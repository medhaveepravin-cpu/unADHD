import SwiftUI

// A first-run tutorial that walks through actually setting up an intent and
// explains the non-obvious controls — the finish target, auto-capture, the
// queue, the global hotkey, and the settings toggles.
// Shown automatically on first launch, and replayable via "How it works".

private struct Slide: Identifiable {
    let id = UUID()
    let symbol: String?       // SF Symbol for the icon badge (nil = show the mascot)
    let title: String
    let intro: String         // one short line of context (may be "")
    let steps: [String]       // terse, action-first lines (markdown bold allowed)
    let numbered: Bool        // numbered steps (a sequence) vs. bulleted (a list)
    let showsHotkey: Bool     // render the ⌃⌥⇧U keycaps under the intro

    init(symbol: String?, title: String, intro: String = "",
         steps: [String] = [], numbered: Bool = false, showsHotkey: Bool = false) {
        self.symbol = symbol; self.title = title; self.intro = intro
        self.steps = steps; self.numbered = numbered; self.showsHotkey = showsHotkey
    }
}

private let slides: [Slide] = [
    Slide(symbol: nil,
          title: "Meet Una, your focus sprout",
          intro: "Hold one intent at a time. Here's the 30-second tour."),

    Slide(symbol: "plus.circle.fill",
          title: "Add an intent",
          steps: [
            "Type the task in **What needs doing?** — or tap 🎙️ to speak it.",
            "Pick where you'll land. Tap **Change** to open the full menu — any app, a URL, or auto-capture.",
            "Press **+** — it drops into your queue.",
          ],
          numbered: true),

    Slide(symbol: "arrow.up.forward.app.fill",
          title: "Where “Finish” sends you",
          intro: "Each intent has a target app, so finishing drops you back into the work:",
          steps: [
            "Tap a **chip** for a common app (Mail, Chrome…).",
            "**Browse app…** picks any installed app.",
            "**Other** takes an app name or a URL.",
            "Right-click a chip to remove it.",
          ]),

    Slide(symbol: "wand.and.stars",
          title: "Auto-capture the app I came from",
          intro: "Leave this on and the target sets itself:",
          steps: [
            "Switch to an app, come back — it becomes your **take me to**.",
            "Turn it off to choose the target by hand.",
          ]),

    Slide(symbol: "macwindow",
          title: "The floating card",
          intro: "Una keeps your current intent on top of every app:",
          steps: [
            "It shows just the one thing to finish next.",
            "**Drag the handle at the top** to move the card anywhere it's in your way.",
            "**Finish** jumps to its app; **Done** checks it off.",
          ]),

    Slide(symbol: "checklist",
          title: "Your queue",
          steps: [
            "The top item is your focus — the one on the floating card.",
            "Tap **Finish** to jump to its app; check it off when done.",
            "**✕** removes an item; drag to reorder.",
          ]),

    Slide(symbol: "bolt.fill",
          title: "Work from anywhere",
          intro: "One shortcut captures an intent without leaving your app:",
          steps: [
            "It targets the app you're in and returns you there.",
            "Flip **Show floating card**, **nudges**, and **Launch at login** below.",
            "Una always waits in your **menu bar** 🌱",
          ],
          showsHotkey: true),
]

struct OnboardingView: View {
    @ObservedObject var store: IntentStore
    @State private var page = 0

    private var slide: Slide { slides[page] }
    private var isLast: Bool { page == slides.count - 1 }

