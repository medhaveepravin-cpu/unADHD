<div align="center">

<img src="Resources/mascot.png" width="140" alt="unADHD mascot — a sprout reading a book" />

# unADHD

**A tiny macOS companion that holds *one* intent in a floating card — so you finish it before you wander off.**

### [🌱 Landing page](https://medhaveepravin-cpu.github.io/unADHD/) · [⬇ Download for macOS](https://github.com/medhaveepravin-cpu/unADHD/releases/latest/download/unADHD.zip)

macOS 13+ · Apple Silicon · ad-hoc signed (right-click → Open on first launch)

</div>

---

## Why

You decide to do one thing — send an email, reply to a message — open the app, get pulled into something else, and forget the original task for hours. unADHD keeps your **current intent** visible on top of every other app, with one tap to jump back to it and one tap to mark it done. Dump a whole list; it shows you only the next one.

macOS is a good home for this: unlike iOS, it lets an app keep a small window **floating above everything, even fullscreen apps** — which is exactly what the floating card does.

## Features

- 🎯 **One current focus** — a floating card shows the first unchecked intent and nothing else. Done → the next one slides in.
- 🗂️ **Brain-dump queue** — add as many intents as you like; check them off one at a time.
- 🪟 **Floats above everything** — including other apps' fullscreen spaces.
- ⚡ **One-tap Finish** — jumps you to the app (or URL) that intent is about. Set a target per task, pick from editable presets, browse for any app, or let it **auto-capture the app you came from**.
- ⌨️ **Global capture — ⌃⌥⇧U** — set an intent from *any* app without leaving it; it targets the app you were in and drops you back there.
- 🔔 **Gentle nudges** — if you drift off your target app for a couple of minutes, the card pulses to pull you back (optional notification too).
- 🌙 **Idle dimming & snooze** — fades when you're not looking; right-click to snooze 10/30/60 min.
- 💾 **Remembers everything** — queue, targets, card position — across launches. Optional **launch at login**.
- 🧭 Lives in the **menu bar** as well as a Dock window.

Everything is **on-device**. No accounts, no sync, no analytics, no network.

## Requirements

- macOS 13 (Ventura) or later
- Apple Silicon (the build script produces an `arm64` binary; build from source for Intel)
- **No Xcode needed** — only the Command Line Tools (`xcode-select --install`)

## Build & run

```bash
./build.sh
open unADHD.app
```

`build.sh` compiles the SwiftUI app with `swiftc` from the Command Line Tools and assembles a `.app` bundle — no Xcode, no package manager.

The app is **ad-hoc signed**, so the first launch may need: right-click `unADHD.app` → **Open** → **Open** (or allow it in System Settings ▸ Privacy & Security).

> Tip: set a task's target to `mailto:` to pop a fresh compose window instead of just raising Mail. Any `https://` URL works as a target too.

## Project layout

```
Sources/
  App.swift             App entry, menu bar, wiring
  ContentView.swift     Main window: add box + queue
  FloatingCard.swift    The always-on-top card + its panel
  QuickCapture.swift    ⌃⌥⇧U popover
  HotKeyManager.swift   Global hotkey (Carbon, no Accessibility permission)
  NudgeEngine.swift     Drift detection → card pulse / notification
  IntentStore.swift     State, queue, targets, persistence
  FrontmostTracker.swift Remembers the app you came from
  LoginItem.swift       Launch at login (SMAppService)
  Theme.swift           Colors + mascot loader
Resources/              Mascot, menu-bar glyph, app icon
build.sh                Builds unADHD.app with Command Line Tools
PHASE1_PLAN.md          Design notes / roadmap
```

## Status

Phase 1 is functional: queue, floating card, global capture, auto-capture, editable targets, nudges, persistence, launch at login. Not yet done: Developer ID signing + notarization (for frictionless sharing), and a longer-term efficacy trial. See [PHASE1_PLAN.md](PHASE1_PLAN.md).

## License

Source code: **Apache License 2.0** — see [LICENSE](LICENSE).

**Artwork is not open-licensed.** The sprout mascot and derived icon are © 2026 Medhavee, all rights reserved, included only so the app builds and looks right. If you fork this for your own distribution, please replace the mascot assets with your own. See [NOTICE](NOTICE).
