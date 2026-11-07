import SwiftUI
import AppKit
import Combine

// One intent at a time. Shared by the menu bar item and the floating card
// so both surfaces always show the same thing.
final class IntentStore: ObservableObject {
    static let shared = IntentStore()

    @Published var intentTitle: String = "Send the email to Priya"
    // Where Finish takes you: an app name ("Google Chrome") or a URL ("https://…", "mailto:").
    @Published var target: String = "Mail"
    @Published var isActive: Bool = false
    @Published var showFloatingCard: Bool = false

    func start() {
        isActive = true
        showFloatingCard = true
    }

    // "Finish" = one click back into the task, routed to THIS intent's target
    // (not a hardcoded app). Give it an app name or a URL.
    func finish() {
        let t = target.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !t.isEmpty else { return }

        // Looks like a URL (has a scheme like https:// or mailto:)? Open it.
        if let url = URL(string: t), url.scheme != nil {
            NSWorkspace.shared.open(url)
            return
        }

        // Otherwise treat it as an app name. Prefer activating a running instance.
        if let app = NSWorkspace.shared.runningApplications.first(where: {
            ($0.localizedName ?? "").caseInsensitiveCompare(t) == .orderedSame
        }) {
            app.activate()
            return
        }

        // Not running — try to launch it by name.
        NSWorkspace.shared.launchApplication(t)
    }

    // "Done" = clear the intent and pull both surfaces down.
    func done() {
        isActive = false
        showFloatingCard = false
    }
}
