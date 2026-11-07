import SwiftUI

struct ContentView: View {
    @StateObject private var controller = LiveActivityController()
    @State private var title = "Send the email to Priya"

    var body: some View {
        NavigationStack {
            Form {
                Section("Current intent") {
                    TextField("What's the one thing?", text: $title, axis: .vertical)
                        .lineLimit(1...3)
                }

                Section {
                    Button {
                        controller.start(title: title)
                    } label: {
                        Label("Start — show on Dynamic Island", systemImage: "target")
                    }

                    Button {
                        controller.update(title: title)
                    } label: {
                        Label("Update intent text", systemImage: "pencil")
                    }
                    .disabled(!controller.isRunning)

                    Button(role: .destructive) {
                        controller.end()
                    } label: {
                        Label("End intent", systemImage: "xmark.circle")
                    }
                    .disabled(!controller.isRunning)
                }

                if let error = controller.lastError {
                    Section {
                        Text(error).foregroundStyle(.red).font(.footnote)
                    }
                }

                Section("The kill-or-continue test") {
                    Text("""
                    1. Tap Start.
                    2. Leave this app. Open Mail, Safari, Messages — wander for 20–30 min like a real distracted session.
                    3. Watch the Dynamic Island the whole time and note:
                       • Is the intent glanceable, or does it collapse to a useless dot?
                       • Tap it (or Finish) — does it bring you back in ONE tap?
                       • Does Done clear it without yanking you out of the app you're in?
                       • Does it survive lock/unlock, Low Power Mode, and the ~8h ceiling?
                    """)
                    .font(.footnote)
                }
            }
            .navigationTitle("Intent Spike")
        }
    }
}
