# unADHD — Phase 1 build plan

_Last updated: 2026-10-05_

## Where we are (Phase 0 result)

The feasibility question is **answered**. The throwaway spike proved, on the real machine:

- A floating card can stay glanceable **above other apps, including fullscreen** (`.screenSaver` level + `.fullScreenAuxiliary`). This worked noticeably better than the menu bar for catching attention.
- **Finish** can route one tap back into the *right* app (activate a running app by name, or open a URL).
- **Auto-capture** — remembering the app you came from — works via `NSWorkspace.didActivateApplicationNotification`.
- The whole thing **builds and runs with Command Line Tools only — no Xcode**, as a signed `.app` from `build.sh`.

**Locked decisions:** macOS-native SwiftUI · one intent at a time · floating card is the primary surface, menu bar secondary · Finish + Done · presets *and* auto-capture · name **unADHD**.

So Phase 1 is no longer "will it work" — it's "make it a thing I actually use every day without babysitting it."

### Progress
- ✅ **App icon** — mascot on a soft lavender squircle (`.icns`, all sizes, generated without Xcode).
- ✅ **Multi-intent queue** — brain-dump many intents; the floating card + menu bar still show only the **current** (first unchecked) one; Done advances to the next. Thesis preserved: one *focus* at a time, with a backlog behind it.
- ✅ **M1 — Durable (done):** queue + auto-capture + card visibility + card position persist in `UserDefaults` and restore on launch; **Launch at login** toggle via `SMAppService`.
  - Caveat: launch-at-login may not stick while the app runs ad-hoc-signed from Desktop; a proper signed build in `/Applications` (M6) resolves it.
- ✅ **M2 — Capture anywhere (done):** global **⌃⌥⇧U** hotkey (Carbon `RegisterEventHotKey`, no Accessibility permission needed) opens a quick-capture popover over any app, targets the app you were in, and returns you there on commit.
  - Note: a global hotkey only works while unADHD is **running**. Closing the window keeps it alive (hotkey still works); **Cmd+Q quits** the process and the hotkey stops until relaunch. Launch-at-login keeps it running after boot.
