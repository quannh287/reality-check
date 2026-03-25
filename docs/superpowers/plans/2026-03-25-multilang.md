# Multi-Language Support (EN / VI) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add English and Vietnamese localization to Reality Check using String Catalogs (`.xcstrings`), with automatic system-language detection and iOS 16+ Per-App Language override.

**Architecture:** One `Localizable.xcstrings` per target (main app + widget). All UI strings replaced with dot-notation localization keys. Development language is English; Vietnamese is a translation. No in-app language picker — iOS handles it natively.

**Tech Stack:** Xcode 15+ String Catalog (`.xcstrings`), SwiftUI `Text()` auto-localization, `String(localized:)`, `String(format:)`

---

## File Map

| File | Change |
|------|--------|
| `RealityCheck/Localizable.xcstrings` | **Create** — ~47 keys, EN + VI |
| `RealityCheckWidget/Localizable.xcstrings` | **Create** — 2 widget-specific keys, EN + VI |
| `RealityCheck.xcodeproj/project.pbxproj` | **Modify** — add `vi` to knownRegions; add both xcstrings as resources |
| `RealityCheck/Views/CardListView.swift` | **Modify** — replace 8 hardcoded strings |
| `RealityCheck/Views/CardFormView.swift` | **Modify** — replace 24 hardcoded strings |
| `RealityCheck/Views/SettingsView.swift` | **Modify** — replace 12 hardcoded strings |
| `RealityCheck/Core/Utils/NotificationService.swift` | **Modify** — replace 3 hardcoded strings |
| `RealityCheckWidget/RealityCheckWidget.swift` | **Modify** — replace 1 hardcoded string + 1 description |
| `RealityCheckWidget/Core/Utils/NotificationService.swift` | **No change** — widget doesn't schedule notifications; `buildContent` only runs in main app |

---

## Key Background

- `Text("key")` auto-resolves from `Localizable.xcstrings` — no extra code needed.
- `.navigationTitle(...)` and `GlassField(placeholder, ...)` take `String` — use `String(localized: "key")`.
- Interpolated keys: `Text("key \(value)")` looks up `"key %@"` in xcstrings.
- `NotificationService` uses `UNMutableNotificationContent` (no SwiftUI) — use `String(localized:)` + `String(format:)`.
- `RealityCheckWidget/RealityCheckWidget.swift` has one hardcoded VI string: `"Mở app để tạo Reality Card đầu tiên"` (line 26 in `emptyEntry`). Widget target does NOT have a NotificationService copy.
- pbxproj key IDs for reference: main app Resources phase = `5A9076C82F7141A80026035B`, widget Resources phase = `5A9077062F7142230026035B`, main app file group = `5A9076CC2F7141A80026035B`, widget file group = `5A90770E2F7142230026035B`.

---

## Task 1: Create `RealityCheck/Localizable.xcstrings`

**Files:**
- Create: `RealityCheck/Localizable.xcstrings`

- [ ] **Step 1: Create the file with full string catalog**

Create `/path/to/worktree/RealityCheck/Localizable.xcstrings` with this exact content:

