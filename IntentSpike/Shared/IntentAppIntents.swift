import AppIntents
import ActivityKit

// The "Done" button on the Live Activity runs this.
// LiveActivityIntent runs in your app's process without foregrounding it,
// so tapping "Done" clears the intent without yanking you out of Mail.
//
// ADD THIS FILE TO BOTH TARGETS (app + widget) in the File Inspector.
@available(iOS 17.0, *)
struct MarkIntentDoneIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Mark intent done"
    static var description = IntentDescription("Clears the current intent and ends the Live Activity.")

    func perform() async throws -> some IntentResult {
        for activity in Activity<IntentActivityAttributes>.activities {
            await activity.end(nil, dismissalPolicy: .immediate)
        }
        return .result()
    }
}
