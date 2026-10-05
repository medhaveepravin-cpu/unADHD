import AppKit

// Auto-capture: remembers whichever app you were in just before you opened unADHD,
// so Finish can route you back without you ever typing it.
final class FrontmostTracker {
    static let shared = FrontmostTracker()
    private(set) var lastApp: String?

    func start() {
        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(activated(_:)),
            name: NSWorkspace.didActivateApplicationNotification,
            object: nil
        )
    }

    @objc private func activated(_ note: Notification) {
        guard let app = note.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication
        else { return }
        // Ignore ourselves — "last app" should be the one you came FROM.
        if app.bundleIdentifier == Bundle.main.bundleIdentifier { return }
        if let name = app.localizedName, !name.isEmpty {
            lastApp = name
        }
    }
}
