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

### Project Structure

```
RealityCheck/
├── App/          — @main entry, ModelContainer setup
├── Core/
│   ├── Components/   — GlassKit UI library (AuroraBackground, GlassCard, GlassButton,
│   │                   GlassField, GlassToggle, GlassModifiers, FormulaChip,
│   │                   WidgetPreviewView, ShimmerView, SectionLabel)
│   ├── Extensions/   — Color+Aurora.swift (hex init, aurora palette, accentColor)
│   └── Utils/        — FormulaEngine, NotificationService, AppGroupContainer
├── Models/       — RealityCard.swift (@Model, CardType, FormulaType enums)
├── Previews/     — #Preview macros only, separated from production code
├── ViewModels/   — @Observable ViewModels (CardListViewModel, CardFormViewModel, SettingsViewModel)
└── Views/        — CardListView, CardFormView, SettingsView
```

### Data Model

`RealityCard` is the sole SwiftData `@Model`:
- `type: CardType` — `.manual` (user-entered) or `.formula` (computed)
- `formula: FormulaType?` — `.divide` (A÷B), `.count` (A/B display), `.subtract` (A−B), `.countdown` (days until date)
- `isPinned: Bool` — at most one card pinned at a time; the widget shows only the pinned card

### Formula Engine

`FormulaEngine` is a pure enum with static methods. `displayValue(for:)` is the single source of truth for computed display strings — used in list rows, `CardFormViewModel.previewDisplayValue`, widget, and notifications. `formatNumber(_:)` is also used directly for live preview calculations.

### MVVM Pattern

Views own `@Query` and `@Environment(\.modelContext)` (SwiftData requires these in Views). Business logic lives in `@Observable` ViewModels held as `@State`:
- `CardFormViewModel` — all form fields as `var` properties; `init(card:)` populates from an existing card. Views bind to fields via `@Bindable var vm = viewModel` inside `body`.
- `CardListViewModel` — pin/delete actions
- `SettingsViewModel` — notification scheduling

### App ↔ Widget Data Sharing

Both targets share a SwiftData store via App Group `group.com.quannh.realitycheck`. `AppGroupContainer` provides the shared `ModelConfiguration`; all writes happen in the main app.

**Critical:** `RealityCard.swift`, `FormulaEngine.swift`, and `AppGroupContainer.swift` are physically duplicated into `RealityCheckWidget/` (Swift can't share source files across targets without a framework). Any change to these files in `RealityCheck/` must be mirrored in `RealityCheckWidget/`.

After pinning/unpinning, always call `WidgetCenter.shared.reloadAllTimelines()`.

### GlassKit & Aurora Colors

`Core/Components/` implements the Aurora Liquid Glass aesthetic. `Core/Extensions/Color+Aurora.swift` defines the palette and `accentColor` extensions — each `FormulaType` maps to a color, which drives card tinting throughout the app and widget.

Aurora palette (widget duplicates these as hardcoded hex strings in `RealityCheckEntry.accentColor`):
- `.auroraRed` `#ff6b6b` — `.manual`
- `.auroraTeal` `#64dfdf` — `.divide`
- `.auroraPurple` `#c77dff` — `.count`
- `.auroraYellow` `#ffd93d` — `.subtract`
- `.auroraGreen` `#00f5a0` — `.countdown`

### Testing

Tests use Swift Testing (`@Suite`, `@Test`), not XCTest. Edge cases: divide-by-zero → `"∞"`, past-date countdown → `"0"`, nil inputs → `"--"`.

### UI Language

App UI text is in Vietnamese. Respond to the user in Vietnamese.

### Localization

UI strings dùng `Localizable.xcstrings` (String Catalog). Không hardcode chuỗi trực tiếp trong View — dùng `String(localized: "key")` hoặc `Text("key")` (SwiftUI tự resolve key từ catalog).

### Xcode Project — PBXFileSystemSynchronizedRootGroup

Target `RealityCheck` dùng **`PBXFileSystemSynchronizedRootGroup`**: Xcode tự động include toàn bộ file trong thư mục `RealityCheck/` vào target mà không cần đăng ký thủ công trong `project.pbxproj`. **Không thêm `PBXBuildFile` hoặc `PBXFileReference` thủ công** cho các file trong thư mục này — sẽ gây lỗi duplicate (ví dụ: `Cannot have multiple Localizable.xcstrings files in same target`).

### Git Worktrees

Worktree để làm việc song song nên đặt ở `worktrees/<tên-branch>` trong project root (đã có trong `.gitignore`). Không đặt worktree trong `.claude/worktrees/` — thư mục `.claude/` được git track nên worktree bên trong sẽ bị commit lên.

**Sau khi merge xong, xoá worktree ngay:**
```bash
git worktree remove worktrees/<tên-branch>
```

### SourceKit False Positives trong Worktree

Khi worktree nằm bên trong project root (ví dụ `worktrees/feature-x/`), SourceKit của Xcode có thể báo lỗi giả (`Cannot find type`, `No such module`) cho các file trong worktree vì không có project context. Đây là **false positive** — dùng `xcodebuild` để xác nhận build thực tế, không dựa vào SourceKit diagnostics.
