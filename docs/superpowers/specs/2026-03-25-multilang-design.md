# Multi-Language Support (EN / VI) — Design Spec

**Date:** 2026-03-25
**Status:** Approved

## Overview

Add English and Vietnamese localization to Reality Check. The app automatically follows the iOS system language (VI → VI, EN → EN, anything else → EN fallback). Users can override per-app language via iOS Settings → Reality Check → Language (iOS 16+ Per-App Language, no in-app UI needed).

## Approach

**String Catalog (`.xcstrings`)** — Xcode 15+ format. Single JSON file per target containing all translations. Development language is English (base/fallback).

**Key convention:** dot-notation lowercase — e.g. `card.list.section.pinned`. No spaces, no uppercase, no diacritics in keys.

## Files

| File | Action |
|------|--------|
| `RealityCheck/Localizable.xcstrings` | Create — main app catalog |
| `RealityCheckWidget/Localizable.xcstrings` | Create — widget catalog (minimal strings) |
| `RealityCheck/Views/CardListView.swift` | Replace hardcoded strings |
| `RealityCheck/Views/CardFormView.swift` | Replace hardcoded strings |
| `RealityCheck/Views/SettingsView.swift` | Replace hardcoded strings |
| `RealityCheck/Core/Utils/NotificationService.swift` | Replace hardcoded strings |
| `RealityCheckWidget/Core/Utils/NotificationService.swift` | Mirror changes (physically duplicated file) |
| `RealityCheck.xcodeproj` | Add EN + VI localization |

## Language Resolution

```
System language = vi   →  Vietnamese
System language = en   →  English
System language = other →  English (development language fallback)
```

Per-App Language override: iOS 16+ exposes this automatically in iOS Settings → Reality Check → Language. No in-app UI required.

## String Inventory

### CardListView

| Key | EN | VI |
|-----|----|----|
| `app.title` | Reality Check | Reality Check |
| `card.list.section.pinned` | Pinned | Đã ghim |
| `card.list.section.all` | All Cards | Tất cả thẻ |
| `card.list.empty.headline` | No Reality Cards yet | Chưa có Reality Card nào |
| `card.list.empty.subheadline` | Create your first card to\nface reality | Tạo card đầu tiên để\nđối diện thực tế |
| `card.list.empty.cta` | ＋ Create first card | ＋ Tạo card đầu tiên |
| `card.list.action.pin` | Pin to widget | Pin lên widget |
| `card.list.action.delete` | Delete | Xoá |

Note: `card.list.section.all` only renders when a pinned card also exists (conditional in CardListView). This is correct behavior — no change needed.

### CardFormView

| Key | EN | VI |
|-----|----|----|
| `card.form.title.create` | Create Card | Tạo Card |
| `card.form.title.edit` | Edit Card | Sửa Card |
| `card.form.action.cancel` | Cancel | Huỷ |
| `card.form.action.save` | Save | Lưu |
| `card.form.section.info` | Info | Thông tin |
| `card.form.field.title` | Title | Tiêu đề |
| `card.form.type.manual` | Manual | Manual |
| `card.form.type.formula` | Formula | Formula |
| `card.form.section.value` | Value | Giá trị |
| `card.form.field.value` | Number | Số liệu |
| `card.form.section.formula` | Formula | Công thức |
| `card.form.section.inputs` | Inputs | Inputs |
| `card.form.section.display` | Display | Hiển thị |
| `card.form.field.unit` | Unit (days, months, M...) | Đơn vị (ngày, tháng, triệu...) |
| `card.form.field.context` | Context line | Context line |
| `card.form.field.label.a` | Name (e.g. Revenue) | Tên (VD: Doanh số) |
| `card.form.field.label.b` | Name (e.g. Target) | Tên (VD: Mục tiêu) |
| `card.form.field.value.placeholder` | Value | Giá trị |
| `card.form.field.target.date` | Target date | Ngày đích |
| `card.form.countdown.remaining` | → %@ days remaining | → %@ ngày còn lại |
| `card.form.action.pin` | Pin to widget | Pin lên widget |
| `card.form.action.unpin` | Unpin | Bỏ pin |
| `card.form.preview.label` | Live preview | Live preview |
| `card.form.preview.section` | Preview | Preview |

Intentional loanwords (same in both languages, not an oversight):
- `card.form.type.manual` / `card.form.type.formula` — "Manual" / "Formula" are accepted loanwords in Vietnamese tech context
- `card.form.section.inputs` — "Inputs" used as-is
- `card.form.field.context` — "Context line" used as-is
- `card.form.preview.label` / `card.form.preview.section` — "Live preview" / "Preview" used as-is

