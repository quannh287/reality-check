# Reality Check — Phase 1 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a native iOS/macOS app where users create "Reality Cards" (hard facts about their situation) and pin one to a home screen widget that displays a bold, unavoidable number.

**Architecture:** SwiftUI app with SwiftData persistence in an App Groups shared container. WidgetKit extension reads the same SwiftData store to render the pinned card. UserNotifications for daily reminders.

**Tech Stack:** Swift, SwiftUI, SwiftData, WidgetKit, UserNotifications, App Groups. iOS 17+ / macOS 14+.

**Spec:** `docs/specs/2026-03-23-reality-check-app-design.md`

---

## File Structure

```
RealityCheck/
├── RealityCheck.xcodeproj
├── RealityCheck/                          # Main app target
│   ├── RealityCheckApp.swift              # App entry point, SwiftData container setup
│   ├── Models/
│   │   ├── RealityCard.swift              # SwiftData @Model, enums (CardType, FormulaType)
│   │   └── FormulaEngine.swift            # Compute display value from card data
│   ├── Views/
│   │   ├── CardListView.swift             # Main screen: pinned card + card list
│   │   ├── CardRowView.swift              # Single card row in the list
│   │   ├── CardFormView.swift             # Create/Edit card form
│   │   ├── WidgetPreviewView.swift        # Mini widget preview shown in form
│   │   └── SettingsView.swift             # Notification time picker + toggle
│   ├── Services/
│   │   └── NotificationService.swift      # Schedule/cancel daily notifications
│   └── Shared/
│       └── AppGroupContainer.swift        # App Groups container URL + SwiftData config
├── RealityCheckWidget/                    # WidgetKit extension target
│   ├── RealityCheckWidget.swift           # Widget definition, timeline provider, entry view
│   └── Info.plist
├── RealityCheckTests/                     # Unit test target
│   ├── FormulaEngineTests.swift           # Formula computation tests
│   ├── RealityCardTests.swift             # Model validation tests
│   └── NotificationServiceTests.swift     # Notification scheduling tests
└── RealityCheckUITests/                   # UI test target (Phase 2)
```

**Shared code:** `Models/` and `Shared/` are compiled into both the app target and widget target. `FormulaEngine` is pure computation with no UI dependencies — safe to share.

---

## Task 1: Xcode Project Setup

**Files:**
- Create: `RealityCheck.xcodeproj` (via Xcode CLI)
- Create: `RealityCheck/RealityCheckApp.swift`
- Create: `RealityCheck/Shared/AppGroupContainer.swift`

**Prerequisites:** Xcode 15+ installed, Apple Developer account for App Groups capability.

- [ ] **Step 1: Create Xcode project**

Open Xcode → File → New → Project → Multiplatform → App
- Product Name: `RealityCheck`
- Organization Identifier: your bundle ID prefix (e.g., `com.quannh`)
- Interface: SwiftUI
- Storage: SwiftData
- Check "Include Tests"

- [ ] **Step 2: Add App Groups capability**

In Xcode → RealityCheck target → Signing & Capabilities → + Capability → App Groups
- Add group: `group.com.quannh.realitycheck` (adjust to your bundle ID)

- [ ] **Step 3: Create AppGroupContainer.swift**

```swift
// RealityCheck/Shared/AppGroupContainer.swift
import Foundation
import SwiftData

enum AppGroupContainer {
    static let groupID = "group.com.quannh.realitycheck"

    static var url: URL {
        FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: groupID
        )!
    }

    static var modelConfiguration: ModelConfiguration {
        ModelConfiguration(
            "RealityCheck",
            url: url.appending(path: "RealityCheck.store")
        )
    }
}
```

- [ ] **Step 4: Update RealityCheckApp.swift entry point**

```swift
// RealityCheck/RealityCheckApp.swift
import SwiftUI
import SwiftData

@main
struct RealityCheckApp: App {
    var body: some Scene {
        WindowGroup {
            CardListView()
        }
        .modelContainer(try! ModelContainer(
            for: RealityCard.self,
            configurations: AppGroupContainer.modelConfiguration
        ))
    }
}
```