```json
{
  "sourceLanguage" : "en",
  "strings" : {
    "app.title" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "Reality Check" } },
        "vi" : { "stringUnit" : { "state" : "translated", "value" : "Reality Check" } }
      }
    },
    "card.list.section.pinned" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "Pinned" } },
        "vi" : { "stringUnit" : { "state" : "translated", "value" : "Đã ghim" } }
      }
    },
    "card.list.section.all" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "All Cards" } },
        "vi" : { "stringUnit" : { "state" : "translated", "value" : "Tất cả thẻ" } }
      }
    },
    "card.list.empty.headline" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "No Reality Cards yet" } },
        "vi" : { "stringUnit" : { "state" : "translated", "value" : "Chưa có Reality Card nào" } }
      }
    },
    "card.list.empty.subheadline" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "Create your first card to\nface reality" } },
        "vi" : { "stringUnit" : { "state" : "translated", "value" : "Tạo card đầu tiên để\nđối diện thực tế" } }
      }
    },
    "card.list.empty.cta" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "＋ Create first card" } },
        "vi" : { "stringUnit" : { "state" : "translated", "value" : "＋ Tạo card đầu tiên" } }
      }
    },
    "card.list.action.pin" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "Pin to widget" } },
        "vi" : { "stringUnit" : { "state" : "translated", "value" : "Pin lên widget" } }
      }
    },
    "card.list.action.delete" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "Delete" } },
        "vi" : { "stringUnit" : { "state" : "translated", "value" : "Xoá" } }
      }
    },
    "card.form.title.create" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "Create Card" } },
        "vi" : { "stringUnit" : { "state" : "translated", "value" : "Tạo Card" } }
      }
    },
    "card.form.title.edit" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "Edit Card" } },
        "vi" : { "stringUnit" : { "state" : "translated", "value" : "Sửa Card" } }
      }
    },
    "card.form.action.cancel" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "Cancel" } },
        "vi" : { "stringUnit" : { "state" : "translated", "value" : "Huỷ" } }
      }
    },
    "card.form.action.save" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "Save" } },
        "vi" : { "stringUnit" : { "state" : "translated", "value" : "Lưu" } }
      }
    },
    "card.form.section.info" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "Info" } },
        "vi" : { "stringUnit" : { "state" : "translated", "value" : "Thông tin" } }
      }
    },
    "card.form.field.title" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "Title" } },
        "vi" : { "stringUnit" : { "state" : "translated", "value" : "Tiêu đề" } }
      }
    },
    "card.form.type.manual" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "Manual" } },
        "vi" : { "stringUnit" : { "state" : "translated", "value" : "Manual" } }
      }
    },
    "card.form.type.formula" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "Formula" } },
        "vi" : { "stringUnit" : { "state" : "translated", "value" : "Formula" } }
      }
    },
    "card.form.section.value" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "Value" } },
        "vi" : { "stringUnit" : { "state" : "translated", "value" : "Giá trị" } }
      }
    },
    "card.form.field.value" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "Number" } },
        "vi" : { "stringUnit" : { "state" : "translated", "value" : "Số liệu" } }
      }
    },
    "card.form.section.formula" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "Formula" } },
        "vi" : { "stringUnit" : { "state" : "translated", "value" : "Công thức" } }
      }
    },
    "card.form.section.inputs" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "Inputs" } },
        "vi" : { "stringUnit" : { "state" : "translated", "value" : "Inputs" } }
      }
    },
    "card.form.section.display" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "Display" } },
        "vi" : { "stringUnit" : { "state" : "translated", "value" : "Hiển thị" } }
      }
    },
    "card.form.field.unit" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "Unit (days, months, M...)" } },
        "vi" : { "stringUnit" : { "state" : "translated", "value" : "Đơn vị (ngày, tháng, triệu...)" } }
      }
    },
    "card.form.field.context" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "Context line" } },
        "vi" : { "stringUnit" : { "state" : "translated", "value" : "Context line" } }
      }
    },
    "card.form.field.label.a" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "Name (e.g. Revenue)" } },
        "vi" : { "stringUnit" : { "state" : "translated", "value" : "Tên (VD: Doanh số)" } }
      }
    },
    "card.form.field.label.b" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "Name (e.g. Target)" } },
        "vi" : { "stringUnit" : { "state" : "translated", "value" : "Tên (VD: Mục tiêu)" } }
      }
    },
    "card.form.field.value.placeholder" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "Value" } },
        "vi" : { "stringUnit" : { "state" : "translated", "value" : "Giá trị" } }
      }
    },
    "card.form.field.target.date" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "Target date" } },
        "vi" : { "stringUnit" : { "state" : "translated", "value" : "Ngày đích" } }
      }
    },
    "card.form.countdown.remaining %@" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "→ %@ days remaining" } },
        "vi" : { "stringUnit" : { "state" : "translated", "value" : "→ %@ ngày còn lại" } }
      }
    },
    "card.form.action.pin" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "Pin to widget" } },
        "vi" : { "stringUnit" : { "state" : "translated", "value" : "Pin lên widget" } }
      }
    },
    "card.form.action.unpin" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "Unpin" } },
        "vi" : { "stringUnit" : { "state" : "translated", "value" : "Bỏ pin" } }
      }
    },
    "card.form.preview.label" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "Live preview" } },
        "vi" : { "stringUnit" : { "state" : "translated", "value" : "Live preview" } }
      }
    },
    "card.form.preview.section" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "Preview" } },
        "vi" : { "stringUnit" : { "state" : "translated", "value" : "Preview" } }
      }
    },
    "settings.title" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "Settings" } },
        "vi" : { "stringUnit" : { "state" : "translated", "value" : "Cài đặt" } }
      }
    },
    "settings.notification.section" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "Daily Notification" } },
        "vi" : { "stringUnit" : { "state" : "translated", "value" : "Thông báo hàng ngày" } }
      }
    },
    "settings.notification.toggle.title" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "Enable notifications" } },
        "vi" : { "stringUnit" : { "state" : "translated", "value" : "Bật thông báo" } }
      }
    },
    "settings.notification.toggle.subtitle" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "Daily Reality Card reminder" } },
        "vi" : { "stringUnit" : { "state" : "translated", "value" : "Nhắc nhở Reality Card mỗi ngày" } }
      }
    },
    "settings.notification.time.title" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "Reminder time" } },
        "vi" : { "stringUnit" : { "state" : "translated", "value" : "Thời gian nhắc" } }
      }
    },
    "settings.notification.time.subtitle" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "Every day at" } },
        "vi" : { "stringUnit" : { "state" : "translated", "value" : "Mỗi ngày vào lúc" } }
      }
    },
    "settings.notification.status.on %@" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "Scheduled · Every day at %@" } },
        "vi" : { "stringUnit" : { "state" : "translated", "value" : "Đã lên lịch · Mỗi ngày %@" } }
      }
    },
    "settings.notification.status.off" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "Notifications disabled" } },
        "vi" : { "stringUnit" : { "state" : "translated", "value" : "Thông báo đã tắt" } }
      }
    },
    "settings.widget.section" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "Widget" } },
        "vi" : { "stringUnit" : { "state" : "translated", "value" : "Widget" } }
      }
    },
    "settings.widget.showing" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "Showing" } },
        "vi" : { "stringUnit" : { "state" : "translated", "value" : "Đang hiển thị" } }
      }
    },
    "settings.widget.refresh" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "Refresh widget" } },
        "vi" : { "stringUnit" : { "state" : "translated", "value" : "Làm mới widget" } }
      }
    },
    "settings.widget.refresh.action" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "Refresh ↺" } },
        "vi" : { "stringUnit" : { "state" : "translated", "value" : "Làm mới ↺" } }
      }
    },
    "notification.title" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "Reality Check" } },
        "vi" : { "stringUnit" : { "state" : "translated", "value" : "Reality Check" } }
      }
    },
    "notification.body.format" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "%1$@ %2$@ — %3$@" } },
        "vi" : { "stringUnit" : { "state" : "translated", "value" : "%1$@ %2$@ — %3$@" } }
      }
    },
    "notification.body.empty" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "Open app to create your first Reality Card" } },
        "vi" : { "stringUnit" : { "state" : "translated", "value" : "Mở app để tạo Reality Card đầu tiên" } }
      }
    }
  },
  "version" : "1.0"
}
```

