# Aurora Liquid Glass Redesign — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Redesign toàn bộ UI của Reality Check theo Aurora Liquid Glass (iOS 26 style) — xây GlassKit component library và rewrite 5 Views, không đụng Models/Services/Tests.

**Architecture:** Phase 1 xây GlassKit (7 files độc lập, UI-only). Phase 2 rewrite Views dùng GlassKit components thay thế List/Form/TextField. Phase 3 update Widget + polish animations. Logic business giữ nguyên 100%.

**Tech Stack:** SwiftUI, SwiftData, WidgetKit, iOS 17+ (zoom transition requires iOS 18+, graceful fallback)

**Spec:** `docs/superpowers/specs/2026-03-25-glassmorphism-liquid-glass-design.md`

---

## File Map

### Files mới (tạo)
```
RealityCheck/GlassKit/
├── AuroraBackground.swift
├── GlassModifiers.swift
├── GlassCard.swift
├── GlassField.swift
├── GlassToggle.swift
├── GlassButton.swift
└── FormulaChip.swift
```

### Files sửa
```
RealityCheck/RealityCheckApp.swift          — thêm AuroraBackground + dark mode
RealityCheck/Views/CardListView.swift       — rewrite: ScrollView + GlassCard
RealityCheck/Views/CardRowView.swift        — deprecated, inline vào GlassCard
RealityCheck/Views/CardFormView.swift       — rewrite: 2-col + GlassField + FormulaChip
RealityCheck/Views/SettingsView.swift       — rewrite: GlassRow + GlassToggle
RealityCheck/Views/WidgetPreviewView.swift  — thêm accentColor param + glass background
RealityCheckWidget/RealityCheckWidget.swift — glass style + medium size support
```

### Files không đổi
```
RealityCheck/Models/          — RealityCard.swift, FormulaEngine.swift
RealityCheck/Services/        — NotificationService.swift
RealityCheck/Shared/          — AppGroupContainer.swift
RealityCheckTests/            — tất cả test files
RealityCheckUITests/          — tất cả UI test files
```

---

## Phase 1 — GlassKit Foundation

---

### Task 1: Color Extensions + AuroraBackground

**Files:**
- Create: `RealityCheck/GlassKit/AuroraBackground.swift`

> **Mục đích:** Cung cấp Aurora gradient background + animated orbs dùng làm root của toàn app. Cũng định nghĩa `Color` extensions và accent color mapping dùng xuyên suốt GlassKit.

- [ ] **Step 1: Tạo file AuroraBackground.swift**

```swift
// RealityCheck/GlassKit/AuroraBackground.swift
import SwiftUI

// MARK: - Color Extensions

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r = Double((int >> 16) & 0xFF) / 255
        let g = Double((int >> 8) & 0xFF) / 255
        let b = Double(int & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }

    static let auroraGreen  = Color(hex: "#00f5a0")
    static let auroraTeal   = Color(hex: "#64dfdf")
    static let auroraPurple = Color(hex: "#c77dff")
    static let auroraRed    = Color(hex: "#ff6b6b")
    static let auroraYellow = Color(hex: "#ffd93d")
}

// MARK: - Accent color per formula type

extension FormulaType {
    var accentColor: Color {
        switch self {
        case .divide:    return .auroraTeal
        case .count:     return .auroraPurple
        case .subtract:  return .auroraYellow
        case .countdown: return .auroraGreen
        }
    }
}

extension CardType {
    var accentColor: Color { .auroraRed }
}

// MARK: - AuroraBackground

struct AuroraBackground: View {
    @State private var phase1 = false
    @State private var phase2 = false
    @State private var phase3 = false

    var body: some View {
        ZStack {
            // Base gradient
            LinearGradient(
                colors: [Color(hex: "#060d1b"), Color(hex: "#0d1b2a"), Color(hex: "#071a0f")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            // Orb 1 — green, top-left, 8s
            GeometryReader { geo in
                Circle()
                    .fill(Color.auroraGreen.opacity(0.14))
                    .frame(width: geo.size.width * 0.6, height: geo.size.width * 0.6)
                    .blur(radius: 80)
                    .offset(
                        x: phase1 ? -geo.size.width * 0.05 : geo.size.width * 0.02,
                        y: phase1 ? -geo.size.height * 0.03 : geo.size.height * 0.04
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)

                // Orb 2 — blue, top-right, 10s
                Circle()
                    .fill(Color(hex: "#00b4ff").opacity(0.12))
                    .frame(width: geo.size.width * 0.5, height: geo.size.width * 0.5)
                    .blur(radius: 70)
                    .offset(
                        x: phase2 ? geo.size.width * 0.04 : -geo.size.width * 0.03,
                        y: phase2 ? -geo.size.height * 0.04 : geo.size.height * 0.02
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)

                // Orb 3 — purple, bottom-center, 12s
                Circle()
                    .fill(Color(hex: "#5a3cff").opacity(0.10))
                    .frame(width: geo.size.width * 0.55, height: geo.size.width * 0.55)
                    .blur(radius: 75)
                    .offset(
                        x: phase3 ? geo.size.width * 0.06 : -geo.size.width * 0.04,
                        y: phase3 ? geo.size.height * 0.03 : -geo.size.height * 0.02
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
            }
            .ignoresSafeArea()
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 8).repeatForever(autoreverses: true)) { phase1.toggle() }
            withAnimation(.easeInOut(duration: 10).repeatForever(autoreverses: true).delay(1)) { phase2.toggle() }
            withAnimation(.easeInOut(duration: 12).repeatForever(autoreverses: true).delay(2)) { phase3.toggle() }
        }
    }
}
```

- [ ] **Step 2: Build để kiểm tra compile**

```bash
xcodebuild build -scheme RealityCheck \
  -project RealityCheck/RealityCheck.xcodeproj \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  2>&1 | grep -E "error:|warning:|BUILD"
```
Expected: `BUILD SUCCEEDED`

- [ ] **Step 3: Commit**

```bash
git add RealityCheck/GlassKit/AuroraBackground.swift
git commit -m "feat(GlassKit): add AuroraBackground + Color extensions + accent color mapping"
```

---

### Task 2: GlassModifiers

**Files:**
- Create: `RealityCheck/GlassKit/GlassModifiers.swift`

> **Mục đích:** Shared ViewModifier recipe cho Liquid Glass surface. Tất cả GlassKit components dùng modifier này.

- [ ] **Step 1: Tạo file GlassModifiers.swift**

