import WidgetKit
import SwiftUI

// @main for the WIDGET EXTENSION target only.
// If Xcode's template generated its own @main bundle + sample widgets,
// delete those generated files so there is exactly one @main here.
@main
struct IntentWidgetBundle: WidgetBundle {
    var body: some Widget {
        IntentLiveActivity()
    }
}
