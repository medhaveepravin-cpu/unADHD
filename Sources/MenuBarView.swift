import SwiftUI
import AppKit

struct MenuBarView: View {
    @ObservedObject var store: IntentStore

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                MascotView(size: 44)
                Text("unADHD")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(Theme.ink)
                Spacer()
                if store.remainingCount > 0 {
                    Text("\(store.remainingCount) left")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Theme.accent)
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("CURRENT INTENT")
                    .font(.caption2.weight(.bold)).tracking(0.8)
                    .foregroundStyle(Theme.subtle)
                Text(store.current?.title ?? "All clear ✨")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(store.current == nil ? Theme.subtle : Theme.ink)
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)
                if let t = store.current?.target {
                    Text("Finish → \(t)")
                        .font(.caption).foregroundStyle(Theme.subtle)
                }
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(LinearGradient(colors: [Theme.cardTop, Theme.cardBottom],
                                         startPoint: .top, endPoint: .bottom))
                    .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Theme.cardStroke, lineWidth: 1))
            )

            HStack(spacing: 8) {
                Button { store.finishCurrent() } label: {
                    Label("Finish", systemImage: "arrow.up.forward.app.fill").frame(maxWidth: .infinity)
                }
                .buttonStyle(CapsuleButton(filled: true))
                .disabled(store.current == nil)

                Button { store.completeCurrent() } label: {
                    Label("Done", systemImage: "checkmark").frame(maxWidth: .infinity)
                }
                .buttonStyle(CapsuleButton(filled: false))
                .disabled(store.current == nil)
            }

            Divider()

            Button("Quit unADHD") { NSApplication.shared.terminate(nil) }
                .buttonStyle(.plain)
                .font(.subheadline)
                .foregroundStyle(Theme.subtle)
        }
        .padding(14)
        .frame(width: 288)
        .background(Theme.appBgTop)
    }
}
