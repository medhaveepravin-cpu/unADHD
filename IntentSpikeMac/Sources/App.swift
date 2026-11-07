import SwiftUI
import AppKit
import Combine

final class AppDelegate: NSObject, NSApplicationDelegate {
    let store = IntentStore.shared
    lazy var floating = FloatingCardController(store: store)
    private var cancellable: AnyCancellable?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        // Drive the floating panel off the shared store.
        cancellable = store.$showFloatingCard
            .receive(on: RunLoop.main)
            .sink { [weak self] show in
                if show { self?.floating.show() } else { self?.floating.hide() }
            }
    }
}

@main
struct IntentSpikeMacApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @ObservedObject var store = IntentStore.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .windowResizability(.contentSize)

        MenuBarExtra("Intent", systemImage: "target") {
            MenuBarView(store: store)
        }
        .menuBarExtraStyle(.window)
    }
}