- [ ] **Step 2: Commit**

```bash
git add RealityCheck/Localizable.xcstrings
git commit -m "feat: add Localizable.xcstrings for main app (EN/VI)"
```

---

## Task 2: Add xcstrings files to Xcode project + enable `vi` region

**Files:**
- Modify: `RealityCheck.xcodeproj/project.pbxproj`

This task edits `project.pbxproj` to:
1. Add `vi` to `knownRegions`
2. Register both xcstrings files as PBXFileReferences
3. Add them to their respective file groups
4. Add them to their respective Resources build phases

- [ ] **Step 1: Generate UUIDs**

Run to get 4 unique 24-char hex IDs (one per operation):

```bash
for i in 1 2 3 4; do python3 -c "import uuid; print(uuid.uuid4().hex[:24].upper())"; done
```

Label them:
- UUID_A = PBXFileReference for main app xcstrings
- UUID_B = PBXBuildFile for main app xcstrings
- UUID_C = PBXFileReference for widget xcstrings
- UUID_D = PBXBuildFile for widget xcstrings

- [ ] **Step 2: Add `vi` to knownRegions**

First, read `project.pbxproj` around line 295 to confirm the exact whitespace and ordering of `knownRegions`. Then add `vi,` as a new line inside the list, before `Base,`. The result must look like:

