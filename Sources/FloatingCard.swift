import AppKit
import SwiftUI

final class FloatingCardController {
    private var panel: NSPanel?
    private let store: IntentStore

    init(store: IntentStore) { self.store = store }

    func show() {
        if panel == nil {
            let hosting = NSHostingView(rootView: FloatingCardView(store: store))
            let size = hosting.fittingSize
            let p = NSPanel(
                contentRect: NSRect(origin: .zero, size: size),
                styleMask: [.titled, .fullSizeContentView, .nonactivatingPanel],
                backing: .buffered,
                defer: false
            )
            p.titleVisibility = .hidden
            p.titlebarAppearsTransparent = true
            p.isFloatingPanel = true
            p.level = .screenSaver
            p.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
            p.hidesOnDeactivate = false
            p.isMovableByWindowBackground = true
            p.isOpaque = false
            p.backgroundColor = .clear
            p.hasShadow = false
            p.standardWindowButton(.closeButton)?.isHidden = true
            p.standardWindowButton(.miniaturizeButton)?.isHidden = true
            p.standardWindowButton(.zoomButton)?.isHidden = true
            p.contentView = hosting
            restorePosition(p)
            NotificationCenter.default.addObserver(
                self, selector: #selector(panelMoved(_:)),
                name: NSWindow.didMoveNotification, object: p)
            panel = p
        }
        panel?.orderFrontRegardless()
    }

    func hide() { panel?.orderOut(nil) }

    @objc private func panelMoved(_ note: Notification) {
        guard let p = note.object as? NSPanel else { return }
        let o = p.frame.origin
        UserDefaults.standard.set(["x": o.x, "y": o.y], forKey: "cardOrigin")
    }

    private func restorePosition(_ panel: NSPanel) {
        if let saved = UserDefaults.standard.dictionary(forKey: "cardOrigin"),
           let x = saved["x"] as? CGFloat, let y = saved["y"] as? CGFloat,
           NSScreen.screens.contains(where: { $0.frame.contains(NSPoint(x: x, y: y)) }) {
            panel.setFrameOrigin(NSPoint(x: x, y: y))
        } else {
            positionTopRight(panel)
        }
    }

    private func positionTopRight(_ panel: NSPanel) {
        guard let screen = NSScreen.main else { return }
        let vf = screen.visibleFrame
        let size = panel.frame.size
        panel.setFrameOrigin(NSPoint(x: vf.maxX - size.width - 24,
                                     y: vf.maxY - size.height - 24))
    }
}

struct FloatingCardView: View {
    @ObservedObject var store: IntentStore
    @State private var hovering = false
    @State private var bump = false     // pulse scale
    @State private var nudged = false   // temporary full-opacity bloom on nudge

    var body: some View {
        ZStack(alignment: .topTrailing) {
            cardBody
            // ✕ sits in the very top-right corner, clear of the "N left" count.
            Button { store.showFloatingCard = false } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(Theme.subtle)
                    .padding(5)
                    .background(Circle().fill(.white.opacity(0.9)))
                    .overlay(Circle().stroke(Theme.cardStroke, lineWidth: 1))
            }
            .buttonStyle(.plain)
            .help("Hide the card")
            .padding(.top, 13)
            .padding(.trailing, 13)
        }
        .padding(10)
        // Idle dimming: fades when you're not looking, blooms on hover or nudge.
        .opacity(hovering || nudged ? 1.0 : 0.6)
        .scaleEffect(bump ? 1.06 : 1.0)
        .animation(.easeInOut(duration: 0.25), value: hovering)
        .animation(.easeInOut(duration: 0.25), value: nudged)
        .onHover { hovering = $0 }
        .onChange(of: store.pulseTick) { _ in pulse() }
        .contextMenu {
            Button("Snooze 10 min") { store.snooze(10 * 60) }
            Button("Snooze 30 min") { store.snooze(30 * 60) }
            Button("Snooze 1 hour") { store.snooze(60 * 60) }
            Divider()
            Button("Hide card") { store.showFloatingCard = false }
        }
    }

    // Gentle attention pulse: a couple of springy bumps + a temporary opacity bloom.
    private func pulse() {
        nudged = true
        withAnimation(.spring(response: 0.16, dampingFraction: 0.4)) { bump = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.20) {
            withAnimation(.spring(response: 0.22, dampingFraction: 0.5)) { bump = false }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.40) {
            withAnimation(.spring(response: 0.16, dampingFraction: 0.4)) { bump = true }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.60) {
            withAnimation(.spring(response: 0.22, dampingFraction: 0.5)) { bump = false }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) { nudged = false }
    }

    private var cardBody: some View {
        HStack(alignment: .top, spacing: 14) {
            MascotView(size: 104)
                .padding(.top, 2)

            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 6) {
                    Text("CURRENT INTENT")
                        .font(.caption2.weight(.bold))
                        .tracking(0.8)
                        .foregroundStyle(Theme.subtle)
                    if store.remainingCount > 1 {
                        Text("· \(store.remainingCount) left")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(Theme.accent)
                    }
                    Spacer()
                }
                .padding(.trailing, 22)   // keep clear of the ✕ corner

                // Title area: fixed height so the panel size stays stable as intents change.
                Text(store.current?.title ?? "All clear — nothing queued ✨")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(store.current == nil ? Theme.subtle : Theme.ink)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, minHeight: 42, alignment: .topLeading)

                HStack(spacing: 8) {
                    Button { store.finishCurrent() } label: {
                        Label("Finish", systemImage: "arrow.up.forward.app.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(CapsuleButton(filled: true))
                    .disabled(store.current == nil)

                    Button { store.completeCurrent() } label: {
                        Label("Done", systemImage: "checkmark")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(CapsuleButton(filled: false))
                    .disabled(store.current == nil)
                }
            }
        }
        .padding(16)
        .frame(width: 372)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(LinearGradient(colors: [Theme.cardTop, Theme.cardBottom],
                                     startPoint: .top, endPoint: .bottom))
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(Theme.cardStroke, lineWidth: 1)
                )
                .shadow(color: Theme.accent.opacity(0.22), radius: 18, x: 0, y: 8)
        )
    }
}

// Shared capsule button style.
struct CapsuleButton: ButtonStyle {
    var filled: Bool
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 13, weight: .semibold))
            .padding(.vertical, 8)
            .foregroundStyle(filled ? Color.white : Theme.accent)
            .background(
                Capsule().fill(filled ? Theme.accentMuted : Theme.accent.opacity(0.08))
            )
            .opacity(configuration.isPressed ? 0.75 : 1)
            .contentShape(Capsule())
    }
}
