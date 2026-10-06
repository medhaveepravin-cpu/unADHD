import SwiftUI
import AppKit
import UniformTypeIdentifiers

struct ContentView: View {
    @ObservedObject var store = IntentStore.shared
    @State private var launchAtLogin = LoginItem.isEnabled
    @State private var tab: Tab = .focus
    @State private var showTargetOptions = false   // Add screen: destination picker

    // Four single-purpose screens instead of one crowded wall. Default to Focus:
    // the calmest screen, showing one task at a time (easier on an ADHD brain).
    enum Tab: String, CaseIterable, Identifiable {
        case focus, queue, add, settings
        var id: String { rawValue }
        var title: String {
            switch self {
            case .focus: return "Focus"
            case .queue: return "Queue"
            case .add: return "Add"
            case .settings: return "Settings"
            }
        }
        var icon: String {
            switch self {
            case .focus: return "scope"
            case .queue: return "checklist"
            case .add: return "plus"
            case .settings: return "gearshape"
            }
        }
    }

    var body: some View {
        ZStack {
            LinearGradient(colors: [Theme.appBgTop, Theme.appBgBottom],
                           startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                content
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                    .transition(.opacity)
                    .id(tab)              // cross-fade when the tab changes
                tabBar
            }

            if store.showOnboarding {
                OnboardingView(store: store)
                    .transition(.opacity)
                    .zIndex(1)
            }
        }
        .frame(width: 460, height: 660)
        .animation(Theme.Motion.gentle, value: store.showOnboarding)
        .animation(Theme.Motion.spring, value: tab)
    }

    // MARK: - Screens

    @ViewBuilder private var content: some View {
        switch tab {
        case .focus:    focusScreen
        case .queue:    queueScreen
        case .add:      addScreen
        case .settings: settingsScreen
        }
    }