```
knownRegions = (
    en,
    vi,
    Base,
);
```

Use the Edit tool with the exact characters you observed in Step 1 as `old_string` to ensure a precise match.

- [ ] **Step 3: Add PBXFileReference entries**

Find the `/* Begin PBXFileReference section */` block and add these two entries inside it (before the `/* End PBXFileReference section */` line):

```
		[UUID_A] /* Localizable.xcstrings */ = {isa = PBXFileReference; lastKnownFileType = text.json.xcstrings; path = Localizable.xcstrings; sourceTree = "<group>"; };
		[UUID_C] /* Localizable.xcstrings */ = {isa = PBXFileReference; lastKnownFileType = text.json.xcstrings; path = Localizable.xcstrings; sourceTree = "<group>"; };
```

- [ ] **Step 4: Add PBXBuildFile entries**

Find the `/* Begin PBXBuildFile section */` block and add these two entries inside it:

```
		[UUID_B] /* Localizable.xcstrings in Resources */ = {isa = PBXBuildFile; fileRef = [UUID_A] /* Localizable.xcstrings */; };
		[UUID_D] /* Localizable.xcstrings in Resources */ = {isa = PBXBuildFile; fileRef = [UUID_C] /* Localizable.xcstrings */; };
```

- [ ] **Step 5: Add files to their groups**

Find the main app group (ID `5A9076CC2F7141A80026035B`):
```
5A9076CC2F7141A80026035B /* RealityCheck */ = {
    isa = PBXGroup;
    children = (
        ...
    );
```
Add `[UUID_A] /* Localizable.xcstrings */,` inside its `children` list.

Find the widget group (ID `5A90770E2F7142230026035B`):
```
5A90770E2F7142230026035B /* RealityCheckWidget */ = {
```
Add `[UUID_C] /* Localizable.xcstrings */,` inside its `children` list.

- [ ] **Step 6: Add files to Resources build phases**

Main app Resources phase (ID `5A9076C82F7141A80026035B`):
```
5A9076C82F7141A80026035B /* Resources */ = {
    isa = PBXResourcesBuildPhase;
    buildActionMask = 2147483647;
    files = (
    );
```
Add `[UUID_B] /* Localizable.xcstrings in Resources */,` inside its `files` list.

Widget Resources phase (ID `5A9077062F7142230026035B`):
```
5A9077062F7142230026035B /* Resources */ = {
    isa = PBXResourcesBuildPhase;
    buildActionMask = 2147483647;
    files = (
    );
```
Add `[UUID_D] /* Localizable.xcstrings in Resources */,` inside its `files` list.

- [ ] **Step 7: Verify project parses**

```bash
cd /Users/quannh2871/Development/IOS/reality-check/.claude/worktrees/feature+multilang
plutil -lint RealityCheck.xcodeproj/project.pbxproj
```

Expected output: `RealityCheck.xcodeproj/project.pbxproj: OK`

- [ ] **Step 8: Commit**

```bash
git add RealityCheck.xcodeproj/project.pbxproj
git commit -m "chore: add xcstrings to project, enable vi localization region"
```

---

## Task 3: Localize `CardListView.swift`

**Files:**
- Modify: `RealityCheck/Views/CardListView.swift`

- [ ] **Step 1: Apply all string replacements**

Replace the following in `CardListView.swift`:

