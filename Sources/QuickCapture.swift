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

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                MascotView(size: 36)
                Text("What's the one thing?")
                    .font(.headline).foregroundStyle(Theme.ink)
                Spacer()
                Text("⌃⌥⇧U").font(.caption2).foregroundStyle(Theme.subtle)
            }

            TextField("Type it, press Return…", text: $text)
                .textFieldStyle(.plain)
                .font(.system(size: 17, weight: .medium))
                .foregroundStyle(Theme.ink)
                .focused($focused)
                .onSubmit { onCommit(text) }
                .padding(12)
                .background(RoundedRectangle(cornerRadius: 10).fill(.white.opacity(0.9)))

            HStack {
                if !capturedApp.isEmpty {
                    Label("Finish will take you back to \(capturedApp)", systemImage: "arrow.uturn.backward")
                        .font(.caption).foregroundStyle(Theme.subtle)
                }
                Spacer()
                Button("Cancel", action: onCancel)
                    .buttonStyle(.plain).font(.caption).foregroundStyle(Theme.subtle)
                    .keyboardShortcut(.cancelAction)
                Button("Add") { onCommit(text) }
                    .buttonStyle(CapsuleButton(filled: true))
                    .keyboardShortcut(.defaultAction)
            }
        }
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
}
