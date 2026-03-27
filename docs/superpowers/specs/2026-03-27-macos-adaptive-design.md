# macOS Adaptive Support — Design Spec

**Date:** 2026-03-27
**Status:** Approved

## Overview

Mở rộng Reality Check thành Mac Catalyst app với:
- **MenuBarExtra**: icon ở macOS status bar, click hiện pinned card + quick actions
- **NavigationSplitView**: main window dạng master-detail (sidebar list + detail form) — tự collapse về single-column trên iOS
- **Background agent**: app tồn tại ở menu bar kể cả khi đóng hết cửa sổ

---

## 1. App Structure & Scenes

### Scene graph

```
RealityCheckApp
├── WindowGroup (id: "main")          — iOS + macOS
│   └── NavigationSplitView
│       ├── sidebar: CardSidebarView
│       └── detail: CardDetailView
└── MenuBarExtra                       — macOS Catalyst only (#if targetEnvironment)
    └── MenuBarCardView
```

### `RealityCheckApp` state

```swift
// Extract ModelContainer thành property để share giữa WindowGroup và MenuBarExtra
let sharedContainer = try! ModelContainer(
    for: RealityCard.self,
    configurations: AppGroupContainer.modelConfiguration
)

@State private var selectedCard: RealityCard?
@State private var columnVisibility: NavigationSplitViewVisibility = .automatic
@State private var appState = AppState()
```

`sharedContainer` được pass vào cả hai scene qua `.modelContainer(sharedContainer)` — đảm bảo MenuBarExtra và WindowGroup dùng cùng một store instance.

`AppState` là `@Observable` class dùng để signal từ menu bar vào main window (ví dụ: trigger open create form).

### iOS behavior

Trên iOS `NavigationSplitView` với `.automatic` visibility tự collapse thành single-column — behavior y hệt hiện tại, không cần thêm code.

---

## 2. View Refactor

### Tách `CardListView` thành hai view

**`CardSidebarView`**
- Chứa toàn bộ list logic hiện tại từ `CardListView`: pinned section, unpinned section, swipe actions, empty state
- Thêm `selection: Binding<RealityCard?>` để drive detail column
- Toolbar: nút Settings + nút "+" (tạo card)

**`CardDetailView`**
- Nhận `selection: RealityCard?`
- `nil` → placeholder "Chọn một card để xem"
- non-nil → `CardFormView(card: card)`

`CardListView` cũ có thể xóa sau khi refactor xong.

### macOS toolbar adjustments

Các modifier iOS-only cần wrap `#if os(iOS)`:
- `.navigationBarTitleDisplayMode(.large)`
- `.toolbarBackground(.hidden, for: .navigationBar)`

Swipe actions trên Catalyst render thành right-click context menu — giữ nguyên, không cần thay đổi.

---

## 3. MenuBarExtra

### Declaration

```swift
#if targetEnvironment(macCatalyst)
MenuBarExtra("Reality Check", systemImage: "pin.circle.fill") {
    MenuBarCardView()
        .modelContainer(sharedModelContainer)
        .environment(appState)
}
.menuBarExtraStyle(.window)
#endif
```

### `MenuBarCardView` layout (~320pt wide)

```
┌─────────────────────────────┐
│  [AuroraBackground subtle]  │
│                             │
│  ┌─ Pinned card ──────────┐ │
│  │  GlassCard(.pinned)   │ │
│  └───────────────────────┘ │
│   (nếu nil: empty state)   │
│                             │
│  [Mở app]    [Thêm card]   │
│                    [Quit]   │
└─────────────────────────────┘
```

### Actions

| Action | Implementation |
|--------|----------------|
| Mở app | `openWindow(id: "main")` |
| Thêm card | `openWindow(id: "main")` + `appState.pendingAction = .openCreateForm` |
| Quit | `NSApplication.shared.terminate(nil)` |

### Data