```swift
// RealityCheck/GlassKit/GlassModifiers.swift
import SwiftUI

// MARK: - Corner radius helpers

struct RoundedCorner: Shape {
    var radius: CGFloat
    var corners: UIRectCorner

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

// MARK: - Glass surface ViewModifier

struct GlassSurfaceModifier: ViewModifier {
    var accent: Color
    var accentOpacity: Double
    var cornerRadius: CGFloat
    var shadowRadius: CGFloat

    init(
        accent: Color = .white,
        accentOpacity: Double = 0.17,
        cornerRadius: CGFloat = 16,
        shadowRadius: CGFloat = 14
    ) {
        self.accent = accent
        self.accentOpacity = accentOpacity
        self.cornerRadius = cornerRadius
        self.shadowRadius = shadowRadius
    }

    func body(content: Content) -> some View {
        content
            .background(glassBackground)
            .overlay(specularBorder)
            .shadow(color: .black.opacity(0.35), radius: shadowRadius, y: 8)
    }

    private var glassBackground: some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .fill(.ultraThinMaterial)
            .overlay(
                LinearGradient(
                    colors: [
                        accent.opacity(accentOpacity * 1.5),
                        accent.opacity(accentOpacity * 0.4),
                        accent.opacity(accentOpacity)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
    }

    private var specularBorder: some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .strokeBorder(
                LinearGradient(
                    colors: [
                        Color.white.opacity(0.42),
                        Color.white.opacity(0.18),
                        Color.white.opacity(0.12),
                        Color.white.opacity(0.08)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                lineWidth: 1
            )
    }
}

// MARK: - View extensions

extension View {
    /// Standard glass card surface (cornerRadius 16)
    func glassCard(accent: Color = .white, accentOpacity: Double = 0.17) -> some View {
        modifier(GlassSurfaceModifier(accent: accent, accentOpacity: accentOpacity, cornerRadius: 16))
    }

    /// Compact glass surface for fields/buttons (cornerRadius 10)
    func glassField() -> some View {
        modifier(GlassSurfaceModifier(
            accent: .white, accentOpacity: 0.065,
            cornerRadius: 10, shadowRadius: 6
        ))
    }

    /// Glass row surface with custom corner radii (for grouped rows)
    func glassRow(topRadius: CGFloat = 14, bottomRadius: CGFloat = 14) -> some View {
        // Build a single Path combining top and bottom rounded corners so we can stroke it
        self
            .background(.ultraThinMaterial.opacity(0.8))
            .overlay(
                LinearGradient(
                    colors: [Color.white.opacity(0.065), Color.white.opacity(0.04)],
                    startPoint: .top, endPoint: .bottom
                )
            )
            .overlay(
                GeometryReader { geo in
                    let r = geo.size
                    Path { p in
                        // Combined shape: top rounded corners + bottom rounded corners
                        p.addPath(RoundedCorner(radius: topRadius, corners: [.topLeft, .topRight]).path(in: CGRect(origin: .zero, size: r)))
                        p.addPath(RoundedCorner(radius: bottomRadius, corners: [.bottomLeft, .bottomRight]).path(in: CGRect(origin: .zero, size: r)))
                    }
                    .stroke(
                        LinearGradient(
                            colors: [Color.white.opacity(0.22), Color.white.opacity(0.08)],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
                }
            )
            .clipShape(
                RoundedCorner(radius: topRadius, corners: [.topLeft, .topRight])
            )
            .clipShape(
                RoundedCorner(radius: bottomRadius, corners: [.bottomLeft, .bottomRight])
            )
    }
}

// MARK: - Shimmer overlay

struct ShimmerView: View {
    @State private var offset: CGFloat = -1

    var body: some View {
        GeometryReader { geo in
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [.clear, .white.opacity(0.07), .clear],
                        startPoint: .leading, endPoint: .trailing
                    )
                )
                .frame(width: geo.size.width * 0.4)
                .offset(x: offset * geo.size.width)
        }
        .clipped()
        .allowsHitTesting(false)
        .onAppear {
            // Initial delay so shimmer doesn't fire immediately
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                startShimmer()
            }
        }
    }

    private func startShimmer() {
        offset = -0.6
        withAnimation(.linear(duration: 1.2)) {
            offset = 1.4
        }
        // Repeat every 3s
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            startShimmer()
        }
    }
}
```

- [ ] **Step 2: Build**

```bash
xcodebuild build -scheme RealityCheck \
  -project RealityCheck/RealityCheck.xcodeproj \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  2>&1 | grep -E "error:|BUILD"
```
Expected: `BUILD SUCCEEDED`

- [ ] **Step 3: Commit**

```bash
git add RealityCheck/GlassKit/GlassModifiers.swift
git commit -m "feat(GlassKit): add GlassModifiers — glass surface, specular border, shimmer"
```

---

### Task 3: GlassCard

**Files:**
- Create: `RealityCheck/GlassKit/GlassCard.swift`

> **Mục đích:** Thay thế `CardRowView`. Hai variants: `.pinned` (hero, với progress bar) và `.unpinned` (compact, chevron).

- [ ] **Step 1: Tạo file GlassCard.swift**

```swift
// RealityCheck/GlassKit/GlassCard.swift
import SwiftUI

enum GlassCardStyle {
    case pinned
    case unpinned
}

struct GlassCard: View {
    let card: RealityCard
    var style: GlassCardStyle = .unpinned

    private var accentColor: Color {
        switch card.type {
        case .manual: return .auroraRed
        case .formula: return card.formula?.accentColor ?? .auroraRed
        }
    }

    private var displayValue: String {
        FormulaEngine.displayValue(for: card)
    }

    // Progress ratio for formula cards (0.0–1.0), nil if not applicable
    private var progressValue: Double? {
        guard card.type == .formula, card.formula == .divide else { return nil }
        guard let a = card.inputA, let b = card.inputB, b != 0 else { return nil }
        return min(max(a / b, 0), 1)
    }

    var body: some View {
        switch style {
        case .pinned:  pinnedView
        case .unpinned: unpinnedView
        }
    }

    // MARK: Pinned (hero)
    private var pinnedView: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(card.title)
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(accentColor.opacity(0.7))
                        .textCase(.uppercase)
                        .tracking(1)

                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text(displayValue)
                            .font(.system(size: 38, weight: .heavy))
                            .foregroundStyle(accentColor)
                            .minimumScaleFactor(0.6)
                        Text(card.unit)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Text(card.contextLine)
                        .font(.system(size: 10))
                        .foregroundStyle(.tertiary)
                }

                Spacer()

                Text(card.type.rawValue)
                    .font(.system(size: 8, weight: .semibold))
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .background(accentColor.opacity(0.15))
                    .overlay(
                        RoundedRectangle(cornerRadius: 5)
                            .strokeBorder(accentColor.opacity(0.28), lineWidth: 1)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 5))
                    .foregroundStyle(accentColor.opacity(0.8))
            }

            if let progress = progressValue {
                ProgressView(value: progress)
                    .tint(
                        LinearGradient(
                            colors: [.auroraRed, Color(hex: "#ff9f43"), .auroraYellow],
                            startPoint: .leading, endPoint: .trailing
                        )
                    )
                    .scaleEffect(y: 1.5)
            }
        }
        .padding(16)
        .glassCard(accent: accentColor, accentOpacity: 0.22)
        .overlay(ShimmerView().clipShape(RoundedRectangle(cornerRadius: 16)))
    }

    // MARK: Unpinned (compact)
    private var unpinnedView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 3) {
                Text(card.title)
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(.tertiary)
                    .textCase(.uppercase)
                    .tracking(0.8)

                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(displayValue)
                        .font(.system(size: 22, weight: .heavy))
                        .foregroundStyle(accentColor)
                    Text(card.unit)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.quaternary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .glassCard(accent: accentColor, accentOpacity: 0.12)
        .overlay(ShimmerView().clipShape(RoundedRectangle(cornerRadius: 16)))
    }
}
```

- [ ] **Step 2: Build**

```bash
xcodebuild build -scheme RealityCheck \
  -project RealityCheck/RealityCheck.xcodeproj \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  2>&1 | grep -E "error:|BUILD"
```
Expected: `BUILD SUCCEEDED`

- [ ] **Step 3: Commit**

```bash
git add RealityCheck/GlassKit/GlassCard.swift
git commit -m "feat(GlassKit): add GlassCard — pinned hero and unpinned compact variants"
```

---

### Task 4: GlassField, GlassToggle, GlassButton

**Files:**
- Create: `RealityCheck/GlassKit/GlassField.swift`
- Create: `RealityCheck/GlassKit/GlassToggle.swift`
- Create: `RealityCheck/GlassKit/GlassButton.swift`

