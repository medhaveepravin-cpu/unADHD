# Intent Spike — Phase 0 (kill-or-continue)

Goal: prove that a Live Activity can hold **one intent** glanceable in the Dynamic Island
while you're inside other apps, with a working **one-tap** button. Nothing else matters yet.
This is throwaway code — don't polish it.

Requires: Xcode (full, not just Command Line Tools), an iPhone 14 Pro or newer on iOS 17+.
A real device is best; the Simulator shows Live Activities but can't reproduce the
"wander through Mail for 20 minutes" test.

---

## Assembly (~5 minutes)

### 1. New project
- Xcode ▸ File ▸ New ▸ Project ▸ **iOS App**.
- Product Name: **IntentSpike**. Interface: **SwiftUI**. Language: **Swift**.
- Replace the generated `IntentSpikeApp.swift` and `ContentView.swift` with the ones in
  `App/`. Also add `App/LiveActivityController.swift` to the app target.

### 2. Add the Widget Extension (this creates all the Live Activity wiring for you)
- File ▸ New ▸ Target ▸ **Widget Extension**. Name it **IntentWidget**.
- **Check "Include Live Activity"**. Uncheck "Include Configuration App Intent".
- When prompted to activate the new scheme, click **Activate**.
- Delete the sample files Xcode generated inside the IntentWidget group
  (e.g. `IntentWidget.swift`, `IntentWidgetBundle.swift`, `IntentWidgetLiveActivity.swift`,
  attributes file) — we replace them. Keep the `Assets.xcassets` and `Info.plist`.
- Add `Widget/IntentWidgetBundle.swift` and `Widget/IntentLiveActivity.swift` to the
  **IntentWidget** target.

### 3. Shared files — add to BOTH targets
Select each of these, open the File Inspector (right panel), and under **Target Membership**
tick **both** IntentSpike and IntentWidget:
- `Shared/IntentActivityAttributes.swift`
- `Shared/IntentAppIntents.swift`

### 4. One Info.plist key (app target)
- Select the **IntentSpike** target ▸ Info tab ▸ add key
  **`NSSupportsLiveActivities`** = **YES**.
  (The widget extension doesn't need it.)

### 5. Run
- Select the **IntentSpike** app scheme (not the widget) and a 14 Pro+ / iOS 17+ device.
- Build & run.

---

## Run the test
1. In the app, tap **Start**.
2. Press Home / swipe up — go live in **Mail, Safari, Messages** for 20–30 minutes.
3. Watch the Dynamic Island and record answers in `FINDINGS.md`:
   - Glanceable, or collapses to a dot you have to go hunting for?
   - Tap the island / **Finish** → does it bring you back in **one** tap?
   - **Done** → clears the intent without yanking you out of the current app?
   - Survives lock/unlock, Low Power Mode, a reboot, and the ~8h ceiling?

If yes → we build Phase 1. If the island keeps collapsing or the reminder doesn't
catch your eye at the moment you drift → we rethink the surface before investing.

## Known limits this spike will surface (expected, not bugs)
- Compact island = basically one glyph per side; the two buttons live in the **expanded**
  view and on the Lock Screen. Compact relies on `widgetURL` for one-tap re-entry.
- "Finish" here just opens Mail (`mailto:`). In the real app it deep-links to the
  task's actual app.
- Live Activity ends by ~8–12h; the user can swipe it away.