    var body: some View {
        ZStack {
            Color.black.opacity(0.28)
                .ignoresSafeArea()
                .transition(.opacity)

            card
                .frame(width: 380)
                .transition(.scale(scale: 0.96).combined(with: .opacity))
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.85), value: page)
    }

    private var card: some View {
        VStack(spacing: 0) {
            HStack {
                Spacer()
                Button("Skip") { finish() }
                    .buttonStyle(.plain)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Theme.subtle)
            }
            .padding([.top, .trailing], 14)

            icon.padding(.top, 4)

            Text(slide.title)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundStyle(Theme.ink)
                .multilineTextAlignment(.center)
                .padding(.top, 14)
                .padding(.horizontal, 26)
                .id("title\(page)")
                .transition(.opacity)

            if !slide.intro.isEmpty {
                Text(slide.intro)
                    .font(.callout)
                    .foregroundStyle(Theme.subtle)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 8)
                    .padding(.horizontal, 26)
                    .id("intro\(page)")
                    .transition(.opacity)
            }

            if slide.showsHotkey {
                hotkey.padding(.top, 14)
            }

            if !slide.steps.isEmpty {
                steps
                    .padding(.top, 14)
                    .padding(.horizontal, 26)
                    .id("steps\(page)")
                    .transition(.opacity)
            }

            dots.padding(.top, 22)

            controls
                .padding(.horizontal, 24)
                .padding(.top, 16)
                .padding(.bottom, 20)
        }
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(LinearGradient(colors: [Theme.cardTop, Theme.cardBottom],
                                     startPoint: .top, endPoint: .bottom))
                .overlay(RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(Theme.cardStroke, lineWidth: 1))
                .shadow(color: .black.opacity(0.18), radius: 30, y: 12)
        )
    }

    @ViewBuilder private var icon: some View {
        if let symbol = slide.symbol {
            Image(systemName: symbol)
                .font(.system(size: 28, weight: .semibold))
                .foregroundStyle(Theme.accent)
                .frame(width: 70, height: 70)
                .background(Circle().fill(Theme.accent.opacity(0.10)))
                .id("icon\(page)")
                .transition(.scale.combined(with: .opacity))
        } else {
            MascotView(size: 88)
                .id("icon\(page)")
                .transition(.scale.combined(with: .opacity))
        }
    }

    private var steps: some View {
        VStack(alignment: .leading, spacing: 11) {
            ForEach(Array(slide.steps.enumerated()), id: \.offset) { i, step in
                HStack(alignment: .top, spacing: 11) {
                    marker(i)
                    Text(.init(step))        // .init parses markdown (bold labels)
                        .font(.callout)
                        .foregroundStyle(Theme.ink)
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer(minLength: 0)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder private func marker(_ i: Int) -> some View {
        if slide.numbered {
            Text("\(i + 1)")
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .frame(width: 22, height: 22)
                .background(Circle().fill(Theme.accentMuted))
        } else {
            Image(systemName: "checkmark")
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(Theme.accent)
                .frame(width: 22, height: 22)
                .background(Circle().fill(Theme.accent.opacity(0.10)))
        }
    }

    private var hotkey: some View {
        HStack(spacing: 6) {
            keycap("⌃"); keycap("⌥"); keycap("⇧"); keycap("U")
        }
    }

    private func keycap(_ s: String) -> some View {
        Text(s)
            .font(.system(size: 16, weight: .semibold, design: .rounded))
            .foregroundStyle(Theme.ink)
            .frame(minWidth: 34, minHeight: 34)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(.white.opacity(0.9))
                    .overlay(RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(Theme.cardStroke, lineWidth: 1))
            )
    }

    private var dots: some View {
        HStack(spacing: 7) {
            ForEach(slides.indices, id: \.self) { i in
                Circle()
                    .fill(i == page ? Theme.accent : Theme.accent.opacity(0.22))
                    .frame(width: 7, height: 7)
            }
        }
    }

    private var controls: some View {
        HStack(spacing: 10) {
            if page > 0 {
                Button { page -= 1 } label: {
                    Text("Back").frame(maxWidth: .infinity)
                }
                .buttonStyle(CapsuleButton(filled: false))
            }
            Button {
                if isLast { finish() } else { page += 1 }
            } label: {
                Text(isLast ? "Get started" : "Next").frame(maxWidth: .infinity)
            }
            .buttonStyle(CapsuleButton(filled: true))
        }
    }

    private func finish() {
        withAnimation(.easeInOut(duration: 0.2)) { store.finishOnboarding() }
        page = 0   // reset so a replay starts from the top
    }
}