- [ ] **Step 1: Tạo GlassField.swift**

```swift
// RealityCheck/GlassKit/GlassField.swift
import SwiftUI

struct GlassField: View {
    let placeholder: String
    @Binding var text: String
    var keyboardType: UIKeyboardType = .default
    var font: Font = .body

    init(_ placeholder: String, text: Binding<String>, keyboardType: UIKeyboardType = .default) {
        self.placeholder = placeholder
        self._text = text
        self.keyboardType = keyboardType
    }

    var body: some View {
        TextField(placeholder, text: $text)
            .keyboardType(keyboardType)
            .font(font)
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .glassField()
    }
}

// MARK: - Section label (inline sub-view)
struct SectionLabel: View {
    let text: String

    init(_ text: String) { self.text = text }

    var body: some View {
        Text(text)
            .font(.system(size: 10, weight: .bold))
            .textCase(.uppercase)
            .tracking(1.4)
            .foregroundStyle(.tertiary)
            .padding(.leading, 4)
    }
}
```

- [ ] **Step 2: Tạo GlassToggle.swift**

```swift
// RealityCheck/GlassKit/GlassToggle.swift
import SwiftUI

struct GlassToggle: View {
    @Binding var isOn: Bool

    var body: some View {
        ZStack {
            // Track
            Capsule()
                .fill(isOn ? Color.auroraGreen.opacity(0.45) : Color.white.opacity(0.08))
                .overlay(
                    Capsule()
                        .strokeBorder(
                            isOn ? Color.auroraGreen.opacity(0.5) : Color.white.opacity(0.14),
                            lineWidth: 1
                        )
                )
                .overlay(
                    // Specular highlight top
                    LinearGradient(
                        colors: [
                            (isOn ? Color.auroraGreen : .white).opacity(0.3),
                            .clear
                        ],
                        startPoint: .top, endPoint: .center
                    )
                    .clipShape(Capsule())
                )
                .frame(width: 44, height: 26)
                .shadow(color: isOn ? Color.auroraGreen.opacity(0.3) : .clear, radius: 6)

            // Thumb
            Circle()
                .fill(Color.white)
                .frame(width: 20, height: 20)
                .shadow(color: .black.opacity(0.3), radius: 3, y: 1)
                .offset(x: isOn ? 9 : -9)
        }
        .frame(width: 44, height: 26)
        .onTapGesture {
            withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) {
                isOn.toggle()
            }
        }
    }
}
```

- [ ] **Step 3: Tạo GlassButton.swift**

```swift
// RealityCheck/GlassKit/GlassButton.swift
import SwiftUI

enum GlassButtonStyle {
    case primary   // Aurora green
    case secondary // White glass
    case destructive // Red
}

struct GlassButton: View {
    let label: String
    var style: GlassButtonStyle = .secondary
    var isDisabled: Bool = false
    let action: () -> Void

    init(_ label: String, style: GlassButtonStyle = .secondary, isDisabled: Bool = false, action: @escaping () -> Void) {
        self.label = label
        self.style = style
        self.isDisabled = isDisabled
        self.action = action
    }

    private var accentColor: Color {
        switch style {
        case .primary:     return .auroraGreen
        case .secondary:   return .white
        case .destructive: return .auroraRed
        }
    }

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 13, weight: style == .primary ? .semibold : .medium))
                .foregroundStyle(
                    style == .primary
                        ? Color(hex: "#c8ffe0").opacity(isDisabled ? 0.4 : 0.9)
                        : Color.white.opacity(isDisabled ? 0.3 : 0.7)
                )
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .modifier(GlassSurfaceModifier(
                    accent: accentColor,
                    accentOpacity: style == .primary ? 0.35 : 0.12,
                    cornerRadius: 10,
                    shadowRadius: style == .primary ? 10 : 6
                ))
                .shadow(
                    color: style == .primary ? Color.auroraGreen.opacity(isDisabled ? 0 : 0.25) : .clear,
                    radius: 8
                )
        }
        .disabled(isDisabled)
        .opacity(isDisabled ? 0.5 : 1)
    }
}
```

- [ ] **Step 4: Build**

```bash
xcodebuild build -scheme RealityCheck \
  -project RealityCheck/RealityCheck.xcodeproj \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  2>&1 | grep -E "error:|BUILD"
```
Expected: `BUILD SUCCEEDED`

- [ ] **Step 5: Commit**

```bash
git add RealityCheck/GlassKit/GlassField.swift \
        RealityCheck/GlassKit/GlassToggle.swift \
        RealityCheck/GlassKit/GlassButton.swift
git commit -m "feat(GlassKit): add GlassField, GlassToggle, GlassButton + SectionLabel"
```

---

### Task 5: FormulaChip

**Files:**
- Create: `RealityCheck/GlassKit/FormulaChip.swift`

- [ ] **Step 1: Tạo FormulaChip.swift**

```swift
// RealityCheck/GlassKit/FormulaChip.swift
import SwiftUI

struct FormulaChip: View {
    @Binding var selected: FormulaType

    private let options: [(type: FormulaType, icon: String, label: String)] = [
        (.divide,    "÷", "Chia A÷B"),
        (.count,     "/", "Đếm A/B"),
        (.subtract,  "−", "Trừ A−B"),
        (.countdown, "⏱", "Countdown"),
    ]

    var body: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 6) {
            ForEach(options, id: \.type) { option in
                chipButton(option)
            }
        }
    }

    private func chipButton(_ option: (type: FormulaType, icon: String, label: String)) -> some View {
        let isSelected = selected == option.type
        let accent = option.type.accentColor

        return Button {
            withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) {
                selected = option.type
            }
        } label: {
            VStack(spacing: 3) {
                Text(option.icon)
                    .font(.system(size: 14))
                Text(option.label)
                    .font(.system(size: 10, weight: isSelected ? .bold : .regular))
                    .foregroundStyle(isSelected ? accent : .secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .modifier(GlassSurfaceModifier(
                accent: isSelected ? accent : .white,
                accentOpacity: isSelected ? 0.16 : 0.04,
                cornerRadius: 10,
                shadowRadius: isSelected ? 8 : 4
            ))
        }
        .buttonStyle(.plain)
    }
}
```

- [ ] **Step 2: Build**

```bash
xcodebuild build -scheme RealityCheck \
  -project RealityCheck/RealityCheck.xcodeproj \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  2>&1 | grep -E "error:|BUILD"
```
Expected: `BUILD SUCCEEDED`

- [ ] **Step 3: Run existing tests để đảm bảo không break gì**

```bash
xcodebuild test -scheme RealityCheck \
  -project RealityCheck/RealityCheck.xcodeproj \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  2>&1 | grep -E "error:|Test.*passed|Test.*failed|BUILD"
```
Expected: tất cả tests pass.

- [ ] **Step 4: Commit**

```bash
git add RealityCheck/GlassKit/FormulaChip.swift
git commit -m "feat(GlassKit): add FormulaChip — 2x2 grid formula type selector"
```

---

## Phase 2 — View Rewrites

---

### Task 6: WidgetPreviewView — thêm accentColor

**Files:**
- Modify: `RealityCheck/Views/WidgetPreviewView.swift`

> **Mục đích:** Thêm `accentColor` parameter, thay background bằng glass surface, thêm orb overlay nhỏ.

- [ ] **Step 1: Rewrite WidgetPreviewView.swift**

