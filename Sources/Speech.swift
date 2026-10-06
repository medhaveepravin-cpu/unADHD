import Foundation
import SwiftUI
import Speech
import AVFoundation

// On-device dictation for quick-capture. Streams partial transcriptions while
// the mic button is active and forces on-device recognition when the Mac
// supports it, so spoken intents never leave the machine.
final class SpeechDictator: ObservableObject {
    @Published var isListening = false
    @Published var transcript = ""
    @Published var denied = false      // permission refused or recognizer unavailable

    private let recognizer = SFSpeechRecognizer(locale: Locale.current)
    private let engine = AVAudioEngine()
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var task: SFSpeechRecognitionTask?

    var isAvailable: Bool { recognizer?.isAvailable ?? false }

    func toggle() { isListening ? stop() : authorizeThenStart() }

    // Ask for Speech + Microphone access, then begin — requesting only when the
    // user actually taps the mic, so there's no prompt on first launch.
    private func authorizeThenStart() {
        SFSpeechRecognizer.requestAuthorization { [weak self] status in
            DispatchQueue.main.async {
                guard let self else { return }
                guard status == .authorized else { self.denied = true; return }
                switch AVCaptureDevice.authorizationStatus(for: .audio) {
                case .authorized:
                    self.start()
                case .notDetermined:
                    AVCaptureDevice.requestAccess(for: .audio) { ok in
                        DispatchQueue.main.async { if ok { self.start() } else { self.denied = true } }
                    }
                default:
                    self.denied = true
                }
            }
        }
    }

    private func start() {
        guard let recognizer, recognizer.isAvailable else { denied = true; return }
        task?.cancel(); task = nil

        let req = SFSpeechAudioBufferRecognitionRequest()
        req.shouldReportPartialResults = true
        if recognizer.supportsOnDeviceRecognition { req.requiresOnDeviceRecognition = true }
        request = req

        let input = engine.inputNode
        let format = input.outputFormat(forBus: 0)
        input.removeTap(onBus: 0)
        input.installTap(onBus: 0, bufferSize: 1024, format: format) { buffer, _ in
            req.append(buffer)     // capture the request directly — runs on the audio thread
        }

        engine.prepare()
        do {
            try engine.start()
        } catch {
            input.removeTap(onBus: 0)
            denied = true
            return
        }

        transcript = ""
        denied = false
        isListening = true

        task = recognizer.recognitionTask(with: req) { [weak self] result, error in
            DispatchQueue.main.async {
                guard let self else { return }
                if let result { self.transcript = result.bestTranscription.formattedString }
                if error != nil || (result?.isFinal ?? false) { self.stop() }
            }
        }
    }

    func stop() {
        guard engine.isRunning || isListening else { return }
        engine.inputNode.removeTap(onBus: 0)
        engine.stop()
        request?.endAudio()
        task?.cancel()
        request = nil
        task = nil
        isListening = false
    }
}

// Reusable round mic button that dictates on-device speech into a text binding.
// Pulses red while listening; turns orange if access is refused.
struct DictationMic: View {
    @Binding var text: String
    var size: CGFloat = 46

    @StateObject private var dictator = SpeechDictator()
    @State private var base = ""      // text already present before dictation began
    @State private var pulse = false

    var body: some View {
        Button {
            if dictator.isListening { dictator.stop() }
            else { base = text; dictator.toggle() }
        } label: {
            ZStack {
                Circle()
                    .fill(fill)
                    .frame(width: size, height: size)
                    .scaleEffect(pulse ? 1.12 : 1.0)
                Image(systemName: symbol)
                    .font(.system(size: size * 0.37, weight: .semibold))
                    .foregroundStyle(tint)
            }
        }
        .buttonStyle(.plain)
        .help(helpText)
        .onChange(of: dictator.transcript) { t in
            let b = base.trimmingCharacters(in: .whitespacesAndNewlines)
            text = b.isEmpty ? t : (t.isEmpty ? b : "\(b) \(t)")
        }
        .onChange(of: dictator.isListening) { on in
            if on {
                withAnimation(.easeInOut(duration: 0.7).repeatForever(autoreverses: true)) { pulse = true }
            } else {
                withAnimation(.easeOut(duration: 0.2)) { pulse = false }
            }
        }
        .onDisappear { dictator.stop() }
    }

    private var fill: Color {
        if dictator.isListening { return .red.opacity(0.14) }
        if dictator.denied { return .orange.opacity(0.14) }
        return Theme.accent.opacity(0.10)
    }
    private var symbol: String {
        if dictator.isListening { return "stop.fill" }
        if dictator.denied { return "mic.slash.fill" }
        return "mic.fill"
    }
    private var tint: Color {
        if dictator.isListening { return .red }
        if dictator.denied { return .orange }
        return Theme.accent
    }
    private var helpText: String {
        if dictator.isListening { return "Stop dictation" }
        if dictator.denied { return "Allow Microphone & Speech Recognition in System Settings ▸ Privacy" }
        return "Dictate your intent (on-device)"
    }
}