`MenuBarCardView` dùng `@Query(filter: #Predicate { $0.isPinned })` — live update tự động khi card được pin/unpin trong app chính. Cùng SwiftData store qua App Group.

---

## 4. Background Agent & App Lifecycle

### `LSUIElement`

Thêm vào `RealityCheck/Info.plist`:

```xml
<key>LSUIElement</key>
<true/>
```

- macOS: app không hiện trong Dock, không có app menu bar truyền thống
- iOS: key bị ignore hoàn toàn

### Ngăn terminate khi đóng window

```swift
#if targetEnvironment(macCatalyst)
class AppDelegate: NSObject, UIApplicationDelegate {
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: UIApplication) -> Bool {
        return false
    }
}
#endif
```

Gán trong `RealityCheckApp`:
```swift
@UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
```

### `AppState` signal

```swift
@Observable
class AppState {
    enum PendingAction { case none, openCreateForm }
    var pendingAction: PendingAction = .none
}
```

`CardSidebarView` observe `appState.pendingAction`, khi thấy `.openCreateForm` thì set `showingCreateForm = true` rồi reset về `.none`.

---

## 5. Previews

### Files mới/cập nhật

| File | Nội dung |
|------|----------|
| `CardSidebarView+Preview.swift` | Sidebar standalone với mock data |
| `CardDetailView+Preview.swift` | Detail với card được chọn + nil state |
| `NavigationSplitView+Preview.swift` | Full split layout preview |
| `MenuBarCardView+Preview.swift` | Menu bar popover với pinned card + nil state |

### Mock data

Tạo `Previews/PreviewSampleData.swift` với:
- 1 pinned manual card
- 1 formula countdown card
- 1 unpinned card

Dùng chung cho tất cả previews.

---

## 6. Testing

### Không thay đổi

`FormulaEngine`, `CardListViewModel`, `CardFormViewModel` — giữ nguyên, tests hiện tại không bị ảnh hưởng.

### Unit test bổ sung

`AppState` transitions: `.none` → `.openCreateForm` → `.none`

### Manual verification checklist

- [ ] iOS: NavigationSplitView collapse về single column
- [ ] macOS: Main window hiện đúng master-detail layout
- [ ] macOS: MenuBarExtra hiện icon ở status bar
- [ ] macOS: Click icon → popover hiện pinned card
- [ ] macOS: Nếu không có pinned card → hiện empty state
- [ ] macOS: "Mở app" → window xuất hiện
- [ ] macOS: "Thêm card" → window mở + create form sheet hiện
- [ ] macOS: "Quit" → app thoát hoàn toàn
- [ ] macOS: Đóng window → app vẫn còn ở menu bar
- [ ] macOS: Pin/unpin trong app → menu bar reflect ngay
- [ ] iOS build: `LSUIElement` không gây lỗi

---

## File Changes Summary

### New files
- `RealityCheck/Views/CardSidebarView.swift`
- `RealityCheck/Views/CardDetailView.swift`
- `RealityCheck/Views/MenuBarCardView.swift`
- `RealityCheck/App/AppState.swift`
- `RealityCheck/App/AppDelegate.swift` (toàn bộ file wrapped trong `#if targetEnvironment(macCatalyst)` ở file level)
- `RealityCheck/Previews/CardSidebarView+Preview.swift`
- `RealityCheck/Previews/CardDetailView+Preview.swift`
- `RealityCheck/Previews/NavigationSplitView+Preview.swift`
- `RealityCheck/Previews/MenuBarCardView+Preview.swift`
- `RealityCheck/Previews/PreviewSampleData.swift`

### Modified files
- `RealityCheck/App/RealityCheckApp.swift` — thêm scenes, AppState, AppDelegate
- `RealityCheck/Views/CardListView.swift` — refactor → CardSidebarView (hoặc xóa)
- `RealityCheck/Views/CardFormView.swift` — bỏ iOS-only modifiers
- `RealityCheck/Info.plist` — thêm `LSUIElement`
