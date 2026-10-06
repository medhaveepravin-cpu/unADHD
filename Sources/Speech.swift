import Foundation
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