| Old | New |
|-----|-----|
| `.navigationTitle("Reality Check")` | `.navigationTitle(String(localized: "app.title"))` |
| `SectionLabel("Đã ghim")` | `SectionLabel(String(localized: "card.list.section.pinned"))` |
| `SectionLabel("Tất cả thẻ")` | `SectionLabel(String(localized: "card.list.section.all"))` |
| `Label("Pin lên widget", systemImage: "pin")` | `Label(String(localized: "card.list.action.pin"), systemImage: "pin")` |
| `Label("Xoá", systemImage: "trash")` | `Label(String(localized: "card.list.action.delete"), systemImage: "trash")` |
| `Text("Chưa có Reality Card nào")` | `Text("card.list.empty.headline")` |
| `Text("Tạo card đầu tiên để\nđối diện thực tế")` | `Text("card.list.empty.subheadline")` |
| `GlassButton("＋ Tạo card đầu tiên", style: .primary)` | `GlassButton(String(localized: "card.list.empty.cta"), style: .primary)` |

- [ ] **Step 2: Build to verify**

```bash
xcodebuild build -scheme RealityCheck -project RealityCheck.xcodeproj -destination 'platform=iOS Simulator,name=iPhone 17 Pro' 2>&1 | grep -E "error:|BUILD"
```

Expected: `BUILD SUCCEEDED` with no errors.

- [ ] **Step 3: Commit**

```bash
git add RealityCheck/Views/CardListView.swift
git commit -m "feat: localize CardListView strings (EN/VI)"
```

---

## Task 4: Localize `CardFormView.swift`

**Files:**
- Modify: `RealityCheck/Views/CardFormView.swift`

- [ ] **Step 1: Apply all string replacements**

Replace the following in `CardFormView.swift`:

| Old | New |
|-----|-----|
| `.navigationTitle(viewModel.isEditing ? "Sửa Card" : "Tạo Card")` | `.navigationTitle(viewModel.isEditing ? String(localized: "card.form.title.edit") : String(localized: "card.form.title.create"))` |
| `Button("Huỷ")` | `Button(String(localized: "card.form.action.cancel"))` |
| `Button("Lưu")` | `Button(String(localized: "card.form.action.save"))` |
| `SectionLabel("Thông tin")` | `SectionLabel(String(localized: "card.form.section.info"))` |
| `GlassField("Tiêu đề", text: $vm.title)` | `GlassField(String(localized: "card.form.field.title"), text: $vm.title)` |
| `Text(t == .manual ? "Manual" : "Formula")` | `Text(t == .manual ? String(localized: "card.form.type.manual") : String(localized: "card.form.type.formula"))` |
| `SectionLabel("Giá trị")` | `SectionLabel(String(localized: "card.form.section.value"))` |
| `GlassField("Số liệu", text: $vm.value, keyboardType: .decimalPad)` | `GlassField(String(localized: "card.form.field.value"), text: $vm.value, keyboardType: .decimalPad)` |
| `SectionLabel("Công thức")` | `SectionLabel(String(localized: "card.form.section.formula"))` |
| `SectionLabel("Inputs")` | `SectionLabel(String(localized: "card.form.section.inputs"))` |
| `SectionLabel("Hiển thị")` | `SectionLabel(String(localized: "card.form.section.display"))` |
| `GlassField("Đơn vị (ngày, tháng, triệu...)", text: $vm.unit)` | `GlassField(String(localized: "card.form.field.unit"), text: $vm.unit)` |
| `GlassField("Context line", text: $vm.contextLine)` | `GlassField(String(localized: "card.form.field.context"), text: $vm.contextLine)` |
| `DatePicker("Ngày đích", selection: $vm.targetDate, displayedComponents: .date)` | `DatePicker(String(localized: "card.form.field.target.date"), selection: $vm.targetDate, displayedComponents: .date)` |
| `Text("→ \(viewModel.previewDisplayValue) ngày còn lại")` | `Text("card.form.countdown.remaining \(viewModel.previewDisplayValue)")` |
| `GlassField("Tên (VD: Doanh số)", text: $vm.inputALabel)` | `GlassField(String(localized: "card.form.field.label.a"), text: $vm.inputALabel)` |
| `GlassField("Tên (VD: Mục tiêu)", text: $vm.inputBLabel)` | `GlassField(String(localized: "card.form.field.label.b"), text: $vm.inputBLabel)` |
| `GlassField("Giá trị", text: $vm.inputA, keyboardType: .decimalPad)` (first occurrence, inputA) | `GlassField(String(localized: "card.form.field.value.placeholder"), text: $vm.inputA, keyboardType: .decimalPad)` |
| `GlassField("Giá trị", text: $vm.inputB, keyboardType: .decimalPad)` (second occurrence, inputB) | `GlassField(String(localized: "card.form.field.value.placeholder"), text: $vm.inputB, keyboardType: .decimalPad)` |
| `Label(isPinned ? "Bỏ pin" : "Pin lên widget", systemImage: isPinned ? "pin.slash" : "pin")` | `Label(isPinned ? String(localized: "card.form.action.unpin") : String(localized: "card.form.action.pin"), systemImage: isPinned ? "pin.slash" : "pin")` |
| `SectionLabel("Preview")` | `SectionLabel(String(localized: "card.form.preview.section"))` |
| `Text("Live preview")` | `Text("card.form.preview.label")` |