```swift
// RealityCheck/Views/WidgetPreviewView.swift
import SwiftUI

struct WidgetPreviewView: View {
    let displayValue: String
    let unit: String
    let contextLine: String
    var accentColor: Color = .auroraRed

    var body: some View {
        ZStack {
            // Glass background
            RoundedRectangle(cornerRadius: 22)
                .fill(.ultraThinMaterial)
                .overlay(
                    LinearGradient(
                        colors: [
                            accentColor.opacity(0.25),
                            accentColor.opacity(0.08),
                            accentColor.opacity(0.15)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 22)
                        .strokeBorder(
                            LinearGradient(
                                colors: [
                                    accentColor.opacity(0.5),
                                    accentColor.opacity(0.2),
                                    accentColor.opacity(0.1)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )

            // Orb overlay (static in preview)
            Circle()
                .fill(accentColor.opacity(0.22))
                .frame(width: 80, height: 80)
                .blur(radius: 30)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                .offset(x: 10, y: -10)

            // Content
            VStack(spacing: 2) {
                Text(displayValue)
                    .font(.system(size: 36, weight: .heavy))
                    .foregroundStyle(accentColor)
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
                Text(unit.uppercased())
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.secondary)
                    .tracking(1)
                Text(contextLine)
                    .font(.system(size: 10))
                    .foregroundStyle(.tertiary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 12)
                    .padding(.top, 4)
            }
            .padding(12)

            // Shimmer
            ShimmerView()
                .clipShape(RoundedRectangle(cornerRadius: 22))
        }
        .frame(width: 155, height: 155)
        .shadow(color: accentColor.opacity(0.2), radius: 16, y: 8)
    }
}
```

- [ ] **Step 2: Build**

```bash
xcodebuild build -scheme RealityCheck \
  -project RealityCheck/RealityCheck.xcodeproj \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  2>&1 | grep -E "error:|BUILD"
```
Expected: `BUILD SUCCEEDED` (CardFormView vẫn compile vì accentColor có default value)

- [ ] **Step 3: Commit**

```bash
git add RealityCheck/Views/WidgetPreviewView.swift
git commit -m "feat(views): update WidgetPreviewView — glass background + accentColor param"
```

---

### Task 7: RealityCheckApp — AuroraBackground + dark mode

**Files:**
- Modify: `RealityCheck/RealityCheckApp.swift`

- [ ] **Step 1: Cập nhật RealityCheckApp.swift**

```swift
// RealityCheck/RealityCheckApp.swift
import SwiftUI
import SwiftData

@main
struct RealityCheckApp: App {
    init() {
        NotificationService.requestPermission()
    }

    var body: some Scene {
        WindowGroup {
            CardListView()
                .background(AuroraBackground())
                .preferredColorScheme(.dark)
        }
        .modelContainer(AppGroupContainer.shared)
    }
}
```

> **Lưu ý:** `.modelContainer(AppGroupContainer.shared)` dùng shared container để widget và app dùng chung store. Kiểm tra `AppGroupContainer.swift` — nếu chưa có `shared` static property thì giữ nguyên `.modelContainer(for: RealityCard.self)`.

- [ ] **Step 2: Kiểm tra AppGroupContainer có shared property không**

```bash
grep -n "shared\|modelContainer\|ModelContainer" \
  RealityCheck/Shared/AppGroupContainer.swift
```

Nếu không có `shared` → giữ nguyên `.modelContainer(for: RealityCard.self)` trong App.

- [ ] **Step 3: Build**

```bash
xcodebuild build -scheme RealityCheck \
  -project RealityCheck/RealityCheck.xcodeproj \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  2>&1 | grep -E "error:|BUILD"
```

- [ ] **Step 4: Commit**

```bash
git add RealityCheck/RealityCheckApp.swift
git commit -m "feat(app): wrap root view with AuroraBackground + preferredColorScheme(.dark)"
```

---

### Task 8: CardListView rewrite

**Files:**
- Modify: `RealityCheck/Views/CardListView.swift`

> **Mục đích:** Thay `List` bằng `ScrollView + VStack`. Dùng `GlassCard`. Thêm stagger animation. Settings navigate bằng `navigationDestination`.

- [ ] **Step 1: Rewrite CardListView.swift**

```swift
// RealityCheck/Views/CardListView.swift
import SwiftUI
import SwiftData
import WidgetKit

struct CardListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \RealityCard.updatedAt, order: .reverse) private var cards: [RealityCard]
    @State private var showingCreateForm = false
    @State private var showingSettings = false
    @State private var appeared = false

    private var pinnedCard: RealityCard? { cards.first(where: \.isPinned) }
    private var unpinnedCards: [RealityCard] { cards.filter { !$0.isPinned } }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 10) {
                    if cards.isEmpty {
                        emptyState
                    } else {
                        cardContent
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 24)
            }
            .navigationTitle("Reality Check")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button { showingCreateForm = true } label: {
                        Image(systemName: "plus")
                            .fontWeight(.semibold)
                    }
                }
                ToolbarItem(placement: .automatic) {
                    Button { showingSettings = true } label: {
                        Image(systemName: "gearshape")
                    }
                }
            }
            .navigationDestination(isPresented: $showingSettings) {
                SettingsView()
            }
            .navigationDestination(for: RealityCard.self) { card in
                CardFormView(card: card)
            }
            .sheet(isPresented: $showingCreateForm) {
                NavigationStack { CardFormView(card: nil) }
            }
        }
        .onAppear {
            withAnimation(.spring(duration: 0.4)) { appeared = true }
        }
    }

    // MARK: - Card content

    @ViewBuilder
    private var cardContent: some View {
        // Pinned section
        if let pinned = pinnedCard {
            SectionLabel("📍 Widget hiện tại")
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 8)

            NavigationLink(value: pinned) {
                GlassCard(card: pinned, style: .pinned)
            }
            .buttonStyle(.plain)
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 8)
            .animation(.spring(duration: 0.4).delay(0.06), value: appeared)
        }

        // Unpinned section
        if !unpinnedCards.isEmpty {
            if pinnedCard != nil {
                SectionLabel("Các card khác")
                    .padding(.top, 4)
                    .opacity(appeared ? 1 : 0)
            }

            ForEach(Array(unpinnedCards.enumerated()), id: \.element.id) { index, card in
                NavigationLink(value: card) {
                    GlassCard(card: card, style: .unpinned)
                }
                .buttonStyle(.plain)
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                    Button(role: .destructive) {
                        modelContext.delete(card)
                    } label: {
                        Label("Xoá", systemImage: "trash")
                    }
                }
                .swipeActions(edge: .leading) {
                    Button { pinCard(card) } label: {
                        Label("Pin", systemImage: "pin")
                    }
                    .tint(.orange)
                }
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 10)
                .animation(
                    .spring(duration: 0.4).delay(Double(index + 1) * 0.06),
                    value: appeared
                )
            }
        }
    }

    // MARK: - Empty state

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "rectangle.stack.badge.plus")
                .font(.system(size: 40))
                .foregroundStyle(.quaternary)
                .padding(.top, 60)

            Text("Chưa có Reality Card nào")
                .font(.headline)
                .foregroundStyle(.secondary)

            Text("Tạo card đầu tiên để\nđối diện thực tế")
                .font(.subheadline)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)

            GlassButton("＋ Tạo card đầu tiên", style: .primary) {
                showingCreateForm = true
            }
            .padding(.top, 4)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Actions

    private func pinCard(_ card: RealityCard) {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            for c in cards where c.isPinned { c.isPinned = false }
            card.isPinned = true
            card.updatedAt = Date()
        }
        WidgetCenter.shared.reloadAllTimelines()
    }
}
```