    // One task, lots of air. This is the home screen.
    private var focusScreen: some View {
        VStack(spacing: 0) {
            screenHeader("Focus", subtitle: "One thing at a time")

            // Even vertical rhythm: flexible gaps top, between the mascot group and
            // the intent, and before the buttons — so nothing clusters or floats.
            Spacer(minLength: Theme.Space.lg)

            HiMascotView(width: 216)

            Spacer().frame(height: Theme.Space.lg)   // mascot ↔ phrase (kept together)

            if !focusMotivator.isEmpty {
                Text(focusMotivator)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(Theme.accent)
                    .multilineTextAlignment(.center)
            }

            Spacer(minLength: Theme.Space.xxl)

            VStack(spacing: Theme.Space.md) {
                HStack(spacing: 6) {
                    Text("CURRENT INTENT")
                        .font(Theme.Typo.eyebrow).tracking(1.4)
                        .foregroundStyle(Theme.subtle)
                    if store.remainingCount > 1 {
                        Text("· \(store.remainingCount) left")
                            .font(Theme.Typo.eyebrow)
                            .foregroundStyle(Theme.accent)
                    }
                }

                Text(store.current?.title ?? "All clear — Una's resting ✨")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(store.current == nil ? Theme.subtle : Theme.ink)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, Theme.Space.lg)

                if let target = store.current?.target {
                    Label("Opens \(target) when you finish", systemImage: "arrow.up.forward")
                        .font(Theme.Typo.callout)
                        .foregroundStyle(Theme.subtle)
                }
            }

            Spacer(minLength: Theme.Space.xxl)

            if store.current != nil {
                VStack(spacing: Theme.Space.md) {
                    Button { store.finishCurrent() } label: {
                        Label("Finish & open", systemImage: "arrow.up.forward.app.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(CapsuleButton(filled: true))

                    Button { store.completeCurrent() } label: {
                        Label("Mark done", systemImage: "checkmark")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(CapsuleButton(filled: false))
                }
            } else {
                Button { tab = .add } label: {
                    Label("Add your first intent", systemImage: "plus")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(CapsuleButton(filled: true))
            }
        }
        .padding(Theme.Space.xxl)
    }

    // The full list — on its own screen so it never competes with the add form.
    private var queueScreen: some View {
        VStack(alignment: .leading, spacing: Theme.Space.lg) {
            HStack(alignment: .firstTextBaseline) {
                screenHeader("My queue",
                             subtitle: store.intents.isEmpty ? "Nothing waiting"
                                                             : "\(store.remainingCount) to go")
                Spacer()
                if store.intents.contains(where: { $0.done }) {
                    Button("Clear done") { store.clearCompleted() }
                        .buttonStyle(.plain).font(Theme.Typo.callout).foregroundStyle(Theme.accent)
                }
                if !store.intents.isEmpty {
                    Button("Clear all") { store.clearAll() }
                        .buttonStyle(.plain).font(Theme.Typo.callout).foregroundStyle(Theme.subtle)
                }
            }

            if store.intents.isEmpty {
                emptyState(icon: "tray",
                           line: "Nothing for Una to hold yet.",
                           cta: "Add an intent") { tab = .add }
            } else {
                List {
                    ForEach(store.intents) { intent in
                        row(intent)
                            .listRowSeparator(.hidden)
                            .listRowBackground(Color.clear)
                            .listRowInsets(EdgeInsets(top: 4, leading: 0, bottom: 4, trailing: 0))
                    }
                    .onMove { store.intents.move(fromOffsets: $0, toOffset: $1) }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(Theme.Space.xxl)
    }

    // The capture + routing form — spread down the full screen so it breathes
    // instead of pooling empty space at the bottom.
    private var addScreen: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top, spacing: Theme.Space.md) {
                screenHeader("Add an intent", subtitle: "Dump it. Una routes it.",
                             caption: "Jot the task, pick where you'll land when it's done, and Una holds the rest.")
                MascotView(size: 168)
                    .offset(y: -16)
            }

            Spacer().frame(height: Theme.Space.xl)

            VStack(alignment: .leading, spacing: Theme.Space.md) {
                label("WHAT NEEDS DOING")
                HStack(spacing: Theme.Space.sm) {
                    TextField("e.g. Reply to Priya's email", text: $store.draftTitle)
                        .textFieldStyle(.plain)
                        .font(Theme.Typo.headline)
                        .foregroundStyle(Theme.ink)
                        .padding(Theme.Space.lg)
                        .innerBox()
                        .onSubmit { addAndGoFocus() }
                    DictationMic(text: $store.draftTitle, size: 48)
                }
            }

            Spacer().frame(height: Theme.Space.xl)

            VStack(alignment: .leading, spacing: Theme.Space.md) {
                label("WHEN I FINISH, TAKE ME TO")

                // Collapsed by default: one calm summary row. Tap to reveal the
                // full list of targets — keeps the common case to a single choice.
                Button {
                    withAnimation(Theme.Motion.spring) { showTargetOptions.toggle() }
                } label: {
                    HStack(spacing: Theme.Space.md) {
                        Image(systemName: effectiveTargetIcon)
                            .foregroundStyle(Theme.accent)
                        Text(effectiveTargetLabel)
                            .font(Theme.Typo.callout).foregroundStyle(Theme.ink)
                            .lineLimit(1)
                        Spacer()
                        Text(showTargetOptions ? "Done" : "Change")
                            .font(Theme.Typo.caption).foregroundStyle(Theme.accent)
                        Image(systemName: "chevron.down")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(Theme.subtle)
                            .rotationEffect(.degrees(showTargetOptions ? 180 : 0))
                    }
                    .padding(Theme.Space.lg)
                    .innerBox()
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)

                // Nudge toward the hidden options — disappears once they're open.
                if !showTargetOptions {
                    HStack(spacing: 6) {
                        Image(systemName: "hand.tap.fill")
                        Text("Tap **Change** to route to any app or URL — a whole menu opens up.")
                    }
                    .font(Theme.Typo.caption)
                    .foregroundStyle(Theme.accent)
                    .transition(.opacity)
                }

                if showTargetOptions {
                    VStack(alignment: .leading, spacing: Theme.Space.md) {
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: Theme.Space.sm), count: 3),
                                  spacing: Theme.Space.sm) {
                            ForEach(store.presets) { chip($0) }
                        }
                        HStack(spacing: Theme.Space.sm) {
                            Button { browseForApp() } label: {
                                Label("Browse app…", systemImage: "folder").frame(maxWidth: .infinity)
                            }
                            .buttonStyle(CapsuleButton(filled: false))
                            HStack(spacing: 5) {
                                Image(systemName: "pencil").foregroundStyle(Theme.subtle)
                                TextField("App or URL", text: $store.draftTarget)
                                    .textFieldStyle(.plain)
                                    .foregroundStyle(Theme.ink)
                                    .onChange(of: store.draftTarget) { _ in store.autoCapture = false }
                            }
                            .padding(.vertical, Theme.Space.sm).padding(.horizontal, Theme.Space.md)
                            .innerBox(radius: Theme.Radius.sm)
                        }
                        Toggle(isOn: $store.autoCapture) {
                            Text("Auto-capture the app I came from")
                                .font(Theme.Typo.caption).foregroundStyle(Theme.ink)
                        }
                        .tint(Theme.accent)
                        Text("Right-click a chip to remove it.")
                            .font(Theme.Typo.caption).foregroundStyle(Theme.subtle)
                    }
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }

            Spacer(minLength: Theme.Space.lg)

            Button { addAndGoFocus() } label: {
                Label("Add to queue", systemImage: "plus")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(CapsuleButton(filled: true))
            .disabled(store.draftTitle.trimmingCharacters(in: .whitespaces).isEmpty)
        }
        .frame(maxHeight: .infinity, alignment: .top)
        .padding(Theme.Space.xxl)
    }

    private var settingsScreen: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Space.xl) {
                screenHeader("Settings", subtitle: "Make Una yours")

                settingsGroup("FOCUS AIDS") {
                    Toggle("Show floating card", isOn: $store.showFloatingCard)
                    Divider().overlay(Theme.surfaceStroke)
                    Toggle("Nudge me when I drift off task", isOn: $store.nudgesEnabled)
                    Divider().overlay(Theme.surfaceStroke)
                    Toggle("…also with a notification", isOn: $store.nudgeNotify)
                        .onChange(of: store.nudgeNotify) { on in if on { store.requestNotificationAuth() } }
                        .disabled(!store.nudgesEnabled)
                }

                settingsGroup("SYSTEM") {
                    Toggle("Launch at login", isOn: $launchAtLogin)
                        .onChange(of: launchAtLogin) { on in LoginItem.set(on) }
                }

                Button { store.replayOnboarding() } label: {
                    HStack(spacing: Theme.Space.md) {
                        MascotView(size: 40)
                        VStack(alignment: .leading, spacing: 1) {
                            Text("How unADHD works")
                                .font(Theme.Typo.callout).foregroundStyle(Theme.ink)
                            Text("Replay the quick tutorial")
                                .font(Theme.Typo.caption).foregroundStyle(Theme.subtle)
                        }
                        Spacer()
                        Image(systemName: "chevron.right").foregroundStyle(Theme.subtle)
                    }
                    .padding(Theme.Space.lg)
                    .frame(maxWidth: .infinity)
                    .themeCard(radius: Theme.Radius.lg,
                               fill: Theme.cardBottom, stroke: Theme.cardStroke)
                }
                .buttonStyle(.plain)
            }
            .padding(Theme.Space.xxl)
        }
        .tint(Theme.accent)
    }

    // MARK: - Bottom tab bar

    private var tabBar: some View {
        HStack(spacing: 0) {
            ForEach(Tab.allCases) { t in
                let selected = (t == tab)
                Button { tab = t } label: {
                    VStack(spacing: 4) {
                        ZStack {
                            if selected {
                                Capsule().fill(Theme.accent.opacity(0.12))
                                    .frame(width: 46, height: 30)
                            }
                            Image(systemName: t.icon)
                                .font(.system(size: 17, weight: selected ? .semibold : .regular))
                        }
                        .frame(height: 30)
                        Text(t.title)
                            .font(.system(size: 10, weight: selected ? .semibold : .medium, design: .rounded))
                    }
                    .foregroundStyle(selected ? Theme.accent : Theme.subtle)
                    .frame(maxWidth: .infinity)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.top, Theme.Space.sm)
        .padding(.bottom, Theme.Space.md)
        .padding(.horizontal, Theme.Space.sm)
        .background(
            Rectangle().fill(Theme.appBgTop.opacity(0.92))
                .overlay(Rectangle().fill(Theme.surfaceStroke).frame(height: 1), alignment: .top)
                .ignoresSafeArea(edges: .bottom)
        )
    }

    // MARK: - Builders

    private func screenHeader(_ title: String, subtitle: String, caption: String? = nil) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 7) {
                Capsule().fill(Theme.accent).frame(width: 18, height: 4)
                Text(subtitle.uppercased())
                    .font(.system(size: 12, weight: .heavy, design: .rounded))
                    .tracking(1.6)
                    .foregroundStyle(Theme.accentMuted)
            }

            Spacer().frame(height: Theme.Space.md)   // breathing room under the eyebrow

            // Eye-catching gradient title — deep ink into lavender accent.
            Text(title)
                .font(.system(size: 32, weight: .heavy, design: .rounded))
                .foregroundStyle(
                    LinearGradient(colors: [Theme.ink, Theme.accent],
                                   startPoint: .topLeading, endPoint: .bottomTrailing))

            if let caption {
                Spacer().frame(height: Theme.Space.sm)   // gap between title and text
                Text(caption)
                    .font(Theme.Typo.callout)
                    .foregroundStyle(Theme.subtle)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder private func settingsGroup<Content: View>(_ heading: String,
                                                           @ViewBuilder _ content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: Theme.Space.sm) {
            label(heading)
            VStack(alignment: .leading, spacing: Theme.Space.md) {
                content()
            }
            .font(Theme.Typo.body)
            .foregroundStyle(Theme.ink)
            .tint(Theme.accent)
            .padding(Theme.Space.lg)
            .frame(maxWidth: .infinity, alignment: .leading)
            .themeCard()
        }
    }

    private func emptyState(icon: String, line: String,
                            cta: String, action: @escaping () -> Void) -> some View {
        VStack(spacing: Theme.Space.lg) {
            Image(systemName: icon)
                .font(.system(size: 34, weight: .light))
                .foregroundStyle(Theme.accentSoft)
            Text(line)
                .font(Theme.Typo.callout).foregroundStyle(Theme.subtle)
            Button(action: action) {
                Label(cta, systemImage: "plus").padding(.horizontal, Theme.Space.md)
            }
            .buttonStyle(CapsuleButton(filled: false))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
    }

    private func label(_ text: String) -> some View {
        Text(text)
            .font(Theme.Typo.eyebrow).tracking(1.4)
            .foregroundStyle(Theme.subtle)
    }

    private func row(_ intent: Intent) -> some View {
        let isCurrent = (intent.id == store.current?.id)
        return HStack(spacing: Theme.Space.md) {
            Button { store.toggleDone(intent) } label: {
                Image(systemName: intent.done ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 20))
                    .foregroundStyle(intent.done ? Theme.accentMuted : Theme.subtle)
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 2) {
                Text(intent.title)
                    .font(.system(size: 14, weight: isCurrent ? .semibold : .regular, design: .rounded))
                    .strikethrough(intent.done, color: Theme.subtle)
                    .foregroundStyle(intent.done ? Theme.subtle : Theme.ink)
                Text("→ \(intent.target)")
                    .font(Theme.Typo.caption).foregroundStyle(Theme.subtle)
            }

            Spacer()

            if isCurrent {
                Text("NOW")
                    .font(Theme.Typo.eyebrow)
                    .foregroundStyle(.white)
                    .padding(.horizontal, Theme.Space.sm).padding(.vertical, 3)
                    .background(Capsule().fill(Theme.accentMuted))
            }

            Button { store.delete(intent) } label: {
                Image(systemName: "xmark").font(.system(size: 11, weight: .bold))
                    .foregroundStyle(Theme.subtle)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, Theme.Space.md).padding(.horizontal, Theme.Space.lg)
        .background(
            RoundedRectangle(cornerRadius: Theme.Radius.lg, style: .continuous)
                .fill(isCurrent ? Theme.cardBottom : Theme.surface)
                .overlay(RoundedRectangle(cornerRadius: Theme.Radius.lg, style: .continuous)
                    .stroke(isCurrent ? Theme.cardStroke : Theme.surfaceStroke, lineWidth: 1))
                .softShadow(isCurrent ? Theme.Shadow(color: Theme.accent.opacity(0.14),
                                                     radius: 10, y: 4)
                                      : Theme.Shadow(color: .clear, radius: 0, y: 0))
        )
        .animation(Theme.Motion.spring, value: isCurrent)
    }

    @ViewBuilder private func chip(_ preset: TargetPreset) -> some View {
        // Only highlight a chip when auto-capture is OFF — otherwise the target
        // actually used is "the app I came from", and a lit chip would lie.
        let selected = !store.autoCapture && store.draftTarget == preset.value
        Button { store.pick(preset) } label: {
            HStack(spacing: 5) {
                Image(systemName: preset.symbol).font(.caption)
                Text(preset.label).font(.system(size: 12, weight: .semibold, design: .rounded))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, Theme.Space.sm)
            .foregroundStyle(selected ? .white : Theme.accent)
            .background(Capsule().fill(selected ? Theme.accentMuted : Theme.accent.opacity(0.07)))
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button(role: .destructive) { store.removePreset(preset) } label: {
                Label("Remove \(preset.label)", systemImage: "trash")
            }
        }
    }

    // The destination shown on the collapsed Add summary row.
    private var effectiveTargetLabel: String {
        if store.autoCapture {
            return store.capturedApp.map { "The app you came from · \($0)" }
                ?? "The app you came from"
        }
        let t = store.draftTarget.trimmingCharacters(in: .whitespaces)
        return t.isEmpty ? "Choose where to land" : t
    }
    private var effectiveTargetIcon: String {
        if store.autoCapture { return "wand.and.stars" }
        if let p = store.presets.first(where: { $0.value == store.draftTarget }) { return p.symbol }
        return "arrow.up.forward.app.fill"
    }

    // A gentle one-liner above the current intent — stable per task, warm in tone.
    private var focusMotivator: String {
        guard let current = store.current else { return "" }
        let lines = ["You've got this 🌱",
                     "Just this one.",
                     "One step at a time.",
                     "Small steps still count.",
                     "Una's right here with you."]
        return lines[abs(current.id.hashValue) % lines.count]
    }

    // Add, then drop the user back on the calm Focus screen.
    private func addAndGoFocus() {
        guard !store.draftTitle.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        store.add()
        tab = .focus
    }

    // Pick any installed app as the Finish target, and pin it as a preset.
    private func browseForApp() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        panel.allowedContentTypes = [.application]
        panel.directoryURL = URL(fileURLWithPath: "/Applications")
        if panel.runModal() == .OK, let url = panel.url {
            let name = url.deletingPathExtension().lastPathComponent
            store.draftTarget = name
            store.autoCapture = false
            store.addPreset(label: name, value: name)
        }
    }
}