- [ ] **Step 2: Build to verify**

```bash
xcodebuild build -scheme RealityCheck -project RealityCheck.xcodeproj -destination 'platform=iOS Simulator,name=iPhone 17 Pro' 2>&1 | grep -E "error:|BUILD"
```

Expected: `BUILD SUCCEEDED`

- [ ] **Step 3: Commit**

```bash
git add RealityCheck/Views/CardFormView.swift
git commit -m "feat: localize CardFormView strings (EN/VI)"
```

---

## Task 5: Localize `SettingsView.swift`

**Files:**
- Modify: `RealityCheck/Views/SettingsView.swift`

- [ ] **Step 1: Apply all string replacements**

Replace the following in `SettingsView.swift`:

| Old | New |
|-----|-----|
| `.navigationTitle("Cài đặt")` | `.navigationTitle(String(localized: "settings.title"))` |
| `SectionLabel("Thông báo hàng ngày")` | `SectionLabel(String(localized: "settings.notification.section"))` |
| `Text("Bật thông báo")` | `Text("settings.notification.toggle.title")` |
| `Text("Nhắc nhở Reality Card mỗi ngày")` | `Text("settings.notification.toggle.subtitle")` |
| `Text("Thời gian nhắc")` | `Text("settings.notification.time.title")` |
| `Text("Mỗi ngày vào lúc")` | `Text("settings.notification.time.subtitle")` |
| `Text("Đã lên lịch · Mỗi ngày \(timeString)")` | `Text("settings.notification.status.on \(timeString)")` |
| `Text("Thông báo đã tắt")` | `Text("settings.notification.status.off")` |
| `SectionLabel("Widget")` | `SectionLabel(String(localized: "settings.widget.section"))` |
| `Text("Đang hiển thị")` | `Text("settings.widget.showing")` |
| `Text("Làm mới widget")` | `Text("settings.widget.refresh")` |
| `Text("Làm mới ↺")` | `Text("settings.widget.refresh.action")` |

- [ ] **Step 2: Build to verify**

```bash
xcodebuild build -scheme RealityCheck -project RealityCheck.xcodeproj -destination 'platform=iOS Simulator,name=iPhone 17 Pro' 2>&1 | grep -E "error:|BUILD"
```

Expected: `BUILD SUCCEEDED`

- [ ] **Step 3: Commit**

```bash
git add RealityCheck/Views/SettingsView.swift
git commit -m "feat: localize SettingsView strings (EN/VI)"
```

---

## Task 6: Localize `NotificationService.swift`

**Files:**
- Modify: `RealityCheck/Core/Utils/NotificationService.swift`

- [ ] **Step 1: Replace hardcoded strings**

The current `buildContent(for:)` method body:
```swift
content.title = "Reality Check"
if let card {
    let value = FormulaEngine.displayValue(for: card)
    content.body = "\(value) \(card.unit) — \(card.contextLine)"
} else {
    content.body = "Mở app để tạo Reality Card đầu tiên"
}
```

Replace with:
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

- [ ] **Step 2: Build to verify**

```bash
xcodebuild build -scheme RealityCheck -project RealityCheck.xcodeproj -destination 'platform=iOS Simulator,name=iPhone 17 Pro' 2>&1 | grep -E "error:|BUILD"
```

Expected: `BUILD SUCCEEDED`

- [ ] **Step 3: Run existing tests**