- [ ] **Step 2: Build**

```bash
xcodebuild build -scheme RealityCheck \
  -project RealityCheck/RealityCheck.xcodeproj \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  2>&1 | grep -E "error:|BUILD"
```

- [ ] **Step 3: Run tests**

```bash
xcodebuild test -scheme RealityCheck \
  -project RealityCheck/RealityCheck.xcodeproj \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  2>&1 | grep -E "Test.*passed|Test.*failed|BUILD"
```

- [ ] **Step 4: Commit**

```bash
git add RealityCheck/Views/CardListView.swift
git commit -m "feat(views): rewrite CardListView — ScrollView + GlassCard + stagger animation"
```

---

### Task 9: CardFormView rewrite

**Files:**
- Modify: `RealityCheck/Views/CardFormView.swift`

> **Mục đích:** Thay `Form` bằng `HStack` 2 cột — form fields bên trái, live widget preview cố định bên phải. Dùng `GlassField`, `FormulaChip`, `GlassButton`.

- [ ] **Step 1: Rewrite CardFormView.swift**

```swift
// RealityCheck/Views/CardFormView.swift
import SwiftUI
import SwiftData
import WidgetKit

struct CardFormView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let card: RealityCard?

    @State private var title: String = ""
    @State private var type: CardType = .manual
    @State private var value: String = ""
    @State private var formula: FormulaType = .divide
    @State private var inputA: String = ""
    @State private var inputALabel: String = ""
    @State private var inputB: String = ""
    @State private var inputBLabel: String = ""
    @State private var targetDate: Date = Date()
    @State private var unit: String = ""
    @State private var contextLine: String = ""

    private var isEditing: Bool { card != nil }

    // MARK: - Preview value

    private var previewDisplayValue: String {
        switch type {
        case .manual:
            guard let v = Double(value) else { return "--" }
            return FormulaEngine.formatNumber(v)
        case .formula:
            switch formula {
            case .divide:
                guard let a = Double(inputA), let b = Double(inputB), b != 0 else { return "--" }
                return FormulaEngine.formatNumber(a / b)
            case .count:
                guard let a = Double(inputA), let b = Double(inputB) else { return "--" }
                return "\(Int(a))/\(Int(b))"
            case .subtract:
                guard let a = Double(inputA), let b = Double(inputB) else { return "--" }
                return FormulaEngine.formatNumber(a - b)
            case .countdown:
                let days = Calendar.current.dateComponents([.day], from: Date(), to: targetDate).day ?? 0
                return "\(max(0, days))"
            }
        }
    }

    private var previewAccentColor: Color {
        switch type {
        case .manual: return .auroraRed
        case .formula: return formula.accentColor
        }
    }

    private var canSave: Bool {
        !title.isEmpty && !unit.isEmpty && !contextLine.isEmpty
    }

    // MARK: - Body

    var body: some View {
        HStack(spacing: 0) {
            formPanel
                .frame(maxWidth: .infinity)

            Divider().opacity(0.1)

            previewPanel
                .frame(width: 200)
        }
        .navigationTitle(isEditing ? "Sửa Card" : "Tạo Card")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if !isEditing {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Huỷ") { dismiss() }
                }
            }
            ToolbarItem(placement: .confirmationAction) {
                GlassButton("Lưu", style: .primary, isDisabled: !canSave) { save() }
            }
        }
        .onAppear { loadCard() }
    }

    // MARK: - Form panel

    private var formPanel: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {

                // Title + type
                VStack(alignment: .leading, spacing: 8) {
                    SectionLabel("Thông tin")
                    GlassField("Tiêu đề", text: $title)
                    segmentedTypePicker
                }

                // Conditional inputs
                if type == .manual {
                    VStack(alignment: .leading, spacing: 8) {
                        SectionLabel("Giá trị")
                        GlassField("Số liệu", text: $value, keyboardType: .decimalPad)
                    }
                } else {
                    VStack(alignment: .leading, spacing: 8) {
                        SectionLabel("Công thức")
                        FormulaChip(selected: $formula)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        SectionLabel("Inputs")
                        formulaInputs
                    }
                }

                // Display
                VStack(alignment: .leading, spacing: 8) {
                    SectionLabel("Hiển thị")
                    GlassField("Đơn vị (ngày, tháng, triệu...)", text: $unit)
                    GlassField("Context line", text: $contextLine)
                }

                // Actions
                HStack(spacing: 8) {
                    pinButton
                    if isEditing { deleteButton }
                }
                .padding(.top, 4)
            }
            .padding(16)
        }
    }

    // MARK: - Segmented type picker

    private var segmentedTypePicker: some View {
        HStack(spacing: 0) {
            ForEach([CardType.manual, CardType.formula], id: \.self) { t in
                Button {
                    withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) { type = t }
                } label: {
                    Text(t == .manual ? "Manual" : "Formula")
                        .font(.system(size: 12, weight: type == t ? .semibold : .regular))
                        .foregroundStyle(type == t ? .primary : .secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 7)
                        .background(
                            type == t
                                ? RoundedRectangle(cornerRadius: 8)
                                    .fill(.ultraThinMaterial)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .strokeBorder(Color.white.opacity(0.2), lineWidth: 1)
                                    )
                                : nil
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(3)
        .background(Color.white.opacity(0.05))
        .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(Color.white.opacity(0.08), lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    // MARK: - Formula inputs

    @ViewBuilder
    private var formulaInputs: some View {
        if formula == .countdown {
            // Date picker with glass style
            HStack {
                Image(systemName: "calendar")
                    .foregroundStyle(.secondary)
                DatePicker("Ngày đích", selection: $targetDate, displayedComponents: .date)
                    .labelsHidden()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .glassField()

            if previewDisplayValue != "--" {
                Text("→ \(previewDisplayValue) ngày còn lại")
                    .font(.caption)
                    .foregroundStyle(Color.auroraGreen.opacity(0.8))
                    .padding(.leading, 4)
            }
        } else {
            // A/B inputs
            VStack(spacing: 6) {
                HStack(spacing: 8) {
                    Text("A")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(.tertiary)
                        .frame(width: 14)
                    GlassField("Tên (VD: Doanh số)", text: $inputALabel)
                    GlassField("Giá trị", text: $inputA, keyboardType: .decimalPad)
                        .frame(width: 80)
                }
                HStack(spacing: 8) {
                    Text("B")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(.tertiary)
                        .frame(width: 14)
                    GlassField("Tên (VD: Mục tiêu)", text: $inputBLabel)
                    GlassField("Giá trị", text: $inputB, keyboardType: .decimalPad)
                        .frame(width: 80)
                }
            }
        }
    }

    // MARK: - Pin / Delete buttons

    private var pinButton: some View {
        let isPinned = card?.isPinned ?? false
        return Button {
            if let card {
                withAnimation {
                    for c in (try? modelContext.fetch(FetchDescriptor<RealityCard>())) ?? [] where c.isPinned {
                        c.isPinned = false
                    }
                    card.isPinned = !isPinned
                    card.updatedAt = Date()
                }
                WidgetCenter.shared.reloadAllTimelines()
            }
        } label: {
            Label(isPinned ? "Bỏ pin" : "Pin lên widget", systemImage: isPinned ? "pin.slash" : "pin")
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .modifier(GlassSurfaceModifier(cornerRadius: 10, shadowRadius: 4))
        }
        .buttonStyle(.plain)
        .opacity(isEditing ? 1 : 0)
        .disabled(!isEditing)
    }

    private var deleteButton: some View {
        Button(role: .destructive) {
            if let card { modelContext.delete(card) }
            WidgetCenter.shared.reloadAllTimelines()
            dismiss()
        } label: {
            Image(systemName: "trash")
                .font(.system(size: 14))
                .foregroundStyle(Color.auroraRed.opacity(0.7))
                .frame(width: 36, height: 36)
                .modifier(GlassSurfaceModifier(
                    accent: .auroraRed, accentOpacity: 0.08,
                    cornerRadius: 10, shadowRadius: 4
                ))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Preview panel

    private var previewPanel: some View {
        VStack(spacing: 14) {
            SectionLabel("Preview")

            WidgetPreviewView(
                displayValue: previewDisplayValue,
                unit: unit,
                contextLine: contextLine,
                accentColor: previewAccentColor
            )
            .animation(.spring(response: 0.35, dampingFraction: 0.6), value: previewDisplayValue)
            .animation(.spring(response: 0.35, dampingFraction: 0.6), value: previewAccentColor.description)

            // Live badge
            HStack(spacing: 5) {
                Circle()
                    .fill(Color.auroraGreen)
                    .frame(width: 6, height: 6)
                    .shadow(color: .auroraGreen.opacity(0.8), radius: 4)
                Text("Live preview")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(Color.auroraGreen.opacity(0.85))
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(Color.auroraGreen.opacity(0.1))
            .overlay(Capsule().strokeBorder(Color.auroraGreen.opacity(0.22), lineWidth: 1))
            .clipShape(Capsule())

            Spacer()
        }
        .padding(16)
    }

    // MARK: - Load / Save

    private func loadCard() {
        guard let card else { return }
        title = card.title
        type = card.type
        value = card.value.map { String($0) } ?? ""
        formula = card.formula ?? .divide
        inputA = card.inputA.map { String($0) } ?? ""
        inputALabel = card.inputALabel ?? ""
        inputB = card.inputB.map { String($0) } ?? ""
        inputBLabel = card.inputBLabel ?? ""
        targetDate = card.targetDate ?? Date()
        unit = card.unit
        contextLine = card.contextLine
    }

    private func save() {
        if let card {
            card.title = title
            card.type = type
            card.value = Double(value)
            card.formula = type == .formula ? formula : nil
            card.inputA = Double(inputA)
            card.inputALabel = inputALabel.isEmpty ? nil : inputALabel
            card.inputB = Double(inputB)
            card.inputBLabel = inputBLabel.isEmpty ? nil : inputBLabel
            card.targetDate = formula == .countdown ? targetDate : nil
            card.unit = unit
            card.contextLine = contextLine
            card.updatedAt = Date()
        } else {
            let newCard = RealityCard(
                title: title,
                type: type,
                formula: type == .formula ? formula : nil,
                value: Double(value),
                inputA: Double(inputA),
                inputALabel: inputALabel.isEmpty ? nil : inputALabel,
                inputB: Double(inputB),
                inputBLabel: inputBLabel.isEmpty ? nil : inputBLabel,
                targetDate: formula == .countdown ? targetDate : nil,
                unit: unit,
                contextLine: contextLine
            )
            modelContext.insert(newCard)
        }
        WidgetCenter.shared.reloadAllTimelines()
        dismiss()
    }
}
```

