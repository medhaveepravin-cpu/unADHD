import SwiftUI
import AppKit
import UniformTypeIdentifiers

struct ContentView: View {
    @ObservedObject var store = IntentStore.shared
    @State private var launchAtLogin = LoginItem.isEnabled

    var body: some View {
        ZStack {
            LinearGradient(colors: [Theme.appBgTop, Theme.appBgBottom],
                           startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 16) {
                header
                addCard
                queueList
                footerToggles
            }
            .padding(20)
        }
        .frame(width: 480, height: 680)
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: 16) {
            MascotView(size: 92)
            VStack(alignment: .leading, spacing: 3) {
                Text("unADHD")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(Theme.ink)
                Text("Dump it all. Finish one at a time.")
                    .font(.callout)
                    .foregroundStyle(Theme.subtle)
                Text("Una's holding your focus 🌱")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(Theme.accent)
            }
            Spacer()
        }
    }

    // MARK: - Add intent

    private var addCard: some View {
        card {
            VStack(alignment: .leading, spacing: 10) {
                label("ADD AN INTENT")
                HStack(spacing: 8) {
                    TextField("What needs doing?", text: $store.draftTitle)
                        .textFieldStyle(.plain)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(Theme.ink)
                        .padding(10)
                        .background(RoundedRectangle(cornerRadius: 10).fill(.white.opacity(0.8)))
                        .onSubmit { store.add() }
                    Button { store.add() } label: {
                        Image(systemName: "plus").font(.system(size: 14, weight: .bold))
                            .padding(10)
                    }
                    .buttonStyle(CapsuleButton(filled: true))
                    .disabled(store.draftTitle.trimmingCharacters(in: .whitespaces).isEmpty)
                }

                HStack {
                    label("WHEN I FINISH IT, TAKE ME TO")
                    Spacer()
                    Text("right-click a chip to remove")
                        .font(.caption2).foregroundStyle(Theme.subtle)
                }
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 3),
                          spacing: 8) {
                    ForEach(store.presets) { chip($0) }
                }
                HStack(spacing: 8) {
                    Button { browseForApp() } label: {
                        Label("Browse app…", systemImage: "folder").frame(maxWidth: .infinity)
                    }
                    .buttonStyle(CapsuleButton(filled: false))
                    Button {
                        store.addPreset(label: store.draftTarget, value: store.draftTarget)
                    } label: {
                        Label("Pin current", systemImage: "pin").frame(maxWidth: .infinity)
                    }
                    .buttonStyle(CapsuleButton(filled: false))
                    .disabled(store.draftTarget.trimmingCharacters(in: .whitespaces).isEmpty)
                }

                HStack(spacing: 6) {
                    Image(systemName: "pencil").foregroundStyle(Theme.subtle)
                    TextField("Other — app name or URL", text: $store.draftTarget)
                        .textFieldStyle(.plain)
                        .foregroundStyle(Theme.ink)
                        .onChange(of: store.draftTarget) { _ in store.autoCapture = false }
                }
                .padding(8)
                .background(RoundedRectangle(cornerRadius: 10).fill(.white.opacity(0.8)))

                Toggle(isOn: $store.autoCapture) {
                    VStack(alignment: .leading, spacing: 1) {
                        Text("Auto-capture the app I came from")
                            .font(.subheadline.weight(.medium)).foregroundStyle(Theme.ink)
                        Text(store.capturedApp.map { "Right now that's \($0)" }
                             ?? "Switch to another app, then come back")
                            .font(.caption).foregroundStyle(Theme.subtle)
                    }
                }
                .tint(Theme.accent)
            }
        }
    }

    // MARK: - Queue

    private var queueList: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
                label("MY QUEUE")
                Spacer()
                if store.intents.contains(where: { $0.done }) {
                    Button("Clear done") { store.clearCompleted() }
                        .buttonStyle(.plain)
                        .font(.caption).foregroundStyle(Theme.accent)
                }
                if !store.intents.isEmpty {
                    Button("Clear all") { store.clearAll() }
                        .buttonStyle(.plain)
                        .font(.caption).foregroundStyle(Theme.subtle)
                }
            }

            if store.intents.isEmpty {
                Text("Nothing for Una to hold yet. Add your first intent above.")
                    .font(.callout).foregroundStyle(Theme.subtle)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            } else {
                List {
                    ForEach(store.intents) { intent in
                        row(intent)
                            .listRowSeparator(.hidden)
                            .listRowBackground(Color.clear)
                    }
                    .onMove { store.intents.move(fromOffsets: $0, toOffset: $1) }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private func row(_ intent: Intent) -> some View {
        let isCurrent = (intent.id == store.current?.id)
        return HStack(spacing: 10) {
            Button { store.toggleDone(intent) } label: {
                Image(systemName: intent.done ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 18))
                    .foregroundStyle(intent.done ? Theme.accentMuted : Theme.subtle)
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 1) {
                Text(intent.title)
                    .font(.system(size: 14, weight: isCurrent ? .semibold : .regular))
                    .strikethrough(intent.done, color: Theme.subtle)
                    .foregroundStyle(intent.done ? Theme.subtle : Theme.ink)
                Text("→ \(intent.target)")
                    .font(.caption2).foregroundStyle(Theme.subtle)
            }

            Spacer()

            if isCurrent {
                Text("NOW")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 6).padding(.vertical, 2)
                    .background(Capsule().fill(Theme.accentMuted))
            }

            Button { store.delete(intent) } label: {
                Image(systemName: "xmark").font(.system(size: 11, weight: .bold))
                    .foregroundStyle(Theme.subtle)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 6).padding(.horizontal, 10)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(isCurrent ? Theme.cardBottom : Theme.surface)
                .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(isCurrent ? Theme.cardStroke : Theme.surfaceStroke, lineWidth: 1))
        )
    }

    // MARK: - Footer

    private var footerToggles: some View {
        VStack(alignment: .leading, spacing: 8) {
            Toggle("Show floating card", isOn: $store.showFloatingCard)
            Toggle("Launch at login", isOn: $launchAtLogin)
                .onChange(of: launchAtLogin) { on in LoginItem.set(on) }
            Toggle("Nudge me when I drift off task", isOn: $store.nudgesEnabled)
            Toggle("…also with a notification", isOn: $store.nudgeNotify)
                .onChange(of: store.nudgeNotify) { on in if on { store.requestNotificationAuth() } }
                .disabled(!store.nudgesEnabled)
                .padding(.leading, 16)
        }
        .tint(Theme.accent)
        .font(.subheadline)
        .foregroundStyle(Theme.ink)
    }

    // MARK: - Builders

    @ViewBuilder private func card<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
        content()
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Theme.surface)
                    .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Theme.surfaceStroke, lineWidth: 1))
            )
    }

    private func label(_ text: String) -> some View {
        Text(text)
            .font(.caption2.weight(.bold)).tracking(0.8)
            .foregroundStyle(Theme.subtle)
    }

    @ViewBuilder private func chip(_ preset: TargetPreset) -> some View {
        // Only show a chip as selected when auto-capture is OFF — otherwise the
        // target actually used is "the app I came from", and a highlighted chip would lie.
        let selected = !store.autoCapture && store.draftTarget == preset.value
        Button { store.pick(preset) } label: {
            HStack(spacing: 5) {
                Image(systemName: preset.symbol).font(.caption)
                Text(preset.label).font(.caption.weight(.semibold))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
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
