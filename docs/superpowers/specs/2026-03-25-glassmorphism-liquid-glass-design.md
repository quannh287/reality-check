# Reality Check — Aurora Liquid Glass Redesign

**Date:** 2026-03-25
**Status:** Approved
**Approach:** GlassKit component library (A) + Full view rewrite (C)
**Color theme:** Aurora (xanh cực quang)

---

## 1. Overview

Redesign toàn bộ UI của app Reality Check theo ngôn ngữ **Liquid Glass** (iOS 26 / macOS 26) với màu nền Aurora. Logic business (FormulaEngine, SwiftData models, NotificationService) giữ nguyên hoàn toàn — chỉ thay UI layer.

**Điều không thay đổi:**
- `Models/` — RealityCard, FormulaEngine
- `Services/` — NotificationService
- `Shared/` — AppGroupContainer
- `RealityCheckWidget/` — widget logic
- `Tests/` — toàn bộ test suite

---

## 2. Navigation Structure

```
App Root (AuroraBackground)
├── CardListView (root)
│   ├── tap ＋ → CardFormView (create, sheet)
│   ├── tap card → CardFormView (edit, push)
│   └── tap ⚙ → SettingsView (push)
```

**Thay đổi so với hiện tại:**
- Xoá `NavigationLink(destination: SettingsView())` khỏi toolbar, thay bằng `navigationDestination`
- CardFormView dùng cho cả create lẫn edit (đã có sẵn, giữ nguyên pattern)
- Swipe leading: Pin · Swipe trailing: Delete (giữ nguyên)

---

## 3. Color System

### Background
```swift
// AuroraBackground gradient
LinearGradient(colors: [Color(hex:"#060d1b"), Color(hex:"#0d1b2a"), Color(hex:"#071a0f")],
               startPoint: .topLeading, endPoint: .bottomTrailing)

// 3 aurora orbs (radial, animated)
orb1: rgba(0,245,160, 0.14)  — top-left,   8s drift
orb2: rgba(0,180,255, 0.12)  — top-right, 10s drift
orb3: rgba(90,60,255, 0.10)  — bottom-center, 12s drift
```

### Accent colors — theo formula type
| Context | Color | Hex |
|---|---|---|
| Pinned / Manual | Đỏ cam | `#ff6b6b` |
| Countdown | Aurora xanh lá | `#00f5a0` |
| Divide A÷B | Teal | `#64dfdf` |
| Count A/B | Tím | `#c77dff` |
| Subtract A−B | Vàng | `#ffd93d` |

### Text
| Role | Alpha |
|---|---|
| Primary | white 100% |
| Secondary | white 60% |
| Tertiary | white 30% |
| Placeholder | white 25% |

---

## 4. GlassKit — Component Library

### 4.1 File structure
```
RealityCheck/GlassKit/
├── AuroraBackground.swift      — root background + animated orbs
├── GlassModifiers.swift        — ViewModifier: .glassCard(), .glassField(), .glassButton()
├── GlassCard.swift             — card component (pinned & unpinned variants)
├── GlassField.swift            — text input replacement for TextField
├── GlassToggle.swift           — toggle replacement
├── GlassButton.swift           — button (.primary aurora / .secondary glass)
└── FormulaChip.swift           — 4-button formula type selector grid
```

### 4.2 GlassModifiers — shared visual recipe

```swift
// Liquid Glass surface recipe
// backdrop-filter: blur(28px) saturate(180%)
// border: specular top > left > right > bottom
// box-shadow: inset highlight top + inset shadow bottom + drop shadow

struct GlassModifier: ViewModifier {
    var accent: Color = .white
    var opacity: Double = 0.17

    func body(content: Content) -> some View {
        content
            .background(glassBackground)
            .overlay(specularBorder)
            .shadow(color: .black.opacity(0.35), radius: 14, y: 8)
    }

    private var glassBackground: some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .fill(.ultraThinMaterial)
            .overlay(
                LinearGradient(
                    colors: [accent.opacity(opacity * 1.5), accent.opacity(opacity * 0.4), accent.opacity(opacity)],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                )
            )
    }

    private var specularBorder: some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .strokeBorder(
                LinearGradient(
                    colors: [.white.opacity(0.42), .white.opacity(0.18), .white.opacity(0.12), .white.opacity(0.08)],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                ),
                lineWidth: 1
            )
    }
}
```

### 4.3 GlassCard

**Pinned variant** (accent = red, với progress bar):
```swift
GlassCard(card: card, style: .pinned)
// - accent màu đỏ #ff6b6b
// - hiển thị title, value lớn, context line
// - LinearProgressView ở dưới (chỉ cho formula type)
// - badge "formula" / "manual" góc phải
```

**Unpinned variant**:
```swift
GlassCard(card: card, style: .unpinned)
// - accent màu theo formula type
// - compact: title nhỏ + value + chevron
// - không có progress bar
```