- [ ] **Step 2: Build**

```bash
xcodebuild build -scheme RealityCheck \
  -project RealityCheck/RealityCheck.xcodeproj \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  2>&1 | grep -E "error:|BUILD"
```

- [ ] **Step 3: Run tests**

```bash
xcodebuild test -scheme RealityCheck \
  -project RealityCheck/RealityCheck.xcodeproj \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  2>&1 | grep -E "Test.*passed|Test.*failed"
```

- [ ] **Step 4: Commit**

```bash
git add RealityCheck/Views/CardFormView.swift
git commit -m "feat(views): rewrite CardFormView — 2-col layout, GlassField, FormulaChip, live preview"
```

---

### Task 10: SettingsView rewrite

**Files:**
- Modify: `RealityCheck/Views/SettingsView.swift`

- [ ] **Step 1: Rewrite SettingsView.swift**

```swift
// RealityCheck/Views/SettingsView.swift
import SwiftUI
import SwiftData

struct SettingsView: View {
    @AppStorage("notificationEnabled") private var notificationEnabled = true
    @AppStorage("notificationHour")    private var notificationHour = 8
    @AppStorage("notificationMinute")  private var notificationMinute = 0

    @Query(filter: #Predicate<RealityCard> { $0.isPinned == true })
    private var pinnedCards: [RealityCard]

    private var notificationTime: Binding<Date> {
        Binding(
            get: {
                Calendar.current.date(from: DateComponents(
                    hour: notificationHour, minute: notificationMinute
                )) ?? Date()
            },
            set: { newDate in
                let c = Calendar.current.dateComponents([.hour, .minute], from: newDate)
                notificationHour = c.hour ?? 8
                notificationMinute = c.minute ?? 0
                updateNotification()
            }
        )
    }

    private var timeString: String {
        String(format: "%02d:%02d", notificationHour, notificationMinute)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {

                // Thông báo section
                VStack(alignment: .leading, spacing: 8) {
                    SectionLabel("Thông báo hàng ngày")

                    VStack(spacing: 1) {
                        // Toggle row
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Bật thông báo")
                                    .font(.system(size: 14, weight: .medium))
                                Text("Nhắc nhở Reality Card mỗi ngày")
                                    .font(.caption)
                                    .foregroundStyle(.tertiary)
                            }
                            Spacer()
                            GlassToggle(isOn: $notificationEnabled)
                                .onChange(of: notificationEnabled) { _, enabled in
                                    if enabled {
                                        NotificationService.requestPermission()
                                        updateNotification()
                                    } else {
                                        NotificationService.cancelDailyNotification()
                                    }
                                }
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 13)
                        .glassRow(topRadius: 14, bottomRadius: 5)

                        // Time row
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Thời gian nhắc")
                                    .font(.system(size: 14, weight: .medium))
                                Text("Mỗi ngày vào lúc")
                                    .font(.caption)
                                    .foregroundStyle(.tertiary)
                            }
                            Spacer()
                            // Large digit time picker
                            DatePicker("", selection: notificationTime, displayedComponents: .hourAndMinute)
                                .labelsHidden()
                                .overlay(
                                    // Glass overlay showing HH:MM
                                    HStack(alignment: .lastTextBaseline, spacing: 2) {
                                        Text(String(format: "%02d", notificationHour))
                                            .font(.system(size: 22, weight: .bold))
                                        Text(":")
                                            .font(.system(size: 18, weight: .bold))
                                            .foregroundStyle(.tertiary)
                                        Text(String(format: "%02d", notificationMinute))
                                            .font(.system(size: 22, weight: .bold))
                                    }
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .glassCard()
                                    .allowsHitTesting(false)
                                )
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 13)
                        .glassRow(topRadius: 5, bottomRadius: 14)
                        .opacity(notificationEnabled ? 1 : 0.4)
                        .disabled(!notificationEnabled)
                    }

                    // Status badge
                    if notificationEnabled {
                        HStack(spacing: 7) {
                            Circle()
                                .fill(Color.auroraGreen)
                                .frame(width: 7, height: 7)
                                .shadow(color: .auroraGreen.opacity(0.7), radius: 4)
                            Text("Đã lên lịch · Mỗi ngày \(timeString)")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(Color.auroraGreen.opacity(0.85))
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.auroraGreen.opacity(0.08))
                        .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(Color.auroraGreen.opacity(0.18), lineWidth: 1))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    } else {
                        HStack(spacing: 7) {
                            Image(systemName: "bell.slash")
                                .font(.system(size: 11))
                                .foregroundStyle(.quaternary)
                            Text("Thông báo đã tắt")
                                .font(.system(size: 11))
                                .foregroundStyle(.quaternary)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.white.opacity(0.04))
                        .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(Color.white.opacity(0.08), lineWidth: 1))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                }

                // Widget section
                VStack(alignment: .leading, spacing: 8) {
                    SectionLabel("Widget")

                    VStack(spacing: 1) {
                        HStack {
                            Text("Đang hiển thị")
                                .font(.system(size: 14, weight: .medium))
                            Spacer()
                            Text(pinnedCards.first?.title ?? "--")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(Color.auroraRed)
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)
                        .glassRow(topRadius: 14, bottomRadius: 5)

                        Button {
                            WidgetCenter.shared.reloadAllTimelines()
                        } label: {
                            HStack {
                                Text("Reload widget")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundStyle(.primary)
                                Spacer()
                                Text("Làm mới ↺")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundStyle(Color.auroraTeal)
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 12)
                            .glassRow(topRadius: 5, bottomRadius: 14)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(16)
        }
        .navigationTitle("Cài đặt")
        .onAppear {
            if notificationEnabled { NotificationService.requestPermission() }
        }
    }

    private func updateNotification() {
        guard notificationEnabled else { return }
        NotificationService.scheduleDailyNotification(
            for: pinnedCards.first,
            hour: notificationHour,
            minute: notificationMinute
        )
    }
}
```

