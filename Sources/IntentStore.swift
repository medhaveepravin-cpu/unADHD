import SwiftUI
import AppKit
import Combine
import UserNotifications

// A quick-pick target. value = app name ("Google Chrome") or URL ("https://…").
struct TargetPreset: Identifiable, Hashable, Codable {
    var id = UUID()
    let label: String
    let value: String
    let symbol: String
}

let defaultPresets: [TargetPreset] = [
    .init(label: "Chrome",   value: "Google Chrome", symbol: "globe"),
    .init(label: "Mail",     value: "Mail",          symbol: "envelope.fill"),
    .init(label: "WhatsApp", value: "WhatsApp",      symbol: "message.fill"),
    .init(label: "Slack",    value: "Slack",         symbol: "number"),
    .init(label: "ChatGPT",  value: "ChatGPT",       symbol: "text.bubble.fill"),
    .init(label: "Claude",   value: "Claude",        symbol: "sparkles"),
]

// One item in the queue.
struct Intent: Identifiable, Codable, Hashable {
    var id = UUID()
    var title: String
    var target: String
    var done: Bool = false
}

final class IntentStore: ObservableObject {
    static let shared = IntentStore()

    // The queue. Floating card always shows the FIRST unchecked one.
    @Published var intents: [Intent] = [] { didSet { save() } }

    // Editable quick-pick targets (M3).
    @Published var presets: [TargetPreset] = defaultPresets { didSet { save() } }

    // Draft for the "add intent" box.
    @Published var draftTitle: String = ""
    @Published var draftTarget: String = "Mail"

    @Published var autoCapture: Bool = true       { didSet { save() } }
    @Published var showFloatingCard: Bool = false { didSet { save() } }

    // Nudges (M5)
    @Published var nudgesEnabled: Bool = true { didSet { save() } }
    @Published var nudgeNotify: Bool = false  { didSet { save() } }
    @Published var pulseTick: Int = 0         // transient — drives the card pulse

    // First-run tutorial. Shown until the user finishes/skips it once; replayable
    // from the "How it works" button. Persisted separately so it survives relaunch.
    @Published var showOnboarding: Bool = false

    // The single current focus.
    var current: Intent? { intents.first(where: { !$0.done }) }
    var remainingCount: Int { intents.filter { !$0.done }.count }

    // What auto-capture would use right now (live preview).
    var capturedApp: String? { FrontmostTracker.shared.lastApp }

    // MARK: - Mutations

    func add() {
        let t = draftTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !t.isEmpty else { return }
        var tgt = draftTarget
        if autoCapture, let last = FrontmostTracker.shared.lastApp, !last.isEmpty {
            tgt = last
        }
        intents.append(Intent(title: t, target: tgt))
        draftTitle = ""
        if !showFloatingCard { showFloatingCard = true }
    }

    func pick(_ preset: TargetPreset) {
        draftTarget = preset.value
        autoCapture = false   // explicit choice wins
    }

    func addPreset(label: String, value: String, symbol: String = "app.dashed") {
        let v = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !v.isEmpty,
              !presets.contains(where: { $0.value.caseInsensitiveCompare(v) == .orderedSame })
        else { return }
        let l = label.trimmingCharacters(in: .whitespacesAndNewlines)
        presets.append(TargetPreset(label: l.isEmpty ? v : l, value: v, symbol: symbol))
    }

    func removePreset(_ p: TargetPreset) {
        presets.removeAll { $0.id == p.id }
    }

    // Used by the ⌃⌥⇧U global quick-capture: target is the app you were in.
    func quickAdd(title: String, target: String) {
        let t = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !t.isEmpty else { return }
        intents.append(Intent(title: t, target: target))
        if !showFloatingCard { showFloatingCard = true }
    }

    func toggleDone(_ intent: Intent) {
        if let i = intents.firstIndex(where: { $0.id == intent.id }) {
            intents[i].done.toggle()
        }
    }

    func completeCurrent() {
        if let i = intents.firstIndex(where: { !$0.done }) {
            intents[i].done = true
        }
    }