### 4.4 GlassField
```swift
GlassField("Tiêu đề", text: $title)
// Thay thế TextField
// background: white 6.5% + specular border + inset highlight
// padding: 10px 12px
```

### 4.5 GlassToggle
```swift
GlassToggle(isOn: $notificationEnabled)
// ON: accent aurora #00f5a0
// OFF: white 8%
// thumb: white circle với drop shadow
```

### 4.6 GlassButton
```swift
GlassButton("Lưu", style: .primary) { save() }
GlassButton("Huỷ", style: .secondary) { dismiss() }
// primary: aurora xanh gradient + aurora glow
// secondary: white glass
```

### 4.7 FormulaChip
```swift
FormulaChip(selected: $formula)
// 2x2 grid: Chia / Đếm / Trừ / Countdown
// selected: accent màu theo type + specular highlight
// unselected: white 4% flat
```

---

## 5. View Specifications

### 5.1 AuroraBackground (root wrapper)

```swift
// RealityCheckApp.swift
CardListView()
    .background(AuroraBackground())
    .preferredColorScheme(.dark)
```

Orb animation:
```swift
@State var phase1: Bool = false  // 8s
@State var phase2: Bool = false  // 10s
@State var phase3: Bool = false  // 12s

// Mỗi orb: offset + scale animation, repeatForever(autoreverses: true)
```

### 5.2 CardListView

**Layout:**
- `NavigationStack` với `navigationTitle("Reality Check")`
- Toolbar: trailing = `[SettingsButton, PlusButton]`
- Body: `ScrollView` + `VStack(spacing: 10)` — **không dùng `List`**

**Pinned section:**
```
if let pinned = pinnedCard {
    SectionLabel("📍 Widget hiện tại")
    GlassCard(card: pinned, style: .pinned)
        .transition(.opacity.combined(with: .scale(0.97)))
}
```

**Unpinned section:**
```
SectionLabel("Các card khác")  // ẩn nếu chỉ có pinned
ForEach(unpinnedCards) { card in
    GlassCard(card: card, style: .unpinned)
        .swipeActions(edge: .leading)  { PinButton }
        .swipeActions(edge: .trailing) { DeleteButton }
}
.animation(.spring(duration: 0.4), value: unpinnedCards)
```

**Empty state:**
```
ContentUnavailableView với GlassButton("＋ Tạo card đầu tiên")
```

**Card stagger animation:** mỗi card delay `index * 0.06s` khi list appear.

### 5.3 CardFormView

**Layout:** `NavigationStack` push/sheet — `HStack` 2 cột:
- Trái (flex 1): form fields
- Phải (fixed 180px): live widget preview + card info panel

**Form fields (thay Form/Section bằng VStack + GlassField):**

```
GlassField("Tiêu đề", text: $title)

// Type toggle (Manual / Formula)
SegmentedGlassPicker(selection: $type)

// Conditional:
if type == .manual {
    GlassField("Giá trị", text: $value, keyboardType: .decimalPad)
} else {
    FormulaChip(selected: $formula)

    // Conditional inputs by formula:
    switch formula {
    case .countdown:
        GlassDatePicker("Ngày đích", selection: $targetDate)
    case .divide, .count, .subtract:
        InputABRow(labelA: $inputALabel, valueA: $inputA,
                   labelB: $inputBLabel, valueB: $inputB)
    }
}

GlassField("Đơn vị", text: $unit)
GlassField("Context line", text: $contextLine)

// Actions
HStack {
    GlassPinButton(isPinned: card?.isPinned ?? false)
    GlassDeleteButton()  // chỉ hiện khi isEditing
}
```

**Right panel — live preview:**
```swift
WidgetPreviewView(displayValue: previewDisplayValue, unit: unit, contextLine: contextLine)
    .animation(.spring(response: 0.35, dampingFraction: 0.6), value: previewDisplayValue)

// Live badge (green dot + "Live")
// Card summary panel (GlassCard nhỏ)
```

**Widget preview accent color** đổi theo formula type:
- manual → `.red`
- countdown → `.aurora`
- divide → `.teal`
- count → `.purple`
- subtract → `.yellow`

**Toolbar:** Back button "‹ Reality Check" | title | GlassButton("Lưu", .primary)

### 5.4 SettingsView

**Layout:** `NavigationStack` push — `ScrollView` + `VStack(spacing: 14)`