- ✅ **M3 — Targets (done):** robust app launching via `open -a` (fixes apps that wouldn't open, e.g. WhatsApp/ChatGPT/Claude when not running); editable presets (right-click to remove, "Pin current"); **Browse app…** picker over `/Applications`; presets persist.
- ✅ Floating card now has a **✕ to dismiss** it.
- ✅ **Target-override bug fixed:** auto-capture used to silently override a picked chip (so multiple tasks all got the same target). Chips now show selected only when auto-capture is OFF, so per-task targets stick.
- ✅ **M4 — Companion feel (partial, done):** card **idle-dimming** (fades when not hovered, blooms on hover); **snooze** 10/30/60 min via card right-click; **Clear all** / Clear done in the queue; card position memory (from M1).
  - Deferred by choice: menu-bar-only mode (you chose Dock + window); a separate Settings window (toggles live in the main window for now).
- ✅ **Finish bring-to-front fixed:** now always uses `open -a`, which launches *and* raises an already-running app (Mail/ChatGPT/Claude/Safari no longer fail when already open). Tip: set a target to `mailto:` to open a fresh compose window instead of just raising Mail.
- ✅ **M5 — Nudges (done):** `NudgeEngine` watches the frontmost app; if you're off your current intent's target app for ~2 min, the card gives a springy pulse + opacity bloom. Toggle "Nudge me when I drift"; optional "…also with a notification" (requests permission on enable). Threshold is currently 2 min (tunable).
- ⏭️ **Remaining Phase 1:** M6 (Developer ID signing + notarization, for sharing) when you want it. Also open: tune nudge threshold / make it a setting; the 1-week efficacy self-trial.

---

## The real remaining risk (carry this through Phase 1)

Visibility is solved; **behavioral efficacy is not.** The open question: does a persistent card actually pull you back on task over a week, or does it become wallpaper you stop seeing? Everything attention-related below (nudges, pulse, idle dimming) exists to test and improve that — and the only real proof is a **1-week self-trial** (see Milestone 5). Second known limit: a Mac app only catches drift that happens *on the laptop*; phone drift is out of scope until/unless we do the iOS path later.

---

## Workstreams

### 1. Persistence & state restore
- Save current intent, target, auto-capture pref, card position, and settings across launches **and reboot**.
- Start simple: `UserDefaults` (or a small JSON file in Application Support). SwiftData is overkill for one record.
- On launch, if an intent was active, restore it and re-show the floating card where it was.

### 2. Launch at login
- `SMAppService.mainApp.register()` (ServiceManagement). Toggle in Settings.
- Verify it survives reboot and shows up in System Settings ▸ General ▸ Login Items.

### 3. Global hotkey — capture from anywhere
- System-wide shortcut: **⌃⌥⇧U** (confirmed). Will verify no clash before shipping.
- Opens a tiny quick-capture field **without leaving the app you're in**.
- **This is the best auto-capture moment:** record the frontmost app *at the instant you hit the hotkey* — that's genuinely "the thing I'm supposed to get back to."
- Implementation: `CGEvent` tap / `NSEvent.addGlobalMonitorForEvents`, or a small Carbon `RegisterEventHotKey` shim. Needs Accessibility permission — handle the prompt gracefully.

### 4. Quick-capture flow
- One field, Return to commit. Pre-fill target from the captured app; let a preset chip or typing override.
- Keep it ADHD-friendly: zero required fields beyond the intent text itself.

### 5. Target system (presets, done properly)
- Editable presets: add / remove / reorder; persist them.
- Real app picker: list running apps and/or browse `/Applications` (`NSWorkspace` + `NSOpenPanel`), instead of typing exact names.
- Keep URL targets (`https://`, `mailto:`) and a free-type fallback.
- Preset set: **Chrome · Mail · WhatsApp · Slack · ChatGPT · Claude** (GTM removed, ChatGPT added).

### 6. App presence — Dock icon + window (decided)
- Keep the **Dock icon + main window** as the default (not menu-bar-only). The menu bar item stays as a secondary surface. Menu-bar-only mode deferred / optional later.

### 7. Floating card UX
- Persist drag position; snap to nearest corner; remember per-display.
- **Idle dimming**: fade to low opacity when untouched, bloom back on hover or on a nudge.
- **Snooze** (10/30/60 min) to hide without marking done.
- Decide click-through behavior so it never blocks a click underneath.
- Multi-display + display-disconnect handling.

### 8. Attention mechanics (the efficacy bet)
- Optional gentle **pulse/wiggle** of the card after N minutes in a *different* app than the target.
- Optional single soft notification at a threshold ("still want to finish: <intent>?").
- Hard rule: dismissible, never modal, never naggy. These are the levers the Milestone-5 trial tunes.

### 9. App icon + branding
- Generate a proper `.icns` from the mascot (multiple sizes) for Dock/Finder. (Scriptable with `sips` + `iconutil`, still no Xcode.)

### 10. Settings window
- Hotkey · launch at login · manage presets · nudge cadence · menu-bar-only · card opacity/behavior.

### 11. Packaging & distribution
- Personal use today: ad-hoc signing (what `build.sh` already does) is fine.
- To share beyond your Mac without Gatekeeper warnings: **Developer ID signing + notarization** (`codesign` + `notarytool` + `stapler` — all in Command Line Tools; needs a paid Apple Developer account, $99/yr). Still no Xcode required.

### 12. Testing checklist
- Reboot → intent + card restored. Login item fires.
- Hotkey capture from 3+ different frontmost apps → correct target each time.
- Finish with: running app / not-running app / URL / app with a tricky name.
- Fullscreen app → card still on top. Multi-display → card behaves.
- Permissions denied (Accessibility) → app degrades gracefully, tells you what to enable.

---

## Suggested sequencing

| Milestone | Contents | Why first |
|---|---|---|
| **M1 — Durable** | Persistence (1), launch at login (2), restore card | Nothing else matters if it forgets state or you have to launch it manually |
| **M2 — Capture anywhere** | Global hotkey (3), quick-capture (4), hotkey-moment auto-capture | The core daily interaction; makes it <3s to set an intent |
| **M3 — Targets** | Preset editor + app picker (5), resolve GTM | Removes the last typing friction |
| **M4 — Companion feel** | Card UX (7), menu-bar-only (6), icon (9), Settings (10) | Makes it live quietly in the background all day |
| **M5 — Does it actually work** | Attention mechanics (8) + **1-week self-trial with a tiny log** | The real validation: did it change behavior, or become wallpaper? |
| **M6 — Shareable** | Signing + notarization (11) | Only when you want others to run it |

## Explicit non-goals for Phase 1
- No iCloud sync, no accounts, no analytics.
- Multiple intents are allowed as a **queue**, but only **one current focus** is ever shown on the card/menu bar — never multiple at once. (Updated from the original strict-single design.)
- No iOS app yet. Revisit only if the week-long trial shows your real drift is on the phone, not the laptop.

## Decisions (resolved 2026-10-05)
1. Presets: **ChatGPT replaces GTM.** ✅
2. Global hotkey: **⌃⌥⇧ + a key** (proposing Space — confirm the key). ✅
3. **Dock icon + window** by default; menu bar stays secondary. ✅
4. **Nudges are in** — build the attention mechanics in M5 (pulse when drifted + optional soft notification, always dismissible).
5. Global-capture hotkey: **⌃⌥⇧U** (confirmed).
