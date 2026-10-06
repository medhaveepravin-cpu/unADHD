import AppKit
import SwiftUI

// The ⌃⌥⇧U popover: a tiny capture field that appears over whatever you're doing,
// pre-targeted to the app you're in, and returns you there when you're done.
final class QuickCaptureController {
    private var panel: NSPanel?
    private let store: IntentStore
    private weak var previousApp: NSRunningApplication?

    init(store: IntentStore) { self.store = store }

    func toggle() {
        if let p = panel, p.isVisible { close(); return }
        present()
    }

    private func present() {
        previousApp = NSWorkspace.shared.frontmostApplication
        let captured = previousApp?.localizedName ?? ""

        let view = QuickCaptureView(capturedApp: captured,
                                    onCommit: { [weak self] title in
                                        self?.store.quickAdd(title: title, target: captured)
                                        self?.close()
                                    },
                                    onCancel: { [weak self] in self?.close() })

        let hosting = NSHostingView(rootView: view)
        let size = NSSize(width: 480, height: 150)
        let p = NSPanel(contentRect: NSRect(origin: .zero, size: size),
                        styleMask: [.titled, .fullSizeContentView],
                        backing: .buffered, defer: false)
        p.titleVisibility = .hidden
        p.titlebarAppearsTransparent = true
        p.isOpaque = false
        p.backgroundColor = .clear
        p.hasShadow = false
        p.level = .screenSaver
        p.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        p.standardWindowButton(.closeButton)?.isHidden = true
        p.standardWindowButton(.miniaturizeButton)?.isHidden = true
        p.standardWindowButton(.zoomButton)?.isHidden = true
        p.contentView = hosting
        center(p)
        panel = p

        NSApp.activate(ignoringOtherApps: true)
        p.makeKeyAndOrderFront(nil)
    }

    func close() {
        panel?.orderOut(nil)
        panel = nil
        // Return the user to whatever they were doing.
        previousApp?.activate()
    }

    private func center(_ panel: NSPanel) {
        guard let screen = NSScreen.main else { return }
        let vf = screen.visibleFrame
        let s = panel.frame.size
        panel.setFrameOrigin(NSPoint(x: vf.midX - s.width / 2,
                                     y: vf.midY - s.height / 2 + 80))
    }
}

struct QuickCaptureView: View {
    let capturedApp: String
    let onCommit: (String) -> Void
    let onCancel: () -> Void

    @State private var text = ""
    @FocusState private var focused: Bool
    @StateObject private var dictator = SpeechDictator()
    @State private var dictationBase = ""   // text typed before dictation started
    @State private var pulse = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                MascotView(size: 36)
                Text("What's the one thing?")
                    .font(.headline).foregroundStyle(Theme.ink)
                Spacer()
                Text("⌃⌥⇧U").font(.caption2).foregroundStyle(Theme.subtle)
            }

            HStack(spacing: 8) {
                TextField("Type it, press Return…", text: $text)
                    .textFieldStyle(.plain)
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(Theme.ink)
                    .focused($focused)
                    .onSubmit { commit() }
                    .padding(12)
                    .frame(maxWidth: .infinity)
                    .background(RoundedRectangle(cornerRadius: 10).fill(.white.opacity(0.9)))

                micButton
            }

            HStack(spacing: 6) {
                if dictator.isListening {
                    Circle().fill(.red).frame(width: 7, height: 7)
                    Text("Listening — tap the mic to stop")
                        .font(.caption).foregroundStyle(Theme.ink)
                } else if dictator.denied {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.caption2).foregroundStyle(.orange)
                    Text("Allow Microphone & Speech Recognition in Privacy settings")
                        .font(.caption).foregroundStyle(Theme.subtle)
                } else if !capturedApp.isEmpty {
                    Label("Finish will take you back to \(capturedApp)", systemImage: "arrow.uturn.backward")
                        .font(.caption).foregroundStyle(Theme.subtle)
                }
                Spacer()
                Button("Cancel") { dictator.stop(); onCancel() }
                    .buttonStyle(.plain).font(.caption).foregroundStyle(Theme.subtle)
                    .keyboardShortcut(.cancelAction)
                Button("Add") { commit() }
                    .buttonStyle(CapsuleButton(filled: true))
                    .keyboardShortcut(.defaultAction)
            }
        }
        .onChange(of: dictator.transcript) { t in
            let base = dictationBase.trimmingCharacters(in: .whitespacesAndNewlines)
            text = base.isEmpty ? t : (t.isEmpty ? base : "\(base) \(t)")
        }
        .onChange(of: dictator.isListening) { on in
            if on {
                withAnimation(.easeInOut(duration: 0.7).repeatForever(autoreverses: true)) { pulse = true }
            } else {
                withAnimation(.easeOut(duration: 0.2)) { pulse = false }
            }
        }
        .onDisappear { dictator.stop() }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(LinearGradient(colors: [Theme.cardTop, Theme.cardBottom],
                                     startPoint: .top, endPoint: .bottom))
                .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(Theme.cardStroke, lineWidth: 1))
                .shadow(color: Theme.accent.opacity(0.28), radius: 24, y: 10)
        )
        .padding(12)
        .onAppear { DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { focused = true } }
    }

    // Tap to dictate on-device; tap again to stop. Pulses while listening.
    private var micButton: some View {
        Button {
            if dictator.isListening {
                dictator.stop()
            } else {
                dictationBase = text
                dictator.toggle()
            }
        } label: {
            ZStack {
                Circle()
                    .fill(dictator.isListening ? Color.red.opacity(0.14) : Theme.accent.opacity(0.10))
                    .frame(width: 46, height: 46)
                    .scaleEffect(pulse ? 1.12 : 1.0)
                Image(systemName: dictator.isListening ? "stop.fill" : "mic.fill")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(dictator.isListening ? .red : Theme.accent)
            }
        }
        .buttonStyle(.plain)
        .help(dictator.isListening ? "Stop dictation" : "Dictate your intent (on-device)")
    }

    // Stop any dictation, then hand the text off.
    private func commit() {
        dictator.stop()
        onCommit(text)
    }
}
