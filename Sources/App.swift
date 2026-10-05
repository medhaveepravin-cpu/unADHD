import SwiftUI
import AppKit
import Combine

final class AppDelegate: NSObject, NSApplicationDelegate {
    let store = IntentStore.shared
    lazy var floating = FloatingCardController(store: store)
    lazy var quickCapture = QuickCaptureController(store: store)
    lazy var nudgeEngine = NudgeEngine(store: store)
    private var cancellable: AnyCancellable?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        FrontmostTracker.shared.start()   // begin remembering where you came from

        cancellable = store.$showFloatingCard
            .receive(on: RunLoop.main)
            .sink { [weak self] show in
                if show { self?.floating.show() } else { self?.floating.hide() }
            }

        // ⌃⌥⇧U — capture an intent from anywhere (M2).
        HotKeyManager.shared.onFire = { [weak self] in self?.quickCapture.toggle() }
        HotKeyManager.shared.register()

        nudgeEngine.start()   // M5
    }
}

@main
struct UnADHDApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @ObservedObject var store = IntentStore.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .windowResizability(.contentSize)

        MenuBarExtra {
            MenuBarView(store: store)
        } label: {
            if let icon = Assets.menuBarIcon {
                Image(nsImage: icon)
            } else {
                Image(systemName: "leaf.fill")
            }
        }
        .menuBarExtraStyle(.window)
    }
}
