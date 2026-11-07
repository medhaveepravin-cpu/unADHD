import ActivityKit
import Foundation

// Shared between the app and the widget extension.
// ADD THIS FILE TO BOTH TARGETS (app + widget) in the File Inspector.
struct IntentActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // The one thing you're trying to hold onto.
        var intentTitle: String
        var startedAt: Date
    }

    // Static for the life of the activity.
    var sessionName: String
}
