import ActivityKit
import WidgetKit
import SwiftUI
import AppIntents

// "Finish" = one tap back into the task. For the spike we deep-link to Mail
// via mailto: so you can literally feel the one-tap re-entry. In the real app
// this becomes a deep link to whatever app the intent is about.
private let finishURL = URL(string: "mailto:")!

struct IntentLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: IntentActivityAttributes.self) { context in
            // Lock Screen / banner presentation
            LockScreenIntentView(context: context)
                .activityBackgroundTint(Color.black.opacity(0.55))
                .activitySystemActionForegroundColor(.white)

        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Image(systemName: "target")
                        .font(.title2)
                        .foregroundStyle(.cyan)
                }
                DynamicIslandExpandedRegion(.center) {
                    Text(context.state.intentTitle)
                        .font(.headline)
                        .lineLimit(2)
                        .minimumScaleFactor(0.7)
                        .multilineTextAlignment(.center)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    HStack(spacing: 12) {
                        Link(destination: finishURL) {
                            Label("Finish", systemImage: "arrow.up.forward.app")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.cyan)

                        if #available(iOS 17.0, *) {
                            Button(intent: MarkIntentDoneIntent()) {
                                Label("Done", systemImage: "checkmark.circle")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                }
            } compactLeading: {
                Image(systemName: "target").foregroundStyle(.cyan)
            } compactTrailing: {
                // Tiny glanceable cue in the compact island while you're in other apps.
                Image(systemName: "arrow.up.forward").foregroundStyle(.cyan)
            } minimal: {
                Image(systemName: "target").foregroundStyle(.cyan)
            }
            // Tapping the compact/minimal island itself = one-tap re-entry.
            .widgetURL(finishURL)
        }
    }
}

struct LockScreenIntentView: View {
    let context: ActivityViewContext<IntentActivityAttributes>

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: "target").foregroundStyle(.cyan)
                Text("CURRENT INTENT")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
                Spacer()
            }

            Text(context.state.intentTitle)
                .font(.headline)
                .foregroundStyle(.white)
                .lineLimit(2)

            HStack(spacing: 10) {
                Link(destination: finishURL) {
                    Label("Finish", systemImage: "arrow.up.forward.app")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.cyan)

                if #available(iOS 17.0, *) {
                    Button(intent: MarkIntentDoneIntent()) {
                        Label("Done", systemImage: "checkmark.circle")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .tint(.white)
                }
            }
        }
        .padding()
    }
}
