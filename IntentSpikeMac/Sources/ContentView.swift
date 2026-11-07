import SwiftUI

// Control panel: set the one intent, start it, toggle the floating card.
struct ContentView: View {
    @ObservedObject var store = IntentStore.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Intent Spike")
                .font(.title2.weight(.bold))

            VStack(alignment: .leading, spacing: 6) {
                Text("Current intent").font(.caption).foregroundStyle(.secondary)
                TextField("What's the one thing?", text: $store.intentTitle, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                    .lineLimit(1...3)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("Finish takes me to").font(.caption).foregroundStyle(.secondary)
                TextField("App name or URL — e.g. Google Chrome, https://…", text: $store.target)
                    .textFieldStyle(.roundedBorder)
                Text("App name (Google Chrome, Mail, Slack) or a URL (https://…, mailto:).")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            HStack {
                Button {
                    store.start()
                } label: {
                    Label("Start", systemImage: "target").frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)

                Button(role: .destructive) {
                    store.done()
                } label: {
                    Label("End", systemImage: "xmark.circle").frame(maxWidth: .infinity)
                }
                .disabled(!store.isActive)
            }

            Toggle("Show floating always-on-top card", isOn: $store.showFloatingCard)

            GroupBox("Compare the two surfaces") {
                Text("""
                • Menu bar item (top-right of the screen) — click the target icon to see the intent and act.
                • Floating card — pinned on top of every app, follows you across spaces.

                Start an intent, then go live in Mail / Slack / a browser for 20–30 min. Which one actually catches your eye when you drift? Does Finish pull you back in one click? Does Done clear both?
                """)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(20)
        .frame(width: 440)
    }
}
