# DebugSwift Integration — Design Spec

**Date:** 2026-03-25
**Status:** Implemented

## Context

Integrate DebugSwift into the Reality Check iOS app to provide an in-app debugging console during development. Must be completely absent from Release builds.

## What DebugSwift Provides (relevant features)

| Feature | Use case |
|---|---|
| Performance monitor (FPS/memory/CPU) | Validate `AuroraBackground` animation cost |
| File system browser | Inspect App Group SQLite store (`RealityCheck.store`) |
| UserDefaults viewer | Verify `notificationEnabled`, `notificationHour`, `notificationMinute` |
| Crash reporter | Catch `try!` panics in `ModelContainer` init |
| Console log viewer | View `print()` output on device without Xcode attached |
| Notification simulator | Test daily reminders without waiting for real time |

## Design

### Package

- **Source:** `https://github.com/DebugSwift/DebugSwift`
- **Pinned version:** commit `dcab247` (`rc-1.14.5`) — first commit with Swift 6 concurrency fixes
- **Reason not using `1.13.0`:** has Swift 6 actor-isolation bugs in `HTTPProtocol.swift` and `WebSocketMonitor.swift` that cause build errors in this project's strict concurrency configuration
- **Target membership:** `RealityCheck` only — NOT `RealityCheckWidgetExtension`

### Initialization

Single call in `RealityCheckApp.init()`, guarded at two levels:

1. **`#if DEBUG` import** — module not referenced in Release binary; linker excludes it
2. **`XCODE_RUNNING_FOR_PREVIEWS` guard** — prevents DebugSwift from attaching its `UIWindow` overlay to Xcode canvas previews

```swift
#if DEBUG
@MainActor
private func setupDebugSwift() {
    guard ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] != "1" else { return }
    DebugSwift().setup().show()
}
#endif
```

### Widget Target

No changes. Widget runs in a background extension process with no `UIWindow` surface.

## Files Changed

- `RealityCheck.xcodeproj/project.pbxproj` — SPM package reference + product dependency (RealityCheck target only)
- `RealityCheck/App/RealityCheckApp.swift` — `#if DEBUG` import + `setupDebugSwift()` method

## Verification

```bash
# Main app (DEBUG — DebugSwift included and compiled)
xcodebuild build -scheme RealityCheck -project RealityCheck.xcodeproj \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro'

# Widget (must build clean, no DebugSwift)
xcodebuild build -scheme RealityCheckWidgetExtension -project RealityCheck.xcodeproj \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
```

Both pass with `BUILD SUCCEEDED`.