### SettingsView

| Key | EN | VI |
|-----|----|----|
| `settings.title` | Settings | Cài đặt |
| `settings.notification.section` | Daily Notification | Thông báo hàng ngày |
| `settings.notification.toggle.title` | Enable notifications | Bật thông báo |
| `settings.notification.toggle.subtitle` | Daily Reality Card reminder | Nhắc nhở Reality Card mỗi ngày |
| `settings.notification.time.title` | Reminder time | Thời gian nhắc |
| `settings.notification.time.subtitle` | Every day at | Mỗi ngày vào lúc |
| `settings.notification.status.on` | Scheduled · Every day at %@ | Đã lên lịch · Mỗi ngày %@ |
| `settings.notification.status.off` | Notifications disabled | Thông báo đã tắt |
| `settings.widget.section` | Widget | Widget |
| `settings.widget.showing` | Showing | Đang hiển thị |
| `settings.widget.refresh` | Refresh widget | Làm mới widget |
| `settings.widget.refresh.action` | Refresh ↺ | Làm mới ↺ |

Note: `settings.widget.showing` is the row _label_ only. The dynamic value next to it (`pinnedCards.first?.title ?? "--"`) is user-entered data — not localized. The `"--"` fallback is language-neutral and needs no key.

### NotificationService

`NotificationService.buildContent(for:)` has two code paths:

| Key | EN | VI |
|-----|----|----|
| `notification.title` | Reality Check | Reality Check |
| `notification.body.format` | %1$@ %2$@ — %3$@ | %1$@ %2$@ — %3$@ |
| `notification.body.empty` | Open app to create your first Reality Card | Mở app để tạo Reality Card đầu tiên |

`notification.body.format` takes three positional args: computed display value, unit, context line. The format string is the same in both languages (user-entered values; sentence structure is identical). `notification.body.empty` is shown when no card is pinned.

## Implementation Notes

### SwiftUI Text (automatic)

String literals in `Text()` auto-resolve from Localizable.xcstrings:
```swift
Text("card.list.section.pinned")   // → "Pinned" or "Đã ghim"
```

### Non-Text contexts (navigationTitle, GlassField placeholders, Button labels)

`.navigationTitle` and `GlassField` take `String`, not `Text` — use `String(localized:)`:
```swift
.navigationTitle(String(localized: "app.title"))          // CardListView
.navigationTitle(String(localized: "settings.title"))      // SettingsView
GlassField(String(localized: "card.form.field.title"), text: $vm.title)
```

### String interpolation in Text()

For keys that contain a `%@` substitution, use Swift string interpolation directly inside `Text()`. `String.LocalizationValue` handles the substitution automatically — xcstrings looks up the key `"<prefix> %@"`.

Examples:
```swift
// card.form.countdown.remaining %@  →  "→ %@ days remaining" / "→ %@ ngày còn lại"
Text("card.form.countdown.remaining \(viewModel.previewDisplayValue)")

// settings.notification.status.on %@  →  "Scheduled · Every day at %@" / "Đã lên lịch · Mỗi ngày %@"
Text("settings.notification.status.on \(timeString)")
```

### NotificationService (no SwiftUI — use String(format:))

`NotificationService` uses `UNMutableNotificationContent`, not SwiftUI. Use `String(format:)` for multi-arg substitution:
```swift
content.title = String(localized: "notification.title")

if let card {
    let value = FormulaEngine.displayValue(for: card)
    let format = String(localized: "notification.body.format")
    content.body = String(format: format, value, card.unit, card.contextLine)
} else {
    content.body = String(localized: "notification.body.empty")
}
```

### Widget catalog

The widget's `Localizable.xcstrings` only needs strings that appear in widget views (e.g., empty-state text if the widget renders any). It does **not** need notification keys — notifications are scheduled by the main app target at schedule time, so `buildContent` runs in the main app context and uses the main app's catalog.

### Duplicated files

`NotificationService.swift` is physically duplicated in `RealityCheckWidget/Core/Utils/`. Changes must be mirrored to both copies. The widget copy will use `RealityCheckWidget/Localizable.xcstrings`; since notification strings are scheduled from the main app, the widget catalog will not include `notification.*` keys.

## Out of Scope

- RTL language support
- More than 2 languages
- In-app language picker UI (iOS Per-App Language handles this natively)