- [ ] **Step 2: Build**

```bash
xcodebuild build -scheme RealityCheck \
  -project RealityCheck/RealityCheck.xcodeproj \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  2>&1 | grep -E "error:|BUILD"
```

- [ ] **Step 3: Run tests**

```bash
xcodebuild test -scheme RealityCheck \
  -project RealityCheck/RealityCheck.xcodeproj \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  2>&1 | grep -E "Test.*passed|Test.*failed"
```

- [ ] **Step 4: Commit**

```bash
git add RealityCheck/Views/SettingsView.swift
git commit -m "feat(views): rewrite SettingsView — GlassRow, GlassToggle, large digit time, status badge"
```

---

## Phase 3 — Widget + Polish

---

### Task 11: Widget glass redesign + medium size

**Files:**
- Modify: `RealityCheckWidget/RealityCheckWidget.swift`

> **Mục đích:** Update widget entry view sang glass style (no backdrop blur — widgets không hỗ trợ). Thêm `.systemMedium`. Thêm `formula` field vào `RealityCheckEntry` để map accent color.

- [ ] **Step 1: Cập nhật RealityCheckWidget.swift**

```swift
// RealityCheckWidget/RealityCheckWidget.swift
import WidgetKit
import SwiftUI
import SwiftData

// MARK: - Entry

struct RealityCheckEntry: TimelineEntry {
    let date: Date
    let displayValue: String
    let title: String           // NEW: card title for medium widget
    let unit: String
    let contextLine: String
    let hasCard: Bool
    let formula: FormulaType?   // NEW: for accent color
    let cardType: CardType      // NEW: manual vs formula
    let progressValue: Double?  // NEW: 0.0–1.0 for formula progress bar in medium widget
}

// MARK: - Provider (unchanged logic)

struct RealityCheckProvider: TimelineProvider {
    private var modelContext: ModelContext {
        let container = try! ModelContainer(
            for: RealityCard.self,
            configurations: AppGroupContainer.modelConfiguration
        )
        return ModelContext(container)
    }

    func placeholder(in context: Context) -> RealityCheckEntry {
        RealityCheckEntry(date: Date(), displayValue: "47", title: "Runway",
                          unit: "ngày", contextLine: "runway nếu nghỉ việc hôm nay",
                          hasCard: true, formula: .countdown, cardType: .formula,
                          progressValue: 0.65)
    }

    func getSnapshot(in context: Context, completion: @escaping (RealityCheckEntry) -> Void) {
        completion(fetchEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<RealityCheckEntry>) -> Void) {
        let entry = fetchEntry()
        let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: Date())!
        completion(Timeline(entries: [entry], policy: .after(nextUpdate)))
    }

    private func fetchEntry() -> RealityCheckEntry {
        let descriptor = FetchDescriptor<RealityCard>(predicate: #Predicate { $0.isPinned == true })
        guard let card = try? modelContext.fetch(descriptor).first else {
            return RealityCheckEntry(date: Date(), displayValue: "--", title: "",
                                     unit: "", contextLine: "Mở app để tạo Reality Card đầu tiên",
                                     hasCard: false, formula: nil, cardType: .manual,
                                     progressValue: nil)
        }
        // Compute optional progress for formula cards (0.0–1.0)
        let progress: Double? = {
            guard card.type == .formula, let formula = card.formula else { return nil }
            switch formula {
            case .countdown:
                guard let target = card.targetDate else { return nil }
                let total = target.timeIntervalSince(card.createdAt ?? Date())
                let elapsed = Date().timeIntervalSince(card.createdAt ?? Date())
                guard total > 0 else { return nil }
                return min(1.0, max(0.0, elapsed / total))
            case .divide, .count, .subtract:
                guard let a = card.inputA, let b = card.inputB, b > 0 else { return nil }
                return min(1.0, a / b)
            }
        }()
        return RealityCheckEntry(
            date: Date(),
            displayValue: FormulaEngine.displayValue(for: card),
            title: card.title,
            unit: card.unit,
            contextLine: card.contextLine,
            hasCard: true,
            formula: card.formula,
            cardType: card.type,
            progressValue: progress
        )
    }
}

// MARK: - Widget accent color helper

extension RealityCheckEntry {
    var accentColor: Color {
        guard hasCard else { return Color(hex: "#ff6b6b") }
        if cardType == .manual { return Color(hex: "#ff6b6b") }
        switch formula {
        case .countdown: return Color(hex: "#00f5a0")
        case .divide:    return Color(hex: "#64dfdf")
        case .count:     return Color(hex: "#c77dff")
        case .subtract:  return Color(hex: "#ffd93d")
        case .none:      return Color(hex: "#ff6b6b")
        }
    }
}

// MARK: - Small widget view

struct WidgetSmallView: View {
    let entry: RealityCheckEntry

    var body: some View {
        ZStack {
            // Static orb (no animation in widget)
            Circle()
                .fill(entry.accentColor.opacity(0.20))
                .frame(width: 100, height: 100)
                .blur(radius: 30)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                .offset(x: 10, y: -10)

            if entry.hasCard {
                VStack(spacing: 2) {
                    Text(entry.displayValue)
                        .font(.system(size: 36, weight: .heavy))
                        .foregroundStyle(entry.accentColor)
                        .minimumScaleFactor(0.5)
                        .lineLimit(1)
                    Text(entry.unit.uppercased())
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.secondary)
                        .tracking(1)
                    Text(entry.contextLine)
                        .font(.system(size: 9))
                        .foregroundStyle(.tertiary)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .padding(.horizontal, 10)
                        .padding(.top, 3)
                }
                .padding(12)
            } else {
                VStack(spacing: 8) {
                    Image(systemName: "plus.rectangle.on.rectangle")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                    Text(entry.contextLine)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                        .multilineTextAlignment(.center)
                }
                .padding(12)
            }
        }
    }
}

// MARK: - Medium widget view

struct WidgetMediumView: View {
    let entry: RealityCheckEntry

    var body: some View {
        HStack(spacing: 0) {
            // Left: big value
            VStack(spacing: 4) {
                Text(entry.displayValue)
                    .font(.system(size: 42, weight: .heavy))
                    .foregroundStyle(entry.accentColor)
                    .minimumScaleFactor(0.4)
                    .lineLimit(1)
                Text(entry.unit.uppercased())
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.secondary)
                    .tracking(1)
            }
            .frame(maxWidth: .infinity)
            .overlay(
                Rectangle()
                    .frame(width: 1)
                    .foregroundStyle(Color.white.opacity(0.08)),
                alignment: .trailing
            )

            // Right: title + context + progress
            VStack(alignment: .leading, spacing: 6) {
                Text(entry.title)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                Text(entry.contextLine)
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                if let progress = entry.progressValue {
                    ProgressView(value: progress)
                        .tint(entry.accentColor)
                        .padding(.top, 2)
                }
            }
            .padding(.leading, 14)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(16)
        .overlay(
            Circle()
                .fill(entry.accentColor.opacity(0.15))
                .frame(width: 120)
                .blur(radius: 40)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .offset(x: -20, y: -20)
        )
    }
}

// MARK: - Entry view dispatcher

struct RealityCheckWidgetView: View {
    @Environment(\.widgetFamily) var family
    let entry: RealityCheckEntry

    var body: some View {
        switch family {
        case .systemMedium: WidgetMediumView(entry: entry)
        default:            WidgetSmallView(entry: entry)
        }
    }
}

// MARK: - Widget bundle

@main
struct RealityCheckWidgetBundle: Widget {
    let kind = "RealityCheckWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: RealityCheckProvider()) { entry in
            RealityCheckWidgetView(entry: entry)
                .containerBackground(
                    LinearGradient(
                        colors: [Color(hex: "#0d1b2a"), Color(hex: "#071a0f")],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    ),
                    for: .widget
                )
        }
        .configurationDisplayName("Reality Check")
        .description("Hiện Reality Card trên home screen")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
```