    func delete(_ intent: Intent) {
        intents.removeAll { $0.id == intent.id }
    }

    func clearCompleted() {
        intents.removeAll { $0.done }
    }

    func clearAll() {
        intents.removeAll()
    }

    // Nudge: pulse the card now, and optionally post a soft notification (M5).
    func nudge() {
        pulseTick &+= 1
        guard nudgeNotify else { return }
        let content = UNMutableNotificationContent()
        content.title = "Still on it?"
        content.body = current?.title ?? "Your current intent"
        let req = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(req)
    }

    func requestNotificationAuth() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert]) { _, _ in }
    }

    // MARK: - Onboarding

    func replayOnboarding() { showOnboarding = true }

    func finishOnboarding() {
        showOnboarding = false
        d.set(true, forKey: K.onboarded)
    }

    // Snooze: hide the card and bring it back after an interval (M4).
    private var snoozeTimer: Timer?
    func snooze(_ seconds: TimeInterval) {
        showFloatingCard = false
        snoozeTimer?.invalidate()
        snoozeTimer = Timer.scheduledTimer(withTimeInterval: seconds, repeats: false) { [weak self] _ in
            DispatchQueue.main.async { self?.showFloatingCard = true }
        }
    }

    // Finish = one click back into the CURRENT intent's target.
    func finishCurrent() {
        guard let t = current?.target else { return }
        openTarget(t)
    }

    private func openTarget(_ raw: String) {
        let t = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !t.isEmpty else { return }

        // A real web/scheme URL (e.g. https://…, mailto:): open it.
        if let url = URL(string: t), let scheme = url.scheme, scheme != "file" {
            NSWorkspace.shared.open(url); return
        }
        // For an app name, ALWAYS use `open -a`: it launches the app if needed AND
        // brings an already-running app to the front (NSRunningApplication.activate()
        // is unreliable from a background app on recent macOS).
        let p = Process()
        p.executableURL = URL(fileURLWithPath: "/usr/bin/open")
        p.arguments = ["-a", t]
        do { try p.run() } catch { NSLog("unADHD: couldn't open '\(t)': \(error.localizedDescription)") }
    }

    // MARK: - Persistence (M1)

    private let d = UserDefaults.standard
    private var loading = false
    private enum K {
        static let intents = "intents.v2", presets = "presets.v1"
        static let auto = "autoCapture", card = "showFloatingCard"
        static let nudge = "nudgesEnabled", notify = "nudgeNotify"
        static let onboarded = "hasOnboarded.v1"
    }

    init() { load() }

    private func load() {
        loading = true
        if let data = d.data(forKey: K.intents),
           let decoded = try? JSONDecoder().decode([Intent].self, from: data) {
            intents = decoded
        }
        if let data = d.data(forKey: K.presets),
           let decoded = try? JSONDecoder().decode([TargetPreset].self, from: data),
           !decoded.isEmpty {
            presets = decoded
        }
        if d.object(forKey: K.auto) != nil { autoCapture = d.bool(forKey: K.auto) }
        if d.object(forKey: K.card) != nil { showFloatingCard = d.bool(forKey: K.card) }
        if d.object(forKey: K.nudge)  != nil { nudgesEnabled = d.bool(forKey: K.nudge) }
        if d.object(forKey: K.notify) != nil { nudgeNotify = d.bool(forKey: K.notify) }
        // Show the tutorial the first time the app ever runs.
        showOnboarding = (d.object(forKey: K.onboarded) == nil)
        loading = false
    }

    private func save() {
        guard !loading else { return }
        if let data = try? JSONEncoder().encode(intents) { d.set(data, forKey: K.intents) }
        if let data = try? JSONEncoder().encode(presets) { d.set(data, forKey: K.presets) }
        d.set(autoCapture, forKey: K.auto)
        d.set(showFloatingCard, forKey: K.card)
        d.set(nudgesEnabled, forKey: K.nudge)
        d.set(nudgeNotify, forKey: K.notify)
    }
}
