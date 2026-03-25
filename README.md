# Reality Check

> A home screen widget that forces you to confront hard facts before making impulsive decisions.

![Swift](https://img.shields.io/badge/Swift-5.10-orange.svg)
![iOS](https://img.shields.io/badge/iOS-17%2B-blue.svg)
![SwiftUI](https://img.shields.io/badge/SwiftUI-brightgreen.svg)
![WidgetKit](https://img.shields.io/badge/WidgetKit-purple.svg)

## What is Reality Check?

When facing major career or financial decisions — quitting a job, switching roles — emotions and excitement can override rational thinking. Reality Check lets you pin a single hard fact (your runway in months, days until a deadline, your monthly surplus) to your home screen as a widget. Every time you look at your phone, you see the number that matters most.

The widget is the primary interface. The app is just where you enter and update the data.

## Screenshots

<!-- Add app and widget screenshots here -->

## Features

- **Reality Cards** — create cards representing hard facts about your current situation
- **4 formula types** — divide (A÷B), count (A/B), subtract (A−B), countdown (days until a date)
- **Home screen widget** — pin one card; the widget shows its computed value front and center
- **Aurora Liquid Glass UI** — dark-mode-only, glassmorphism aesthetic with per-formula accent colors
- **Localization** — English and Vietnamese (EN/VI)

## Architecture

```
┌─────────────┐     App Groups      ┌──────────────────┐
│   App        │  ──────────────→   │   Widget          │
│  (SwiftUI)   │   (shared data)    │  (WidgetKit)      │
│              │                    │                   │
│ • CRUD cards │                    │ • Read pinned card│
│ • Input data │                    │ • Bold number     │
│ • Pin card   │                    │ • Context line    │
└─────────────┘                     └──────────────────┘
       │
       ▼
  SwiftData (App Group container)
```

**Stack:** SwiftUI + SwiftData + WidgetKit + App Groups

### Project Structure

```
RealityCheck/
├── App/              — @main entry, ModelContainer setup
├── Core/
│   ├── Components/   — GlassKit UI library (AuroraBackground, GlassCard, GlassButton, etc.)
│   ├── Extensions/   — Color+Aurora.swift (hex init, aurora palette, accentColor per FormulaType)
│   └── Utils/        — FormulaEngine, NotificationService, AppGroupContainer
├── Models/           — RealityCard.swift (@Model, CardType, FormulaType enums)
├── Previews/         — #Preview macros only, separated from production code
├── ViewModels/       — CardListViewModel, CardFormViewModel, SettingsViewModel (@Observable)
└── Views/            — CardListView, CardFormView, SettingsView
```

MVVM pattern: Views own `@Query` and `@Environment(\.modelContext)` (SwiftData requirement). Business logic lives in `@Observable` ViewModels held as `@State`.

## Data Model

### RealityCard

| Field        | Type                    | Description                                      |
|--------------|-------------------------|--------------------------------------------------|
| `id`         | UUID                    | Unique identifier                                |
| `title`      | String                  | Card name — e.g. "Runway"                        |
| `type`       | `CardType`              | `.manual` or `.formula`                          |
| `value`      | Double?                 | Direct value (manual cards only)                 |
| `inputA`     | Double?                 | First formula input                              |
| `inputB`     | Double?                 | Second formula input                             |
| `inputALabel`| String?                 | Label for input A                                |
| `inputBLabel`| String?                 | Label for input B                                |
| `formula`    | `FormulaType?`          | `.divide`, `.count`, `.subtract`, `.countdown`   |
| `targetDate` | Date?                   | For `.countdown` formula                         |
| `unit`       | String                  | Display unit — "months", "days", etc.            |
| `contextLine`| String                  | Subtext below the number on the widget           |
| `isPinned`   | Bool                    | Whether this card is shown on the widget         |

### Formula Types

| Formula     | Operation      | Example                          | Output     |
|-------------|----------------|----------------------------------|------------|
| `divide`    | A ÷ B          | 30M savings ÷ 15M/month          | "2 months" |
| `count`     | A / B display  | 1 confirmed / 3 total offers     | "1/3"      |
| `subtract`  | A − B          | 20M income − 15M expenses        | "5M"       |
| `countdown` | target − today | Days until a date                | "12 days"  |

`FormulaEngine` is the single source of truth for all computed display strings — used in list rows, form preview, widget, and notifications.

## Getting Started

**Requirements:**
- Xcode 16+
- iOS 17+ (simulator or device)

**Setup:**
```bash
git clone https://github.com/<your-username>/reality-check.git
cd reality-check
open RealityCheck.xcodeproj
```

Select the `RealityCheck` scheme and run on an iPhone 17 Pro simulator or your device.

## Build & Test

```bash
# Build the app
xcodebuild build \
  -scheme RealityCheck \
  -project RealityCheck.xcodeproj \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro'

# Run all tests
xcodebuild test \
  -scheme RealityCheck \
  -project RealityCheck.xcodeproj \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro'

# Run a single test class
xcodebuild test \
  -scheme RealityCheck \
  -project RealityCheck.xcodeproj \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -only-testing:RealityCheckTests/FormulaEngineTests

# Build the widget extension
xcodebuild build \
  -scheme RealityCheckWidget \
  -project RealityCheck.xcodeproj \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
```

Tests use Swift Testing (`@Suite`, `@Test`), not XCTest.

## Contributing

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/your-feature`
3. Make your changes and run the full test suite
4. Open a pull request against `main`

### Important: Shared Source Files

Three files are physically duplicated across both targets because Swift cannot share source files across targets without a framework:

- `RealityCard.swift`
- `FormulaEngine.swift`
- `AppGroupContainer.swift`

**Any change to these files in `RealityCheck/` must be mirrored in `RealityCheckWidget/`**, otherwise the widget will diverge from the app.

### Code Style

- Dark-mode only — do not add light mode support
- UI strings go through `Localizable.xcstrings` (String Catalog). Do not hardcode strings in Views — use `String(localized: "key")` or `Text("key")`
- The `RealityCheck` target uses `PBXFileSystemSynchronizedRootGroup`: Xcode auto-includes all files in `RealityCheck/`. Do not manually add `PBXBuildFile` or `PBXFileReference` entries for files in this directory

## License

MIT License — see [LICENSE](LICENSE) for details.
