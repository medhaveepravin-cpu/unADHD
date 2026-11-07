import ActivityKit
import Foundation

// Starts / updates / ends the Live Activity entirely on-device.
// No push, no server. This is the whole point of the spike:
// can ActivityKit keep one intent glanceable while you're in other apps?
@MainActor
final class LiveActivityController: ObservableObject {
    @Published var isRunning = false
    @Published var lastError: String?

    var activitiesEnabled: Bool {
        ActivityAuthorizationInfo().areActivitiesEnabled
    }

    func start(title: String) {
        guard activitiesEnabled else {
            lastError = "Live Activities are disabled. Settings ▸ IntentSpike ▸ Allow Live Activities."
            return
        }
        // One intent at a time: clear any existing before starting a new one.
        endAllSync()

        let attributes = IntentActivityAttributes(sessionName: "Spike")
        let state = IntentActivityAttributes.ContentState(intentTitle: title, startedAt: Date())
        do {
            _ = try Activity.request(
                attributes: attributes,
                content: .init(state: state, staleDate: nil),
                pushType: nil
            )
            isRunning = true
            lastError = nil
        } catch {
            lastError = "Failed to start: \(error.localizedDescription)"
        }
    }

    func update(title: String) {
        Task {
            let state = IntentActivityAttributes.ContentState(intentTitle: title, startedAt: Date())
            for activity in Activity<IntentActivityAttributes>.activities {
                await activity.update(.init(state: state, staleDate: nil))
            }
        }
    }

    func end() {
        Task {
            for activity in Activity<IntentActivityAttributes>.activities {
                await activity.end(nil, dismissalPolicy: .immediate)
            }
            isRunning = false
        }
    }

    private func endAllSync() {
        for activity in Activity<IntentActivityAttributes>.activities {
            Task { await activity.end(nil, dismissalPolicy: .immediate) }
        }
    }
}
