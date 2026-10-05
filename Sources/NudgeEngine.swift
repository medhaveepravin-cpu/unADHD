import AppKit

// M5: when you've been in a different app than your current intent's target
// for a while, give the card a gentle pulse (and optionally a soft notification).
final class NudgeEngine {
    private let store: IntentStore
    private var timer: Timer?
    private var driftStart: Date?
    private var lastNudge: Date?

    // Tunable. Kept short-ish so it's easy to feel while testing.
    private let driftThreshold: TimeInterval = 2 * 60
    private let cooldown: TimeInterval = 2 * 60

    init(store: IntentStore) { self.store = store }

    func start() {
        timer = Timer.scheduledTimer(withTimeInterval: 15, repeats: true) { [weak self] _ in
            self?.tick()
        }
    }

    private func tick() {
        guard store.nudgesEnabled, store.showFloatingCard, let current = store.current else {
            driftStart = nil; return
        }
        // Can't tell "in target" for URL targets — skip drift detection for those.
        if let url = URL(string: current.target), let s = url.scheme, s != "file" {
            driftStart = nil; return
        }

        let front = NSWorkspace.shared.frontmostApplication
        let frontName = front?.localizedName ?? ""
        let isSelf = front?.bundleIdentifier == Bundle.main.bundleIdentifier
        let inTarget = frontName.caseInsensitiveCompare(current.target) == .orderedSame

        if inTarget || isSelf {
            driftStart = nil
            return
        }

        let now = Date()
        if driftStart == nil { driftStart = now }
        if now.timeIntervalSince(driftStart!) >= driftThreshold,
           lastNudge == nil || now.timeIntervalSince(lastNudge!) >= cooldown {
            lastNudge = now
            store.nudge()
        }
    }
}
