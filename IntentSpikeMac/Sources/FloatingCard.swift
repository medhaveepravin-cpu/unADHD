import AppKit
import SwiftUI

// The thing iOS forbids and macOS allows: a small card pinned on top of
// every other app, visible across spaces and over fullscreen apps.
// This is the most direct test of "holds my intent visibly while I wander."
final class FloatingCardController {
    private var panel: NSPanel?
    private let store: IntentStore

    init(store: IntentStore) { self.store = store }

    func show() {
        if panel == nil {
            let hosting = NSHostingView(rootView: FloatingCardView(store: store))
            let p = NSPanel(
                contentRect: NSRect(x: 0, y: 0, width: 300, height: 130),
                styleMask: [.titled, .closable, .fullSizeContentView, .nonactivatingPanel],
                backing: .buffered,
                defer: false
            )
            p.titleVisibility = .hidden
            p.titlebarAppearsTransparent = true
            p.isFloatingPanel = true
            // .screenSaver sits above other apps' full-screen windows;
            // .fullScreenAuxiliary + .canJoinAllSpaces let the panel ride into
            // any space, including another app's full-screen space.
            p.level = .screenSaver
            p.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
            p.hidesOnDeactivate = false
            p.isMovableByWindowBackground = true
            p.standardWindowButton(.miniaturizeButton)?.isHidden = true
            p.standardWindowButton(.zoomButton)?.isHidden = true
            p.contentView = hosting
            positionTopRight(p)
            panel = p
        }
        // orderFrontRegardless so it appears without stealing focus from Mail.
        panel?.orderFrontRegardless()
    }

    func hide() {
        panel?.orderOut(nil)
    }

    private func positionTopRight(_ panel: NSPanel) {
        guard let screen = NSScreen.main else { return }
        let vf = screen.visibleFrame
        let size = panel.frame.size
        panel.setFrameOrigin(NSPoint(x: vf.maxX - size.width - 20,
                                     y: vf.maxY - size.height - 20))
    }
}

struct FloatingCardView: View {
    @ObservedObject var store: IntentStore

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: "target").foregroundStyle(.cyan)
                Text("CURRENT INTENT")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.secondary)
            }
            Text(store.intentTitle)
                .font(.headline)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 8) {
                Button { store.finish() } label: {
                    Label("Finish", systemImage: "arrow.up.forward.app")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.cyan)

                Button { store.done() } label: {
                    Label("Done", systemImage: "checkmark.circle")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }
        }
        .padding(16)
        .frame(width: 300)
    }
}