**Thông báo section:**
```
SectionLabel("Thông báo hàng ngày")

GlassRow {
    VStack(alignment: .leading) {
        Text("Bật thông báo")
        Text("Nhắc nhở Reality Card mỗi ngày").caption
    }
    GlassToggle(isOn: $notificationEnabled)
}
.cornerRadius(topLeading: 14, topTrailing: 14, bottomLeading: 5, bottomTrailing: 5)

GlassRow {
    VStack(alignment: .leading) {
        Text("Thời gian nhắc")
        Text("Mỗi ngày vào lúc").caption
    }
    GlassTimePicker(hour: $notificationHour, minute: $notificationMinute)
    // Large digit display: "08 : 00" trong glass panel
}
.opacity(notificationEnabled ? 1 : 0.4)
.disabled(!notificationEnabled)
.cornerRadius(topLeading: 5, topTrailing: 5, bottomLeading: 14, bottomTrailing: 14)
```

**Widget section:**
```
SectionLabel("Widget")
GlassRow { "Đang hiển thị" | pinnedCard?.title ?? "--" (red) }
GlassRow { "Reload widget" | "Làm mới ↺" (teal) }
```

**Status badge:**
```swift
if notificationEnabled {
    AuroraStatusBadge("Đã lên lịch · Mỗi ngày HH:MM")  // green dot
} else {
    DisabledBadge("Thông báo đã tắt")
}
```

### 5.5 WidgetPreviewView (cập nhật)

```swift
struct WidgetPreviewView: View {
    let displayValue: String
    let unit: String
    let contextLine: String
    var accentColor: Color = .red  // NEW: đổi theo formula type

    var body: some View {
        VStack(spacing: 3) {
            Text(displayValue)
                .font(.system(size: 36, weight: .heavy))
                .foregroundStyle(accentColor)
            Text(unit.uppercased())
                .font(.system(size: 11, weight: .medium))
                .tracking(1)
                .foregroundStyle(.secondary)
            Text(contextLine)
                .font(.system(size: 10))
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 12)
        }
        .frame(width: 155, height: 155)
        .background(glassWidgetBackground(accent: accentColor))
        // Aurora orb overlay nhỏ
        .overlay(orbOverlay)
        // Shimmer animation mỗi 3s
        .overlay(shimmerView)
    }
}
```

---

## 6. Animations

| Animation | Trigger | Spec |
|---|---|---|
| Aurora orb drift | App launch, loop | `easeInOut`, 8/10/12s, `repeatForever(autoreverses: true)` |
| Card stagger appear | List onAppear | `index * 0.06s` delay, `.spring(duration: 0.4)` |
| Widget value pop | `displayValue` change | `.spring(response: 0.35, dampingFraction: 0.6)`, scale 0.7→1 |
| Specular shimmer | 3s interval timer | `left: -55% → 110%`, `.linear(duration: 1.2)` |
| Navigation zoom | Card tap (iOS 18+) | `.navigationTransition(.zoom(sourceID: card.id, in: namespace))` |
| Toggle | isOn change | Built-in SwiftUI + custom glass pill |
| Pin/unpin | Pinned change | `.transition(.opacity.combined(with: .scale(0.97)))` |

---

## 7. Widget (WidgetKit)

### Small (155×155)
- Centered: value lớn + unit + context line
- Aurora orb nhỏ overlay (static, không animate trong widget)
- Shimmer stroke 1 lần khi timeline refresh

### Medium (329×155)
- Left pane: value + unit (border right)
- Right pane: title + context + LinearProgressView (cho formula)
- Chỉ hiển thị nếu card isPinned

**Accent color trong widget:** đọc từ `RealityCard.formula` → map sang Color tương ứng.

---

## 8. Implementation Plan Summary

**Phase 1 — GlassKit foundation**
1. Tạo `GlassKit/` folder
2. `AuroraBackground.swift` — background + orb animation
3. `GlassModifiers.swift` — shared ViewModifier recipe
4. `GlassCard.swift` — pinned + unpinned
5. `GlassField.swift`, `GlassToggle.swift`, `GlassButton.swift`
6. `FormulaChip.swift`

**Phase 2 — View rewrites**
7. `WidgetPreviewView` — thêm `accentColor` param
8. `CardListView` — thay List bằng ScrollView + GlassCard
9. `CardFormView` — 2-column layout + GlassField + FormulaChip
10. `SettingsView` — GlassRow + GlassToggle + GlassTimePicker

**Phase 3 — Widget + Polish**
11. Update `RealityCheckWidget` để dùng glass style + accent color
12. Stagger animations + shimmer + value pop
13. Navigation zoom transition (iOS 18+)

**Không cần thay đổi:** Models, Services, Shared, Tests.

---

## 9. Wireframe References

Wireframes lưu tại:
```
.superpowers/brainstorm/67242-1774366742/
├── color-mood.html                  — 4 color mood options
├── layout-wireframe-v2.html         — iPhone portrait/landscape + macOS
├── liquid-glass-wireframe.html      — Liquid Glass cho 3 layouts
├── all-screens-v2.html             — Navigation flow + all screens
├── design-section1-system.html     — Color system + GlassKit components
├── design-section2-screens.html    — All screens với Aurora applied
└── design-section3-widget-anim.html — Widget sizes + animations
```
