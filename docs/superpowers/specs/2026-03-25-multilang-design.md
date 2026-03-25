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
| `RealityCheckWidget/Localizable.xcstrings` | Create — widget catalog |
| `RealityCheck/Views/CardListView.swift` | Replace hardcoded strings |
| `RealityCheck/Views/CardFormView.swift` | Replace hardcoded strings |
| `RealityCheck/Views/SettingsView.swift` | Replace hardcoded strings |
| `RealityCheck/Core/Utils/NotificationService.swift` | Replace hardcoded strings |
| `RealityCheckWidget/Core/Utils/NotificationService.swift` | Mirror changes (duplicated target file) |
| `RealityCheck.xcodeproj` | Add EN + VI localization |

## Language Resolution

```
System language = vi  →  Vietnamese
System language = en  →  English
System language = other  →  English (development language fallback)
```

Per-App Language override: iOS 16+ exposes this automatically in iOS Settings. No in-app UI required.

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

### NotificationService

| Key | EN | VI |
|-----|----|----|
| `notification.title` | Reality Check | Reality Check |
| `notification.body` | Your pinned card: %@ | Thẻ đã ghim: %@ |

## Implementation Notes

### SwiftUI Text (automatic)
```swift
// String literals in Text() auto-resolve from Localizable.xcstrings
Text("card.list.section.pinned")
```

### Non-Text contexts (navigationTitle, GlassField placeholders)
```swift
.navigationTitle(String(localized: "settings.title"))
GlassField(String(localized: "card.form.field.title"), text: $vm.title)
```

### String interpolation
```swift
// xcstrings entry key: "card.form.countdown.remaining %@"
Text("card.form.countdown.remaining \(viewModel.previewDisplayValue)")
```

### NotificationService (no SwiftUI)
```swift
content.title = String(localized: "notification.title")
content.body = String(localized: "notification.body \(card.title)")
```

### Widget target
Widget has a separate `Localizable.xcstrings`. It only shows user-entered card data so has minimal localizable strings (primarily empty-state placeholders if any).

### Duplicated files
`NotificationService.swift` is physically duplicated into `RealityCheckWidget/`. Changes must be mirrored to both copies.

## Out of Scope

- RTL language support
- More than 2 languages
- In-app language picker UI (iOS Per-App Language handles this natively)
