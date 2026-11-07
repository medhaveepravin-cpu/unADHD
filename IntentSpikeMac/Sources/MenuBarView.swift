import SwiftUI
import AppKit

// The quieter surface: always present in the menu bar, click to see + act.
struct MenuBarView: View {
    @ObservedObject var store: IntentStore

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("CURRENT INTENT")
                .font(.caption2.weight(.bold))
                .foregroundStyle(.secondary)

            Text(store.isActive ? store.intentTitle : "No active intent")
                .font(.headline)
                .lineLimit(3)
                .fixedSize(horizontal: false, vertical: true)

            Divider()

            Button { store.finish() } label: {
                Label("Finish (open Mail)", systemImage: "arrow.up.forward.app")
            }
            .disabled(!store.isActive)

            Button { store.done() } label: {
                Label("Done", systemImage: "checkmark.circle")
            }
            .disabled(!store.isActive)

            Divider()

            Button("Quit Intent Spike") { NSApplication.shared.terminate(nil) }
        }
        .padding(12)
        .frame(width: 260)
    }
}
