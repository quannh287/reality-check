# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build & Test Commands

```bash
# Build the app
xcodebuild build -scheme RealityCheck -project RealityCheck.xcodeproj -destination 'platform=iOS Simulator,name=iPhone 17 Pro'

# Run all tests
xcodebuild test -scheme RealityCheck -project RealityCheck.xcodeproj -destination 'platform=iOS Simulator,name=iPhone 17 Pro'

# Run a single test class
xcodebuild test -scheme RealityCheck -project RealityCheck.xcodeproj -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:RealityCheckTests/FormulaEngineTests

# Build the widget extension
xcodebuild build -scheme RealityCheckWidget -project RealityCheck.xcodeproj -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
```

## Architecture

**Reality Check** is an iOS app (SwiftUI + SwiftData + WidgetKit) that lets users pin "reality cards" — facts or computed metrics — to their home screen as a daily reminder. The app is dark-mode only.

### Data Model

`RealityCard` (`RealityCheck/Models/RealityCard.swift`) is the sole SwiftData `@Model`:
- `type: CardType` — `.manual` (user-entered value) or `.formula` (computed)
- `formula: FormulaType?` — `.divide` (A÷B), `.count` (A/B display), `.subtract` (A−B), `.countdown` (days until date)
- `isPinned: Bool` — at most one card should be pinned; the widget shows the pinned card

### Formula Engine

`FormulaEngine` (`RealityCheck/Models/FormulaEngine.swift`) is a pure enum with static methods. `displayValue(for:)` takes a `RealityCard` and returns a formatted `String`. This is the single source of truth for computed values — used in list rows, form preview, widget, and notifications.

### App ↔ Widget Data Sharing

Both targets share a SwiftData store via App Groups:
- Group ID: `group.com.quannh.realitycheck`
- `AppGroupContainer` (`RealityCheck/Shared/AppGroupContainer.swift`) provides the shared `ModelConfiguration`
- The widget queries the shared store for the pinned card; all writes happen in the main app
- After pinning/unpinning, call `WidgetCenter.shared.reloadAllTimelines()` to refresh the widget
- Widget timeline refreshes every hour

**Important:** `RealityCard.swift`, `FormulaEngine.swift`, and `AppGroupContainer.swift` are duplicated into the `RealityCheckWidget` target (Swift files cannot be shared across targets without a framework). Changes to these files in `RealityCheck/` must be mirrored in `RealityCheckWidget/`.

### GlassKit Design System

`RealityCheck/GlassKit/` is the app's internal UI component library implementing the Aurora Liquid Glass aesthetic:

- `AuroraBackground` — animated dark background with three blurred color orbs (no animation in widget contexts)
- `GlassCard` — card component with `.pinned` (hero) and `.unpinned` (compact) styles; pinned cards show a progress bar for `.divide` formula cards
- `GlassModifiers` — view extension methods: `.glassCard()` (cornerRadius 16), `.glassField()` (cornerRadius 10), `.glassRow()` (grouped rows with custom per-corner radii); all use `.ultraThinMaterial` + gradient overlay + specular border
- `ShimmerView` — shimmer overlay applied to all GlassCards
- `GlassButton`, `GlassField`, `GlassToggle`, `FormulaChip` — styled form controls

**Aurora color palette** (defined in `AuroraBackground.swift`, duplicated as hex literals in the widget):
- `.auroraRed` `#ff6b6b` — manual cards
- `.auroraTeal` `#64dfdf` — `.divide`
- `.auroraPurple` `#c77dff` — `.count`
- `.auroraYellow` `#ffd93d` — `.subtract`
- `.auroraGreen` `#00f5a0` — `.countdown`
- `.auroraBlue` `#00b4ff` — background orb only

Each `FormulaType` has an `.accentColor` extension in `AuroraBackground.swift`. The widget duplicates these as hardcoded hex strings in `RealityCheckEntry.accentColor`.

### Views

Views use `@Query` and `@Environment(\.modelContext)` directly — no explicit view models. Key views:
- `CardListView` — root screen; two sections (pinned, others); swipe to pin/delete
- `CardFormView` — create/edit form with live `WidgetPreviewView` showing widget appearance in real time
- `SettingsView` — notification toggle + time picker, persisted via `@AppStorage`

### Notifications

`NotificationService` (`RealityCheck/Services/NotificationService.swift`) schedules a single daily `UNCalendarNotificationTrigger`. Content is built from the pinned card at schedule time. Identifier: `"daily-reality-check"`.

### Testing

Tests use Swift Testing (`@Suite`, `@Test` macros), not XCTest. `FormulaEngineTests` is the most comprehensive — covers all formula types and edge cases (divide-by-zero returns `"∞"`, past-date countdown returns `"0"`, missing inputs return `"--"`).

### UI Language

App UI text is in Vietnamese.
