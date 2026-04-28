# EisenMat

Personal-use iOS task manager built around the Eisenhower matrix. SwiftUI + SwiftData, local-only storage, with a home-screen widget for the "Do" quadrant.

A new task is created with two sliders (urgency and importance) and lands directly in the matrix. The four quadrants — **Schedule** (important / not urgent), **Do** (important / urgent), **Delegate** (urgent / not important), **Delete** (neither) — are derived from the slider values; thresholds are at 0.5 on each axis. Tasks at near-identical positions fan out diagonally so they don't overlap.

## Requirements

- macOS with Xcode 16+ (tested with Xcode 26.4.1).
- iOS Simulator runtime ≥ iOS 17.2. Newer Xcode versions may need an extra runtime download — see *First-time setup*.
- [`xcodegen`](https://github.com/yonaskolb/XcodeGen) — install with `brew install xcodegen`. The `.xcodeproj` is generated from `project.yml`; do not edit the project file by hand.

## First-time setup

```sh
brew install xcodegen
cd EisenMat
xcodegen generate
```

If `xcodebuild` later complains *"No simulator runtime version … available to use with iphonesimulator SDK version …"*, the simulator runtime that matches your Xcode SDK isn't installed. Either:

- open `EisenMat.xcodeproj` once in Xcode and let it offer the download, or
- run `xcodebuild -downloadPlatform iOS` (≈5 GB).

## Build and test

The project signs ad-hoc (`CODE_SIGN_IDENTITY = "-"`) so it builds and runs on the simulator with no Apple Developer team. To build for a device, set `DEVELOPMENT_TEAM` in `project.yml` and re-run `xcodegen generate`.

Pick any iOS 17.2+ simulator. Example with iPhone 17:

```sh
SIM_ID=$(xcrun simctl list devices available | awk '/iPhone 17 \(/{ match($0, /\(([-A-F0-9]+)\)/, m); print m[1]; exit }')

xcodebuild -project EisenMat.xcodeproj \
  -scheme EisenMat \
  -destination "platform=iOS Simulator,id=$SIM_ID" \
  build

xcodebuild -project EisenMat.xcodeproj \
  -scheme EisenMat \
  -destination "platform=iOS Simulator,id=$SIM_ID" \
  test
```

Or `open EisenMat.xcodeproj` and use Xcode normally.

## Project layout

```
EisenMat/
├── project.yml                       # xcodegen config — edit this, not the .xcodeproj
├── EisenMat/
│   ├── EisenMatApp.swift             # @main, ModelContainer, notification env
│   ├── EisenMat.entitlements         # App Group
│   ├── Assets.xcassets/
│   ├── Models/
│   │   ├── TaskItem.swift            # SwiftData @Model — note: NOT named `Task`
│   │   ├── Tag.swift                 # SwiftData @Model + Color hex helpers
│   │   └── Quadrant.swift            # enum + tint/symbol/subtitle styling
│   ├── Shared/
│   │   └── ModelContainer+Shared.swift  # also a member of the widget target
│   ├── Services/
│   │   └── NotificationScheduler.swift  # local notifications, protocol-backed
│   └── Views/
│       ├── RootTabView.swift
│       ├── Matrix/                   # main matrix screen, grid, task card, new-task sheet
│       ├── Detail/TaskDetailSheet.swift
│       ├── Tags/TagManagerView.swift
│       ├── Archive/ArchiveView.swift
│       └── Completed/CompletedView.swift
├── EisenMatWidget/                   # WidgetKit extension (Do-quadrant widget)
│   ├── Info.plist                    # hand-written; needs CFBundleVersion
│   ├── EisenMatWidget.entitlements
│   ├── DoQuadrantWidget.swift
│   ├── DoQuadrantWidgetView.swift
│   └── TaskSnapshot.swift
└── EisenMatTests/
    ├── QuadrantTests.swift
    ├── NotificationSchedulerTests.swift
    └── TagFilterTests.swift
```

The widget target reuses `TaskItem`, `Tag`, `Quadrant`, and `ModelContainer+Shared.swift` from the app sources; this is wired up in `project.yml` so `xcodegen` keeps both target memberships in sync.

## Things worth knowing

- **The model is `TaskItem`, not `Task`.** Naming it `Task` collides with Swift concurrency's `_Concurrency.Task` and breaks every `Task { … }` closure in the file. Don't rename it back without aliasing first.
- **App Group** `group.com.langseth.eisenmat` is used to share the SwiftData store between the app and the widget. Both targets need the same group ID in their entitlements; `xcodegen` keeps them aligned.
- **First launch** logs a recoverable CoreData error about the App Group's `Library/Application Support` directory not existing yet. SwiftData creates it on retry. Harmless.
- **Notification permission** is requested once on first launch via `NotificationScheduler.requestAuthorizationIfNeeded()`, gated by a `UserDefaults` flag.
- **Bundle ID prefix** is `com.langseth`. Change in `project.yml` (`bundleIdPrefix`, `PRODUCT_BUNDLE_IDENTIFIER`, and the App Group identifier in both entitlements files) before any TestFlight or App Store work.
- **Widget freshness** is driven by `WidgetCenter.shared.reloadAllTimelines()` after every mutation, with a 15-minute fallback. WidgetKit rate-limits reloads; rapid-fire edits won't each redraw immediately.

## Manual verification

1. Run on iPhone 17 simulator (iOS 17.2+).
2. Accept the notification permission prompt on first launch.
3. Tap **+**, type a title, move the urgency and importance sliders, watch the quadrant chip update live, **Add**.
4. Add a couple more tasks at the same slider values — confirm they fan out diagonally instead of stacking on the same pixel.
5. Tap a task → adjust sliders in the detail sheet → confirm it moves on the grid when the sheet closes.
6. Set a due date 1–2 minutes ahead, background the app, confirm the local notification fires.
7. From the Matrix toolbar, create two tags with different colors, tag a task with one, filter the matrix by that tag, confirm only matching tasks render.
8. Archive a task → it disappears from the Matrix and shows up under the **Archive** tab → tap **Restore**.
9. Check a task's checkbox → it strikes through and moves to the **Done** tab → tap **Undo** to bring it back.
10. Long-press the simulator home screen, add the **EisenMat** widget (small or medium), confirm Do-quadrant tasks appear.