```bash
xcodebuild test -scheme RealityCheck -project RealityCheck.xcodeproj -destination 'platform=iOS Simulator,name=iPhone 17 Pro' 2>&1 | grep -E "error:|Test Suite|passed|failed"
```

Expected: All existing FormulaEngine tests pass.

- [ ] **Step 4: Commit**

```bash
git add RealityCheck/Core/Utils/NotificationService.swift
git commit -m "feat: localize NotificationService strings (EN/VI)"
```

---

## Task 7: Create `RealityCheckWidget/Localizable.xcstrings` + localize widget

**Files:**
- Create: `RealityCheckWidget/Localizable.xcstrings`
- Modify: `RealityCheckWidget/RealityCheckWidget.swift`

The widget has two hardcoded strings to localize:
1. `"Mở app để tạo Reality Card đầu tiên"` — empty state context line (line 26 in `emptyEntry`)
2. `"Hiện Reality Card trên home screen"` — widget gallery description (`.description(...)`)

- [ ] **Step 1: Create widget xcstrings**

Create `RealityCheckWidget/Localizable.xcstrings`:

```json
{
  "sourceLanguage" : "en",
  "strings" : {
    "widget.empty.context" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "Open app to create your first Reality Card" } },
        "vi" : { "stringUnit" : { "state" : "translated", "value" : "Mở app để tạo Reality Card đầu tiên" } }
      }
    },
    "widget.description" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "Show Reality Card on home screen" } },
        "vi" : { "stringUnit" : { "state" : "translated", "value" : "Hiện Reality Card trên home screen" } }
      }
    }
  },
  "version" : "1.0"
}
```

- [ ] **Step 2: Localize widget strings**

In `RealityCheckWidget/RealityCheckWidget.swift`:

Replace (line ~26 in `emptyEntry`):
```swift
contextLine: "Mở app để tạo Reality Card đầu tiên",
```
With:
```swift
contextLine: String(localized: "widget.empty.context"),
```

Replace (in widget bundle `.description`):
```swift
.description("Hiện Reality Card trên home screen")
```
With:
```swift
.description("widget.description")
```

Note: Pass the key as a string literal — `WidgetConfiguration.description()` accepts `LocalizedStringKey`, so a bare string literal auto-localizes via the widget's `Localizable.xcstrings`. Do NOT use `String(localized:)` here as that returns a plain `String` and bypasses WidgetKit's localization path.

- [ ] **Step 3: Build widget to verify**

```bash
xcodebuild build -scheme RealityCheckWidget -project RealityCheck.xcodeproj -destination 'platform=iOS Simulator,name=iPhone 17 Pro' 2>&1 | grep -E "error:|BUILD"
```

Expected: `BUILD SUCCEEDED`

- [ ] **Step 4: Commit**

```bash
git add RealityCheckWidget/Localizable.xcstrings RealityCheckWidget/RealityCheckWidget.swift
git commit -m "feat: add widget xcstrings and localize widget strings (EN/VI)"
```

---

## Task 8: Final verification

- [ ] **Step 1: Build main app**

```bash
xcodebuild build -scheme RealityCheck -project RealityCheck.xcodeproj -destination 'platform=iOS Simulator,name=iPhone 17 Pro' 2>&1 | grep -E "error:|BUILD"
```

Expected: `BUILD SUCCEEDED`

- [ ] **Step 2: Build widget**

```bash
xcodebuild build -scheme RealityCheckWidget -project RealityCheck.xcodeproj -destination 'platform=iOS Simulator,name=iPhone 17 Pro' 2>&1 | grep -E "error:|BUILD"
```

Expected: `BUILD SUCCEEDED`

- [ ] **Step 3: Run all tests**

```bash
xcodebuild test -scheme RealityCheck -project RealityCheck.xcodeproj -destination 'platform=iOS Simulator,name=iPhone 17 Pro' 2>&1 | grep -E "Test Suite|passed|failed"
```

Expected: All tests pass (FormulaEngine tests unaffected by localization changes).

- [ ] **Step 4: Final commit**

```bash
git add -A
git commit -m "feat: complete EN/VI localization for Reality Check"
```