> **Lưu ý:** `Color(hex:)` extension cần available trong widget target. Tạo file `RealityCheckWidget/ColorExtensions.swift` duplicate hoặc move extension vào `Shared/` và add to both targets.

- [ ] **Step 2: Tạo ColorExtensions.swift cho widget target**

```swift
// RealityCheckWidget/ColorExtensions.swift
import SwiftUI

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r = Double((int >> 16) & 0xFF) / 255
        let g = Double((int >> 8) & 0xFF) / 255
        let b = Double(int & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }
}
```

- [ ] **Step 3: Build cả hai targets**

```bash
# Main app
xcodebuild build -scheme RealityCheck \
  -project RealityCheck/RealityCheck.xcodeproj \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  2>&1 | grep -E "error:|BUILD"

# Widget
xcodebuild build -scheme RealityCheckWidget \
  -project RealityCheck/RealityCheck.xcodeproj \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  2>&1 | grep -E "error:|BUILD"
```
Expected: cả hai `BUILD SUCCEEDED`

- [ ] **Step 4: Run tests**

```bash
xcodebuild test -scheme RealityCheck \
  -project RealityCheck/RealityCheck.xcodeproj \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  2>&1 | grep -E "Test.*passed|Test.*failed"
```

- [ ] **Step 5: Commit**

```bash
git add RealityCheckWidget/RealityCheckWidget.swift \
        RealityCheckWidget/ColorExtensions.swift
git commit -m "feat(widget): glass redesign — aurora background, accent color per type, medium size"
```

---

### Task 12: CardRowView cleanup

**Files:**
- Modify: `RealityCheck/Views/CardRowView.swift`

> `CardRowView` không còn được dùng sau khi `CardListView` chuyển sang `GlassCard`. Xoá để tránh dead code.

- [ ] **Step 1: Kiểm tra CardRowView có còn được reference không**

```bash
grep -rn "CardRowView" RealityCheck/ --include="*.swift"
```

Expected: chỉ còn trong `CardRowView.swift` chính nó (không có file nào import).

- [ ] **Step 2: Xoá file**

```bash
rm RealityCheck/Views/CardRowView.swift
```

- [ ] **Step 3: Build**

```bash
xcodebuild build -scheme RealityCheck \
  -project RealityCheck/RealityCheck.xcodeproj \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  2>&1 | grep -E "error:|BUILD"
```

- [ ] **Step 4: Commit**

```bash
git add -A
git commit -m "chore: remove CardRowView — replaced by GlassCard"
```

---

### Task 13: Navigation zoom transition (iOS 18+)

**Files:**
- Modify: `RealityCheck/Views/CardListView.swift`

> Thêm `.navigationTransition(.zoom)` cho card tap. Fallback tự động trên iOS 17.

- [ ] **Step 1: Thêm `@Namespace` và zoom transition vào CardListView**

Tìm đoạn NavigationLink unpinned trong `cardContent` và cập nhật:

```swift
// Ở đầu struct CardListView, thêm:
@Namespace private var namespace

// Trong unpinnedView NavigationLink, thêm modifier:
NavigationLink(value: card) {
    GlassCard(card: card, style: .unpinned)
}
.buttonStyle(.plain)
// ... (swipeActions giữ nguyên)
.matchedTransitionSource(id: card.id, in: namespace)  // iOS 18+
```

Và trong `.navigationDestination(for: RealityCard.self)`:
```swift
.navigationDestination(for: RealityCard.self) { card in
    CardFormView(card: card)
        .navigationTransition(.zoom(sourceID: card.id, in: namespace))  // iOS 18+
}
```

> **Lưu ý:** `.matchedTransitionSource` và `.navigationTransition(.zoom)` chỉ available iOS 18+. Nếu minimum deployment target < 18, wrap bằng `if #available(iOS 18, *)`.

- [ ] **Step 2: Kiểm tra deployment target**

```bash
grep -n "IPHONEOS_DEPLOYMENT_TARGET" \
  RealityCheck/RealityCheck.xcodeproj/project.pbxproj | head -5
```

Nếu deployment target < 18, dùng `@available` guard:
```swift
// Thay vì trực tiếp dùng API, check availability:
if #available(iOS 18.0, *) {
    NavigationLink(value: card) { GlassCard(...) }
        .matchedTransitionSource(id: card.id, in: namespace)
} else {
    NavigationLink(value: card) { GlassCard(...) }
}
```

- [ ] **Step 3: Build**

```bash
xcodebuild build -scheme RealityCheck \
  -project RealityCheck/RealityCheck.xcodeproj \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  2>&1 | grep -E "error:|BUILD"
```

- [ ] **Step 4: Run full test suite**

```bash
xcodebuild test -scheme RealityCheck \
  -project RealityCheck/RealityCheck.xcodeproj \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  2>&1 | grep -E "Test Suite.*passed|Test.*failed|BUILD"
```
Expected: tất cả pass.

- [ ] **Step 5: Final commit**

```bash
git add RealityCheck/Views/CardListView.swift
git commit -m "feat(views): add navigation zoom transition (iOS 18+) with graceful fallback"
```

---

## Done Checklist

- [ ] Phase 1: GlassKit — 7 files tạo mới, build success
- [ ] Phase 2: 5 views rewrite, tất cả tests pass
- [ ] Phase 3: Widget glass redesign + medium size, navigation zoom
- [ ] `CardRowView.swift` đã xoá
- [ ] Tất cả tests vẫn pass (Models/Services không đổi)
- [ ] Build cả main + widget target thành công