(This won't compile yet — `RealityCard` and `CardListView` don't exist. That's expected.)

- [ ] **Step 5: Add WidgetKit extension target**

In Xcode → File → New → Target → Widget Extension
- Product Name: `RealityCheckWidget`
- Check "Include Configuration App Intent" → NO (we use static config for Phase 1)
- Add the same App Groups capability to the widget target
- Add `RealityCard.swift`, `FormulaEngine.swift`, and `AppGroupContainer.swift` to the widget target's Compile Sources

- [ ] **Step 6: Commit**

```bash
git init
echo ".DS_Store\nbuild/\n*.xcuserstate\nxcuserdata/" > .gitignore
git add -A
git commit -m "chore: initialize Xcode project with App Groups and Widget target"
```

---

## Task 2: Data Model — RealityCard

**Files:**
- Create: `RealityCheck/Models/RealityCard.swift`
- Create: `RealityCheckTests/RealityCardTests.swift`

- [ ] **Step 1: Write failing tests for RealityCard model**

```swift
// RealityCheckTests/RealityCardTests.swift
import Testing
import Foundation
@testable import RealityCheck

@Suite("RealityCard Model")
struct RealityCardTests {

    @Test("Manual card stores value directly")
    func manualCard() {
        let card = RealityCard(
            title: "Chi phí",
            type: .manual,
            value: 15_000_000,
            unit: "triệu",
            contextLine: "chi phí cố định mỗi tháng"
        )
        #expect(card.title == "Chi phí")
        #expect(card.type == .manual)
        #expect(card.value == 15_000_000)
        #expect(card.isPinned == false)
    }

    @Test("Formula card stores inputs and formula type")
    func formulaCard() {
        let card = RealityCard(
            title: "Runway",
            type: .formula,
            formula: .divide,
            inputA: 30_000_000,
            inputALabel: "Tiết kiệm",
            inputB: 15_000_000,
            inputBLabel: "Chi phí / tháng",
            unit: "tháng",
            contextLine: "còn sống được nếu nghỉ việc"
        )
        #expect(card.type == .formula)
        #expect(card.formula == .divide)
        #expect(card.inputA == 30_000_000)
        #expect(card.inputB == 15_000_000)
    }

    @Test("Card has UUID and timestamps on creation")
    func cardMetadata() {
        let before = Date()
        let card = RealityCard(
            title: "Test",
            type: .manual,
            value: 1,
            unit: "x",
            contextLine: "test"
        )
        let after = Date()
        #expect(card.id != UUID(uuidString: "00000000-0000-0000-0000-000000000000"))
        #expect(card.createdAt >= before)
        #expect(card.createdAt <= after)
        #expect(card.updatedAt >= before)
    }
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run: Cmd+U in Xcode or `xcodebuild test -scheme RealityCheck -destination 'platform=iOS Simulator,name=iPhone 16'`
Expected: Compile error — `RealityCard` not defined

- [ ] **Step 3: Implement RealityCard model**

```swift
// RealityCheck/Models/RealityCard.swift
import Foundation
import SwiftData

enum CardType: String, Codable, CaseIterable {
    case manual
    case formula
}

enum FormulaType: String, Codable, CaseIterable {
    case divide
    case count
    case subtract
    case countdown
}

@Model
final class RealityCard {
    var id: UUID
    var title: String
    var type: CardType
    var value: Double?
    var inputA: Double?
    var inputB: Double?
    var inputALabel: String?
    var inputBLabel: String?
    var formula: FormulaType?
    var targetDate: Date?
    var unit: String
    var contextLine: String
    var isPinned: Bool
    var createdAt: Date
    var updatedAt: Date

    init(
        title: String,
        type: CardType,
        formula: FormulaType? = nil,
        value: Double? = nil,
        inputA: Double? = nil,
        inputALabel: String? = nil,
        inputB: Double? = nil,
        inputBLabel: String? = nil,
        targetDate: Date? = nil,
        unit: String,
        contextLine: String,
        isPinned: Bool = false
    ) {
        self.id = UUID()
        self.title = title
        self.type = type
        self.formula = formula
        self.value = value
        self.inputA = inputA
        self.inputALabel = inputALabel
        self.inputB = inputB
        self.inputBLabel = inputBLabel
        self.targetDate = targetDate
        self.unit = unit
        self.contextLine = contextLine
        self.isPinned = isPinned
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}
```

- [ ] **Step 4: Run tests to verify they pass**

Run: Cmd+U in Xcode
Expected: All 3 tests PASS

- [ ] **Step 5: Commit**

```bash
git add -A
git commit -m "feat: add RealityCard SwiftData model with enums"
```

---

## Task 3: FormulaEngine — Compute Display Values

**Files:**
- Create: `RealityCheck/Models/FormulaEngine.swift`
- Create: `RealityCheckTests/FormulaEngineTests.swift`

- [ ] **Step 1: Write failing tests for FormulaEngine**

```swift
// RealityCheckTests/FormulaEngineTests.swift
import Testing
import Foundation
@testable import RealityCheck

@Suite("FormulaEngine")
struct FormulaEngineTests {

    // MARK: - Manual cards

    @Test("Manual card returns value as display string")
    func manualValue() {
        let card = RealityCard(
            title: "Chi phí", type: .manual,
            value: 15_000_000, unit: "triệu",
            contextLine: "chi phí cố định"
        )
        #expect(FormulaEngine.displayValue(for: card) == "15000000")
    }

    @Test("Manual card with nil value returns --")
    func manualNilValue() {
        let card = RealityCard(
            title: "Test", type: .manual,
            value: nil, unit: "x", contextLine: "test"
        )
        #expect(FormulaEngine.displayValue(for: card) == "--")
    }

    // MARK: - Divide formula

    @Test("Divide formula computes A / B")
    func divideFormula() {
        let card = RealityCard(
            title: "Runway", type: .formula, formula: .divide,
            inputA: 30_000_000, inputB: 15_000_000,
            unit: "tháng", contextLine: "runway"
        )
        #expect(FormulaEngine.displayValue(for: card) == "2")
    }

    @Test("Divide by zero returns infinity symbol")
    func divideByZero() {
        let card = RealityCard(
            title: "Test", type: .formula, formula: .divide,
            inputA: 100, inputB: 0,
            unit: "x", contextLine: "test"
        )
        #expect(FormulaEngine.displayValue(for: card) == "∞")
    }

    // MARK: - Count formula

    @Test("Count formula returns A/B format")
    func countFormula() {
        let card = RealityCard(
            title: "Jobs", type: .formula, formula: .count,
            inputA: 1, inputB: 3,
            unit: "job", contextLine: "confirmed"
        )
        #expect(FormulaEngine.displayValue(for: card) == "1/3")
    }

    // MARK: - Subtract formula

    @Test("Subtract formula computes A - B")
    func subtractFormula() {
        let card = RealityCard(
            title: "Dư", type: .formula, formula: .subtract,
            inputA: 20_000_000, inputB: 15_000_000,
            unit: "triệu", contextLine: "dư hàng tháng"
        )
        #expect(FormulaEngine.displayValue(for: card) == "5000000")
    }

    // MARK: - Countdown formula

    @Test("Countdown formula returns days until target")
    func countdownFormula() {
        let target = Calendar.current.date(byAdding: .day, value: 12, to: Date())!
        let card = RealityCard(
            title: "Deadline", type: .formula, formula: .countdown,
            targetDate: target,
            unit: "ngày", contextLine: "đến deadline"
        )
        let result = FormulaEngine.displayValue(for: card)
        // Allow 11 or 12 depending on time of day
        #expect(result == "12" || result == "11")
    }

    @Test("Countdown past date returns 0")
    func countdownPastDate() {
        let target = Calendar.current.date(byAdding: .day, value: -5, to: Date())!
        let card = RealityCard(
            title: "Past", type: .formula, formula: .countdown,
            targetDate: target,
            unit: "ngày", contextLine: "đã qua"
        )
        #expect(FormulaEngine.displayValue(for: card) == "0")
    }

    // MARK: - Missing inputs

    @Test("Formula card with missing inputs returns --")
    func formulaMissingInputs() {
        let card = RealityCard(
            title: "Bad", type: .formula, formula: .divide,
            inputA: nil, inputB: nil,
            unit: "x", contextLine: "test"
        )
        #expect(FormulaEngine.displayValue(for: card) == "--")
    }
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run: Cmd+U
Expected: Compile error — `FormulaEngine` not defined

- [ ] **Step 3: Implement FormulaEngine**

```swift
// RealityCheck/Models/FormulaEngine.swift
import Foundation

enum FormulaEngine {

    static func displayValue(for card: RealityCard) -> String {
        switch card.type {
        case .manual:
            guard let value = card.value else { return "--" }
            return formatNumber(value)

        case .formula:
            guard let formula = card.formula else { return "--" }
            return computeFormula(formula, card: card)
        }
    }

    private static func computeFormula(_ formula: FormulaType, card: RealityCard) -> String {
        switch formula {
        case .divide:
            guard let a = card.inputA, let b = card.inputB else { return "--" }
            if b == 0 { return "∞" }
            return formatNumber(a / b)

        case .count:
            guard let a = card.inputA, let b = card.inputB else { return "--" }
            return "\(Int(a))/\(Int(b))"

        case .subtract:
            guard let a = card.inputA, let b = card.inputB else { return "--" }
            return formatNumber(a - b)

        case .countdown:
            guard let target = card.targetDate else { return "--" }
            let days = Calendar.current.dateComponents([.day], from: Date(), to: target).day ?? 0
            return "\(max(0, days))"
        }
    }

    static func formatNumber(_ value: Double) -> String {
        if value == value.rounded() && abs(value) < 1_000_000_000 {
            return "\(Int(value))"
        }
        return String(format: "%.1f", value)
    }
}
```

- [ ] **Step 4: Run tests to verify they pass**

Run: Cmd+U
Expected: All 8 tests PASS

- [ ] **Step 5: Commit**

```bash
git add -A
git commit -m "feat: add FormulaEngine with divide/count/subtract/countdown"
```

---

## Task 4: Card List View (Main Screen)

**Files:**
- Create: `RealityCheck/Views/CardListView.swift`
- Create: `RealityCheck/Views/CardRowView.swift`

- [ ] **Step 1: Implement CardRowView**

```swift
// RealityCheck/Views/CardRowView.swift
import SwiftUI

struct CardRowView: View {
    let card: RealityCard

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(FormulaEngine.displayValue(for: card))
                        .font(.system(size: 28, weight: .heavy))
                        .foregroundStyle(Color(red: 1, green: 0.267, blue: 0.267))
                    Text(card.unit)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Text(card.contextLine)
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            Spacer()
            Text(card.type.rawValue)
                .font(.caption2)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(.quaternary)
                .clipShape(RoundedRectangle(cornerRadius: 4))
        }
        .padding(.vertical, 4)
    }
}
```

- [ ] **Step 2: Implement CardListView**

```swift
// RealityCheck/Views/CardListView.swift
import SwiftUI
import SwiftData
import WidgetKit

struct CardListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \RealityCard.updatedAt, order: .reverse) private var cards: [RealityCard]
    @State private var showingCreateForm = false

    private var pinnedCard: RealityCard? {
        cards.first(where: \.isPinned)
    }

    private var unpinnedCards: [RealityCard] {
        cards.filter { !$0.isPinned }
    }

    var body: some View {
        NavigationStack {
            List {
                if let pinned = pinnedCard {
                    Section {
                        CardRowView(card: pinned)
                            .listRowBackground(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color(red: 1, green: 0.267, blue: 0.267), lineWidth: 1)
                                    .background(RoundedRectangle(cornerRadius: 8).fill(.clear))
                            )
                    } header: {
                        Label("Đang hiện trên Widget", systemImage: "pin.fill")
                    }
                }

                Section {
                    if unpinnedCards.isEmpty && pinnedCard == nil {
                        ContentUnavailableView(
                            "Chưa có Reality Card nào",
                            systemImage: "rectangle.stack.badge.plus",
                            description: Text("Tạo card đầu tiên để đối diện thực tế")
                        )
                    }
                    ForEach(unpinnedCards) { card in
                        NavigationLink(value: card) {
                            CardRowView(card: card)
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                modelContext.delete(card)
                            } label: {
                                Label("Xoá", systemImage: "trash")
                            }
                        }
                        .swipeActions(edge: .leading) {
                            Button {
                                pinCard(card)
                            } label: {
                                Label("Pin", systemImage: "pin")
                            }
                            .tint(.orange)
                        }
                    }
                } header: {
                    if pinnedCard != nil {
                        Text("Các card khác")
                    }
                }
            }
            .navigationTitle("Reality Check")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingCreateForm = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
                ToolbarItem(placement: .automatic) {
                    NavigationLink(destination: SettingsView()) {
                        Image(systemName: "gear")
                    }
                }
            }
            .navigationDestination(for: RealityCard.self) { card in
                CardFormView(card: card)
            }
            .sheet(isPresented: $showingCreateForm) {
                NavigationStack {
                    CardFormView(card: nil)
                }
            }
        }
    }

    private func pinCard(_ card: RealityCard) {
        // Unpin all other cards first
        for c in cards where c.isPinned {
            c.isPinned = false
        }
        card.isPinned = true
        card.updatedAt = Date()
        // Tell widget to refresh
        WidgetCenter.shared.reloadAllTimelines()
    }
}
```

- [ ] **Step 3: Build and verify it compiles**

Run: Cmd+B
Expected: Compile error for `CardFormView` and `SettingsView` (not yet created). Replace with placeholder:

```swift
// Temporary placeholders — remove in Task 5 & 7
struct CardFormView: View {
    var card: RealityCard?
    var body: some View { Text("TODO: CardFormView") }
}
struct SettingsView: View {
    var body: some View { Text("TODO: SettingsView") }
}
```

Build should succeed.

- [ ] **Step 4: Run on simulator, verify card list shows empty state**

Run: Cmd+R on iPhone simulator
Expected: "Reality Check" title, empty state message, "+" button in toolbar

- [ ] **Step 5: Commit**

```bash
git add -A
git commit -m "feat: add CardListView with pinned section and empty state"
```

---

## Task 5: Card Form View (Create/Edit)

**Files:**
- Create: `RealityCheck/Views/CardFormView.swift`
- Create: `RealityCheck/Views/WidgetPreviewView.swift`

- [ ] **Step 1: Implement WidgetPreviewView**

```swift
// RealityCheck/Views/WidgetPreviewView.swift
import SwiftUI

struct WidgetPreviewView: View {
    let displayValue: String
    let unit: String
    let contextLine: String

    var body: some View {
        VStack(spacing: 2) {
            Text(displayValue)
                .font(.system(size: 36, weight: .heavy))
                .foregroundStyle(Color(red: 1, green: 0.267, blue: 0.267))
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
        .frame(width: 155, height: 155)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.black)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(.quaternary)
                )
        )
    }
}
```

- [ ] **Step 2: Implement CardFormView**

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

    var body: some View {
        Form {
            Section("Thông tin") {
                TextField("Tiêu đề", text: $title)
                Picker("Loại", selection: $type) {
                    Text("Manual").tag(CardType.manual)
                    Text("Formula").tag(CardType.formula)
                }
                .pickerStyle(.segmented)
            }

            if type == .manual {
                Section("Giá trị") {
                    TextField("Giá trị", text: $value)
                        .keyboardType(.decimalPad)
                }
            } else {
                Section("Formula") {
                    Picker("Công thức", selection: $formula) {
                        Text("Chia (A ÷ B)").tag(FormulaType.divide)
                        Text("Đếm (A / B)").tag(FormulaType.count)
                        Text("Trừ (A − B)").tag(FormulaType.subtract)
                        Text("Countdown").tag(FormulaType.countdown)
                    }

                    if formula == .countdown {
                        DatePicker("Ngày đích", selection: $targetDate, displayedComponents: .date)
                    } else {
                        TextField("Tên Input A", text: $inputALabel)
                        TextField("Giá trị A", text: $inputA)
                            .keyboardType(.decimalPad)
                        TextField("Tên Input B", text: $inputBLabel)
                        TextField("Giá trị B", text: $inputB)
                            .keyboardType(.decimalPad)
                    }
                }
            }

            Section("Hiển thị") {
                TextField("Đơn vị (ngày, tháng, triệu...)", text: $unit)
                TextField("Context line", text: $contextLine)
            }

            Section("Preview") {
                HStack {
                    Spacer()
                    WidgetPreviewView(
                        displayValue: previewDisplayValue,
                        unit: unit,
                        contextLine: contextLine
                    )
                    Spacer()
                }
                .listRowBackground(Color.clear)
            }
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
                Button("Lưu") { save() }
                    .disabled(title.isEmpty || unit.isEmpty || contextLine.isEmpty)
            }
        }
        .onAppear { loadCard() }
    }

    private func loadCard() {
        guard let card else { return }
        title = card.title
        type = card.type
        value = card.value.map { "\($0)" } ?? ""
        formula = card.formula ?? .divide
        inputA = card.inputA.map { "\($0)" } ?? ""
        inputALabel = card.inputALabel ?? ""
        inputB = card.inputB.map { "\($0)" } ?? ""
        inputBLabel = card.inputBLabel ?? ""
        targetDate = card.targetDate ?? Date()
        unit = card.unit
        contextLine = card.contextLine
    }

    private func save() {
        if let card {
            // Edit existing
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
            // Create new
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

- [ ] **Step 3: Remove placeholder CardFormView from CardListView**

Delete the temporary `CardFormView` and `SettingsView` placeholder structs added in Task 4. (`SettingsView` placeholder can stay until Task 7, or create a minimal placeholder now.)

- [ ] **Step 4: Build and run on simulator**

Run: Cmd+R
Expected: Can tap "+", see form, fill in fields, see widget preview update live, save, card appears in list.

Test these flows:
1. Create a manual card → appears in list
2. Create a formula (divide) card → preview shows computed value
3. Tap a card → navigates to edit form with data pre-filled
4. Swipe left to delete
5. Swipe right to pin → card moves to pinned section

- [ ] **Step 5: Commit**

```bash
git add -A
git commit -m "feat: add CardFormView with live widget preview"
```

---

## Task 6: WidgetKit Extension

**Files:**
- Create/Modify: `RealityCheckWidget/RealityCheckWidget.swift`

**Prerequisites:** Task 2 (RealityCard model) and Task 3 (FormulaEngine) files must be added to the widget target's Compile Sources in Xcode. Also add `AppGroupContainer.swift`.

- [ ] **Step 1: Implement the widget**

```swift
// RealityCheckWidget/RealityCheckWidget.swift
import WidgetKit
import SwiftUI
import SwiftData

struct RealityCheckEntry: TimelineEntry {
    let date: Date
    let displayValue: String
    let unit: String
    let contextLine: String
    let hasCard: Bool
}

struct RealityCheckProvider: TimelineProvider {
    private var modelContext: ModelContext {
        let container = try! ModelContainer(
            for: RealityCard.self,
            configurations: AppGroupContainer.modelConfiguration
        )
        return ModelContext(container)
    }

    func placeholder(in context: Context) -> RealityCheckEntry {
        RealityCheckEntry(
            date: Date(),
            displayValue: "47",
            unit: "ngày",
            contextLine: "runway nếu nghỉ việc hôm nay",
            hasCard: true
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (RealityCheckEntry) -> Void) {
        completion(fetchEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<RealityCheckEntry>) -> Void) {
        let entry = fetchEntry()
        // Refresh every hour (countdown cards need daily updates)
        let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: Date())!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }

    private func fetchEntry() -> RealityCheckEntry {
        let descriptor = FetchDescriptor<RealityCard>(
            predicate: #Predicate { $0.isPinned == true }
        )
        guard let card = try? modelContext.fetch(descriptor).first else {
            return RealityCheckEntry(
                date: Date(),
                displayValue: "--",
                unit: "",
                contextLine: "Mở app để tạo Reality Card đầu tiên",
                hasCard: false
            )
        }
        return RealityCheckEntry(
            date: Date(),
            displayValue: FormulaEngine.displayValue(for: card),
            unit: card.unit,
            contextLine: card.contextLine,
            hasCard: true
        )
    }
}

struct RealityCheckWidgetView: View {
    let entry: RealityCheckEntry

    var body: some View {
        if entry.hasCard {
            VStack(spacing: 2) {
                Text(entry.displayValue)
                    .font(.system(size: 42, weight: .heavy))
                    .foregroundStyle(Color(red: 1, green: 0.267, blue: 0.267))
                    .minimumScaleFactor(0.5)
                Text(entry.unit.uppercased())
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.secondary)
                    .tracking(1)
                Text(entry.contextLine)
                    .font(.system(size: 10))
                    .foregroundStyle(.tertiary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .padding(.top, 2)
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

@main
struct RealityCheckWidgetBundle: Widget {
    let kind = "RealityCheckWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: RealityCheckProvider()) { entry in
            RealityCheckWidgetView(entry: entry)
                .containerBackground(.black, for: .widget)
        }
        .configurationDisplayName("Reality Check")
        .description("Hiện Reality Card trên home screen")
        .supportedFamilies([.systemSmall])
    }
}
```

- [ ] **Step 2: Build widget target**

Select the RealityCheckWidget scheme in Xcode → Cmd+B
Expected: Builds successfully

- [ ] **Step 3: Run app, create a card, pin it, add widget to home screen**

1. Run app on simulator (Cmd+R)
2. Create a card (e.g., "Runway", divide, 30000000 / 15000000, unit "tháng")
3. Swipe right on card → Pin
4. Go to home screen → long press → add widget → find "Reality Check" → add small widget
5. Widget should show the pinned card's value

- [ ] **Step 4: Verify widget updates when data changes**

1. Edit the pinned card's inputA to a different value
2. Save
3. Widget should refresh within seconds (due to `reloadAllTimelines()`)

- [ ] **Step 5: Commit**

```bash
git add -A
git commit -m "feat: add WidgetKit extension showing pinned Reality Card"
```

---

## Task 7: Settings View + Notifications

**Files:**
- Create: `RealityCheck/Views/SettingsView.swift`
- Create: `RealityCheck/Services/NotificationService.swift`
- Create: `RealityCheckTests/NotificationServiceTests.swift`

- [ ] **Step 1: Write failing tests for NotificationService**

```swift
// RealityCheckTests/NotificationServiceTests.swift
import Testing
import Foundation
@testable import RealityCheck

@Suite("NotificationService")
struct NotificationServiceTests {

    @Test("Notification content includes card value and context")
    func notificationContent() {
        let card = RealityCard(
            title: "Runway", type: .formula, formula: .divide,
            inputA: 30_000_000, inputB: 15_000_000,
            unit: "tháng", contextLine: "còn sống được nếu nghỉ việc"
        )
        let content = NotificationService.buildContent(for: card)
        #expect(content.title == "Reality Check")
        #expect(content.body.contains("2"))
        #expect(content.body.contains("còn sống được nếu nghỉ việc"))
    }

    @Test("Notification content for nil card shows prompt")
    func notificationContentNoCard() {
        let content = NotificationService.buildContent(for: nil)
        #expect(content.body.contains("Reality Card"))
    }

    @Test("Trigger is daily at specified hour and minute")
    func dailyTrigger() {
        let trigger = NotificationService.buildDailyTrigger(hour: 8, minute: 30)
        #expect(trigger.dateComponents.hour == 8)
        #expect(trigger.dateComponents.minute == 30)
        #expect(trigger.repeats == true)
    }
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run: Cmd+U
Expected: Compile error — `NotificationService` not defined

- [ ] **Step 3: Implement NotificationService**

```swift
// RealityCheck/Services/NotificationService.swift
import Foundation
import UserNotifications

enum NotificationService {
    static let dailyReminderID = "daily-reality-check"

    static func buildContent(for card: RealityCard?) -> UNMutableNotificationContent {
        let content = UNMutableNotificationContent()
        content.title = "Reality Check"
        if let card {
            let value = FormulaEngine.displayValue(for: card)
            content.body = "\(value) \(card.unit) — \(card.contextLine)"
        } else {
            content.body = "Mở app để tạo Reality Card đầu tiên"
        }
        content.sound = .default
        return content
    }

    static func buildDailyTrigger(hour: Int, minute: Int) -> UNCalendarNotificationTrigger {
        var components = DateComponents()
        components.hour = hour
        components.minute = minute
        return UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
    }

    static func scheduleDailyNotification(
        for card: RealityCard?,
        hour: Int,
        minute: Int
    ) {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [dailyReminderID])

        let content = buildContent(for: card)
        let trigger = buildDailyTrigger(hour: hour, minute: minute)
        let request = UNNotificationRequest(
            identifier: dailyReminderID,
            content: content,
            trigger: trigger
        )
        center.add(request)
    }

    static func cancelDailyNotification() {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: [dailyReminderID])
    }

    static func requestPermission() {
        UNUserNotificationCenter.current()
            .requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }
}
```

- [ ] **Step 4: Run tests to verify they pass**

Run: Cmd+U
Expected: All 3 notification tests PASS

- [ ] **Step 5: Implement SettingsView**

```swift
// RealityCheck/Views/SettingsView.swift
import SwiftUI
import SwiftData

struct SettingsView: View {
    @AppStorage("notificationEnabled") private var notificationEnabled = true
    @AppStorage("notificationHour") private var notificationHour = 8
    @AppStorage("notificationMinute") private var notificationMinute = 0

    @Query(filter: #Predicate<RealityCard> { $0.isPinned == true })
    private var pinnedCards: [RealityCard]

    private var notificationTime: Binding<Date> {
        Binding(
            get: {
                Calendar.current.date(from: DateComponents(
                    hour: notificationHour,
                    minute: notificationMinute
                )) ?? Date()
            },
            set: { newDate in
                let components = Calendar.current.dateComponents([.hour, .minute], from: newDate)
                notificationHour = components.hour ?? 8
                notificationMinute = components.minute ?? 0
                updateNotification()
            }
        )
    }

    var body: some View {
        Form {
            Section("Thông báo hàng ngày") {
                Toggle("Bật thông báo", isOn: $notificationEnabled)
                    .onChange(of: notificationEnabled) { _, enabled in
                        if enabled {
                            NotificationService.requestPermission()
                            updateNotification()
                        } else {
                            NotificationService.cancelDailyNotification()
                        }
                    }

                if notificationEnabled {
                    DatePicker(
                        "Thời gian nhắc",
                        selection: notificationTime,
                        displayedComponents: .hourAndMinute
                    )
                }
            }
        }
        .navigationTitle("Cài đặt")
        .onAppear {
            if notificationEnabled {
                NotificationService.requestPermission()
            }
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

- [ ] **Step 6: Remove SettingsView placeholder** (if still exists from Task 4)

- [ ] **Step 7: Build and test on simulator**

Run: Cmd+R
Expected: Settings gear icon → Settings screen → toggle and time picker work

- [ ] **Step 8: Commit**

```bash
git add -A
git commit -m "feat: add Settings screen with daily notification scheduling"
```

---

## Task 8: macOS Support

**Files:**
- Modify: `RealityCheck.xcodeproj` (add macOS destination)

- [ ] **Step 1: Add macOS destination**

In Xcode → RealityCheck target → General → Supported Destinations → add "macOS". Use **native multiplatform** (not Mac Catalyst) — Mac Catalyst adds UIKit compatibility shims that can complicate SwiftData container paths.

Also ensure the widget target supports macOS:
- RealityCheckWidget target → General → Supported Destinations → add "macOS"

- [ ] **Step 2: Add App Groups to macOS**

Ensure App Groups capability is added for macOS signing as well (same group ID).

- [ ] **Step 3: Build for macOS**

Select "My Mac" as destination → Cmd+B
Expected: Should compile. Fix any platform-specific issues if they arise (e.g., `UIKit` references — there shouldn't be any since we use SwiftUI throughout).

- [ ] **Step 4: Run on macOS, verify app + widget**

Run on Mac → verify:
1. App opens, CRUD works
2. Can add widget to macOS Notification Center / Desktop

- [ ] **Step 5: Commit**

```bash
git add -A
git commit -m "feat: add macOS support for app and widget"
```

---

## Task 9: Polish & Final Verification

**Files:**
- Modify: various views for edge case handling

- [ ] **Step 1: Request notification permission on first launch**

In `RealityCheckApp.swift`, add:
```swift
.onAppear {
    NotificationService.requestPermission()
}
```
to the `WindowGroup` content.

- [ ] **Step 2: Verify all error states from spec**

Test on simulator:
1. **No card pinned** → widget shows "Mở app để tạo Reality Card đầu tiên" ✓
2. **Division by zero** → create divide card with B = 0 → shows "∞" ✓
3. **Countdown past date** → create countdown card with past date → shows "0" ✓
4. **Empty card list** → shows ContentUnavailableView ✓

- [ ] **Step 3: Run all unit tests**

Run: Cmd+U
Expected: All tests pass (RealityCardTests, FormulaEngineTests, NotificationServiceTests)

- [ ] **Step 4: Final commit**

```bash
git add -A
git commit -m "chore: polish error states and notification permission flow"
```

- [ ] **Step 5: Tag release**

```bash
git tag v0.1.0 -m "Phase 1: Reality Check app with Reality Cards and widget"
```
