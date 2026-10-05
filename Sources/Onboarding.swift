import SwiftUI

// A first-run tutorial that explains the non-obvious parts of unADHD —
// the queue, the floating card, the global capture hotkey, and nudges.
// Shown automatically on first launch, and replayable via "How it works".

private struct Slide: Identifiable {
    let id = UUID()
    let symbol: String?      // SF Symbol for the icon badge (nil = show the mascot)
    let title: String
    let body: String
    let showsHotkey: Bool    // render the ⌃⌥⇧U keycaps under the body
}

private let slides: [Slide] = [
    Slide(symbol: nil,
          title: "Meet Una, your focus sprout",
          body: "unADHD holds one intent at a time, so you can empty your head onto the list and still finish what actually matters.",
          showsHotkey: false),
    Slide(symbol: "tray.full.fill",
          title: "Dump everything into the queue",
          body: "Type anything into “Add an intent.” It all lands in your queue — but Una surfaces only the first one, so you're never staring at a wall of tasks.",
          showsHotkey: false),
    Slide(symbol: "macwindow.on.rectangle",
          title: "One intent, always in view",
          body: "A small floating card hovers above every app showing your current intent. Toggle it anytime with “Show floating card.”",
          showsHotkey: false),
    Slide(symbol: "arrow.up.forward.app.fill",
          title: "Finish takes you back",
          body: "Give each intent a target app — Mail, Chrome, anything. Hit Finish and unADHD jumps you straight back to where the work happens.",
          showsHotkey: false),
    Slide(symbol: "bolt.fill",
          title: "Capture from anywhere",
          body: "Press this shortcut in any app to jot a new intent without losing your place. It even remembers the app you were in and aims you back there.",
          showsHotkey: true),
    Slide(symbol: "bell.badge.fill",
          title: "A nudge when you drift",
          body: "Wander off task and Una gives a gentle nudge to pull you back. Turn nudges and notifications on below. Una always lives in your menu bar 🌱",
          showsHotkey: false),
]

struct OnboardingView: View {
    @ObservedObject var store: IntentStore
    @State private var page = 0

    private var slide: Slide { slides[page] }
    private var isLast: Bool { page == slides.count - 1 }

    var body: some View {
        ZStack {
            // Dim + blur the app behind the tutorial.
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
            // Skip, top-right.
            HStack {
                Spacer()
                Button("Skip") { finish() }
                    .buttonStyle(.plain)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Theme.subtle)
            }
            .padding([.top, .trailing], 14)

            icon
                .padding(.top, 4)

            Text(slide.title)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundStyle(Theme.ink)
                .multilineTextAlignment(.center)
                .padding(.top, 16)
                .padding(.horizontal, 28)
                .id("title\(page)")
                .transition(.opacity)

            Text(slide.body)
                .font(.callout)
                .foregroundStyle(Theme.subtle)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 8)
                .padding(.horizontal, 28)
                .id("body\(page)")
                .transition(.opacity)

            if slide.showsHotkey {
                hotkey.padding(.top, 16)
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
                .font(.system(size: 30, weight: .semibold))
                .foregroundStyle(Theme.accent)
                .frame(width: 76, height: 76)
                .background(Circle().fill(Theme.accent.opacity(0.10)))
                .id("icon\(page)")
                .transition(.scale.combined(with: .opacity))
        } else {
            MascotView(size: 92)
                .id("icon\(page)")
                .transition(.scale.combined(with: .opacity))
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
