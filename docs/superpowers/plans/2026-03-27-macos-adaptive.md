# macOS Adaptive Support Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Mở rộng Reality Check thành Mac Catalyst app với MenuBarExtra (status bar popover), NavigationSplitView master-detail layout, và background agent lifecycle.

**Architecture:** Dùng Mac Catalyst — một codebase duy nhất cho iOS và macOS. `NavigationSplitView` tự collapse về single-column trên iOS. `MenuBarExtra` và `AppDelegate` được guard bằng `#if targetEnvironment(macCatalyst)`. `AppState` (@Observable) truyền signal từ menu bar vào main window.

**Tech Stack:** SwiftUI, SwiftData, WidgetKit, Swift Testing. Target deployment: iOS 26.2 / macOS 26.2.

---

## File Map

### New files
| File | Responsibility |
|------|----------------|
| `RealityCheck/App/AppState.swift` | Observable signal object — pendingAction từ menu bar vào sidebar |
| `RealityCheck/App/AppDelegate.swift` | macOS-only: ngăn app terminate khi đóng window |
| `RealityCheck/Views/CardSidebarView.swift` | Sidebar list (refactor từ CardListView), nhận `selection: Binding<RealityCard?>` |
| `RealityCheck/Views/CardDetailView.swift` | Detail column: hiện CardFormView hoặc placeholder |
| `RealityCheck/Views/MenuBarCardView.swift` | Menu bar popover: pinned card + actions |
| `RealityCheck/Previews/PreviewSampleData.swift` | Mock cards dùng chung cho previews |
| `RealityCheck/Previews/CardSidebarView+Preview.swift` | Preview CardSidebarView |
| `RealityCheck/Previews/CardDetailView+Preview.swift` | Preview CardDetailView (có card + nil) |
| `RealityCheck/Previews/MenuBarCardView+Preview.swift` | Preview MenuBarCardView (có card + nil) |

### Modified files
| File | Changes |
|------|---------|
| `RealityCheck/App/RealityCheckApp.swift` | Extract sharedContainer, thêm NavigationSplitView, MenuBarExtra, AppDelegate adaptor |
| `RealityCheck/Views/CardFormView.swift` | Wrap iOS-only modifiers trong `#if os(iOS)` |
| `RealityCheck/Views/CardListView.swift` | Xóa (logic đã chuyển sang CardSidebarView) |

### Build settings
- Thêm `INFOPLIST_KEY_LSUIElement = YES` vào build settings của target `RealityCheck`

---

## Task 1: AppState và AppDelegate

**Files:**
- Create: `RealityCheck/App/AppState.swift`
- Create: `RealityCheck/App/AppDelegate.swift`

- [ ] **Step 1: Tạo AppState.swift**

```swift
// RealityCheck/App/AppState.swift
import SwiftUI

@Observable
final class AppState {
    enum PendingAction {
        case none
        case openCreateForm
    }

    var pendingAction: PendingAction = .none
}
```

- [ ] **Step 2: Tạo AppDelegate.swift**

```swift
// RealityCheck/App/AppDelegate.swift
#if targetEnvironment(macCatalyst)
import UIKit

class AppDelegate: NSObject, UIApplicationDelegate {
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: UIApplication) -> Bool {
        return false
    }
}
#endif
```

- [ ] **Step 3: Build để xác nhận không có lỗi**

```bash
xcodebuild build \
  -scheme RealityCheck \
  -project RealityCheck.xcodeproj \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  2>&1 | grep -E "error:|BUILD"
```

Expected: `BUILD SUCCEEDED` (không có error)

- [ ] **Step 4: Commit**

```bash
git add RealityCheck/App/AppState.swift RealityCheck/App/AppDelegate.swift
git commit -m "feat: add AppState observable and macOS AppDelegate"
```

---

## Task 2: Tạo CardSidebarView từ CardListView

`CardSidebarView` là refactor của `CardListView` — thêm `selection: Binding<RealityCard?>` để drive `NavigationSplitView` detail column. Logic list giữ nguyên hoàn toàn.

**Files:**
- Create: `RealityCheck/Views/CardSidebarView.swift`
- Delete: `RealityCheck/Views/CardListView.swift`

- [ ] **Step 1: Tạo CardSidebarView.swift**

```swift
// RealityCheck/Views/CardSidebarView.swift
import SwiftUI
import SwiftData

struct CardSidebarView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(AppState.self) private var appState
    @Query(sort: \RealityCard.updatedAt, order: .reverse) private var cards: [RealityCard]
    @Binding var selection: RealityCard?
    @State private var viewModel = CardListViewModel()
    @State private var showingCreateForm = false
    @State private var appeared = false
    @State private var cardToDelete: RealityCard? = nil
    @Namespace private var namespace

    private var pinnedCard: RealityCard? { cards.first(where: \.isPinned) }
    private var unpinnedCards: [RealityCard] { cards.filter { !$0.isPinned } }

    var body: some View {
        NavigationStack {
            List {
                if cards.isEmpty {
                    emptyState
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                        .listRowInsets(EdgeInsets(top: 5, leading: 16, bottom: 5, trailing: 16))
                } else {
                    cardContent
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .padding(.top, 8)
            .padding(.bottom, 24)
            .navigationTitle(String(localized: "app.title"))
            #if os(iOS)
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(.hidden, for: .navigationBar)
            #endif
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink(destination: SettingsView()) {
                        Image(systemName: "gearshape")
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showingCreateForm = true } label: {
                        Image(systemName: "plus")
                            .fontWeight(.semibold)
                    }
                }
            }
            .sheet(isPresented: $showingCreateForm) {
                NavigationStack { CardFormView(card: nil) }
            }
            .alert(String(localized: "card.list.alert.delete.title"), isPresented: Binding(
                get: { cardToDelete != nil },
                set: { if !$0 { cardToDelete = nil } }
            )) {
                Button(String(localized: "card.list.action.delete"), role: .destructive) {
                    if let card = cardToDelete {
                        viewModel.deleteCard(card, context: modelContext)
                    }
                }
                Button(String(localized: "card.form.action.cancel"), role: .cancel) { cardToDelete = nil }
            } message: {
                Text("card.list.alert.delete.message")
            }
        }
        .background(.clear)
        .onAppear {
            withAnimation(.spring(duration: 0.4)) { appeared = true }
        }
        .onChange(of: appState.pendingAction) { _, newValue in
            if newValue == .openCreateForm {
                showingCreateForm = true
                appState.pendingAction = .none
            }
        }
    }

    // MARK: - Card content

    @ViewBuilder
    private var cardContent: some View {
        if let pinned = pinnedCard {
            SectionLabel(String(localized: "card.list.section.pinned"))
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 8)
                .animation(.spring(duration: 0.4), value: appeared)
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets(top: 5, leading: 16, bottom: 5, trailing: 16))

            Button {
                selection = pinned
            } label: {
                GlassCard(card: pinned, style: .pinned)
            }
            .buttonStyle(.plain)
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 8)
            .animation(.spring(duration: 0.4).delay(0.06), value: appeared)
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
            .listRowInsets(EdgeInsets(top: 5, leading: 16, bottom: 5, trailing: 16))
            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                Button(role: .destructive) {
                    cardToDelete = pinned
                } label: {
                    Label(String(localized: "card.list.action.delete"), systemImage: "trash")
                }
                Button {
                    viewModel.unpinCard(pinned, context: modelContext)
                } label: {
                    Label(String(localized: "card.list.action.unpin"), systemImage: "pin.slash")
                }
                .tint(.auroraYellow)
            }
        }

        if !unpinnedCards.isEmpty {
            if pinnedCard != nil {
                SectionLabel(String(localized: "card.list.section.all"))
                    .padding(.top, 4)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 8)
                    .animation(.spring(duration: 0.4).delay(0.03), value: appeared)
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                    .listRowInsets(EdgeInsets(top: 5, leading: 16, bottom: 5, trailing: 16))
            }

            ForEach(Array(unpinnedCards.enumerated()), id: \.element.id) { index, card in
                Button {
                    selection = card
                } label: {
                    GlassCard(card: card, style: .unpinned)
                }
                .buttonStyle(.plain)
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 10)
                .animation(
                    .spring(duration: 0.4).delay(Double(index + 1) * 0.06),
                    value: appeared
                )
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets(top: 5, leading: 16, bottom: 5, trailing: 16))
                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                    Button(role: .destructive) {
                        cardToDelete = card
                    } label: {
                        Label(String(localized: "card.list.action.delete"), systemImage: "trash")
                    }
                    Button {
                        viewModel.pinCard(card, from: cards, context: modelContext)
                    } label: {
                        Label(String(localized: "card.list.action.pin.short"), systemImage: "pin")
                    }
                    .tint(.auroraGreen)
                }
            }
        }
    }

    // MARK: - Empty state

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "rectangle.stack.badge.plus")
                .font(.system(size: 40))
                .foregroundStyle(.primary)
                .padding(.top, 60)

            Text("card.list.empty.headline")
                .font(.headline)
                .foregroundStyle(.primary)

            Text("card.list.empty.subheadline")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            GlassButton(String(localized: "card.list.empty.cta"), style: .primary) {
                showingCreateForm = true
            }
            .padding(.top, 4)
        }
        .frame(maxWidth: .infinity)
    }
}
```

**Lưu ý quan trọng về navigation:** `CardSidebarView` dùng `Button { selection = card }` thay cho `NavigationLink` — vì trong `NavigationSplitView`, tap vào sidebar item cần update `selection` binding để drive detail column, không phải push vào NavigationStack. `NavigationLink(destination:)` vẫn dùng cho Settings (vì nó push trong sidebar stack, không phải detail column).

- [ ] **Step 2: Xóa CardListView.swift**

```bash
rm RealityCheck/Views/CardListView.swift
```

Vì target dùng `PBXFileSystemSynchronizedRootGroup`, Xcode tự sync — không cần chỉnh project.pbxproj.

- [ ] **Step 3: Build để xác nhận không có lỗi**

```bash
xcodebuild build \
  -scheme RealityCheck \
  -project RealityCheck.xcodeproj \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  2>&1 | grep -E "error:|BUILD"
```

Expected: `BUILD SUCCEEDED`

- [ ] **Step 4: Commit**

```bash
git add RealityCheck/Views/CardSidebarView.swift
git rm RealityCheck/Views/CardListView.swift
git commit -m "feat: extract CardSidebarView from CardListView with selection binding"
```

---

## Task 3: Tạo CardDetailView và fix CardFormView

**Files:**
- Create: `RealityCheck/Views/CardDetailView.swift`
- Modify: `RealityCheck/Views/CardFormView.swift`

- [ ] **Step 1: Tạo CardDetailView.swift**

```swift
// RealityCheck/Views/CardDetailView.swift
import SwiftUI

struct CardDetailView: View {
    let selection: RealityCard?

    var body: some View {
        if let card = selection {
            CardFormView(card: card)
        } else {
            emptyPlaceholder
        }
    }

    private var emptyPlaceholder: some View {
        VStack(spacing: 12) {
            Image(systemName: "rectangle.on.rectangle")
                .font(.system(size: 36))
                .foregroundStyle(.tertiary)
            Text("card.detail.placeholder")
                .font(.subheadline)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
```

- [ ] **Step 2: Thêm localization key cho placeholder**

Mở `RealityCheck/Localizable.xcstrings`, thêm key `"card.detail.placeholder"`:
- Tiếng Việt: `"Chọn một card để xem"`
- English: `"Select a card to view"`

- [ ] **Step 3: Fix iOS-only modifiers trong CardFormView.swift**

Trong `RealityCheck/Views/CardFormView.swift`, tìm 2 dòng trong `body`:
```swift
.navigationBarTitleDisplayMode(.inline)
```

Dòng này ổn trên Catalyst — giữ nguyên. Không có modifier nào khác cần fix trong `CardFormView` (`.toolbar` với `.cancellationAction`/`.confirmationAction` hoạt động trên cả hai platform).

Không cần thay đổi `CardFormView.swift`.

- [ ] **Step 4: Build để xác nhận**

```bash
xcodebuild build \
  -scheme RealityCheck \
  -project RealityCheck.xcodeproj \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  2>&1 | grep -E "error:|BUILD"
```

Expected: `BUILD SUCCEEDED`

- [ ] **Step 5: Commit**

```bash
git add RealityCheck/Views/CardDetailView.swift
git commit -m "feat: add CardDetailView for NavigationSplitView detail column"
```

---

## Task 4: Refactor RealityCheckApp — NavigationSplitView + AppDelegate

**Files:**
- Modify: `RealityCheck/App/RealityCheckApp.swift`

- [ ] **Step 1: Thay thế toàn bộ nội dung RealityCheckApp.swift**

```swift
// RealityCheck/App/RealityCheckApp.swift
import SwiftUI
import SwiftData
#if DEBUG
import DebugSwift
#endif

@main
struct RealityCheckApp: App {
    #if targetEnvironment(macCatalyst)
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    #endif

    @State private var selectedCard: RealityCard?
    @State private var columnVisibility: NavigationSplitViewVisibility = .automatic
    @State private var appState = AppState()

    private let sharedContainer: ModelContainer = {
        try! ModelContainer(
            for: RealityCard.self,
            configurations: AppGroupContainer.modelConfiguration
        )
    }()

    init() {
        NotificationService.requestPermission()
        #if DEBUG
        setupDebugSwift()
        #endif
    }

    var body: some Scene {
        WindowGroup(id: "main") {
            ZStack {
                AuroraBackground()
                NavigationSplitView(columnVisibility: $columnVisibility) {
                    CardSidebarView(selection: $selectedCard)
                } detail: {
                    CardDetailView(selection: selectedCard)
                }
            }
            .preferredColorScheme(.dark)
            .environment(appState)
        }
        .modelContainer(sharedContainer)

        #if targetEnvironment(macCatalyst)
        MenuBarExtra("Reality Check", systemImage: "pin.circle.fill") {
            MenuBarCardView()
                .modelContainer(sharedContainer)
                .environment(appState)
        }
        .menuBarExtraStyle(.window)
        #endif
    }

    #if DEBUG
    @MainActor
    private func setupDebugSwift() {
        guard ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] != "1" else { return }
        DebugSwift().setup().show()
    }
    #endif
}
```

**Lưu ý:** `MenuBarCardView` chưa tồn tại — sẽ tạo ở Task 5. Build sẽ fail ở bước này nếu compile cả Catalyst target. Bước build sau khi hoàn thành Task 5.

- [ ] **Step 2: Commit (chưa build)**

```bash
git add RealityCheck/App/RealityCheckApp.swift
git commit -m "feat: refactor App to NavigationSplitView with MenuBarExtra scene"
```

---

## Task 5: Tạo MenuBarCardView

**Files:**
- Create: `RealityCheck/Views/MenuBarCardView.swift`

- [ ] **Step 1: Tạo MenuBarCardView.swift**

```swift
// RealityCheck/Views/MenuBarCardView.swift
import SwiftUI
import SwiftData
#if targetEnvironment(macCatalyst)
import UIKit
#endif

struct MenuBarCardView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.openWindow) private var openWindow
    @Query(filter: #Predicate<RealityCard> { $0.isPinned }) private var pinnedCards: [RealityCard]

    private var pinnedCard: RealityCard? { pinnedCards.first }

    var body: some View {
        ZStack {
            AuroraBackground()
            VStack(spacing: 0) {
                cardSection
                Divider()
                    .opacity(0.2)
                actionSection
            }
        }
        .frame(width: 320)
        .preferredColorScheme(.dark)
    }

    // MARK: - Card section

    private var cardSection: some View {
        Group {
            if let card = pinnedCard {
                GlassCard(card: card, style: .pinned)
                    .padding(16)
            } else {
                VStack(spacing: 10) {
                    Image(systemName: "pin.slash")
                        .font(.system(size: 28))
                        .foregroundStyle(.tertiary)
                    Text("menubar.empty")
                        .font(.subheadline)
                        .foregroundStyle(.tertiary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 32)
                .padding(.horizontal, 16)
            }
        }
    }

    // MARK: - Action section

    private var actionSection: some View {
        HStack {
            Button {
                openWindow(id: "main")
            } label: {
                Label("menubar.action.open", systemImage: "macwindow")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
            }
            .buttonStyle(.plain)

            Divider()
                .frame(height: 20)
                .opacity(0.2)

            Button {
                openWindow(id: "main")
                appState.pendingAction = .openCreateForm
            } label: {
                Label("menubar.action.add", systemImage: "plus")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
            }
            .buttonStyle(.plain)

            Divider()
                .frame(height: 20)
                .opacity(0.2)

            Button {
                #if targetEnvironment(macCatalyst)
                (UIApplication.shared.delegate as? AppDelegate)
                // AppDelegate không expose quit — dùng exit trực tiếp
                #endif
                exit(0)
            } label: {
                Label("menubar.action.quit", systemImage: "power")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 8)
    }
}
```

- [ ] **Step 2: Thêm localization keys**

Trong `Localizable.xcstrings`, thêm các key:
- `"menubar.empty"` → VI: `"Chưa có card nào được ghim"` / EN: `"No card pinned"`
- `"menubar.action.open"` → VI: `"Mở app"` / EN: `"Open app"`
- `"menubar.action.add"` → VI: `"Thêm card"` / EN: `"Add card"`
- `"menubar.action.quit"` → VI: `"Thoát"` / EN: `"Quit"`
- `"card.detail.placeholder"` → VI: `"Chọn một card để xem"` / EN: `"Select a card to view"` (nếu chưa thêm ở Task 3)

- [ ] **Step 3: Build iOS để xác nhận không có lỗi**

```bash
xcodebuild build \
  -scheme RealityCheck \
  -project RealityCheck.xcodeproj \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  2>&1 | grep -E "error:|BUILD"
```

Expected: `BUILD SUCCEEDED`

- [ ] **Step 4: Commit**

```bash
git add RealityCheck/Views/MenuBarCardView.swift
git commit -m "feat: add MenuBarCardView with pinned card and quick actions"
```

---

## Task 6: Background agent lifecycle — LSUIElement

**Files:**
- Modify: Build settings của target `RealityCheck` (qua Xcode UI hoặc pbxproj)

- [ ] **Step 1: Thêm LSUIElement vào build settings**

Mở Xcode → target `RealityCheck` → tab `Build Settings` → search `"INFOPLIST_KEY"`.

Click nút `+` để thêm User-Defined Setting:
- Key: `INFOPLIST_KEY_LSUIElement`
- Value: `YES`

Hoặc chỉnh trực tiếp trong `project.pbxproj` — trong section build settings của target `RealityCheck`, thêm dòng:
```
INFOPLIST_KEY_LSUIElement = YES;
```

Trên iOS key này bị ignore hoàn toàn. Trên macOS Catalyst, app sẽ không hiện trong Dock.

- [ ] **Step 2: Build để xác nhận**

```bash
xcodebuild build \
  -scheme RealityCheck \
  -project RealityCheck.xcodeproj \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  2>&1 | grep -E "error:|BUILD"
```

Expected: `BUILD SUCCEEDED`

- [ ] **Step 3: Commit**

```bash
git add RealityCheck.xcodeproj/project.pbxproj
git commit -m "feat: add LSUIElement to suppress Dock icon on macOS"
```

---

## Task 7: Unit test AppState

**Files:**
- Modify: `RealityCheckTests/RealityCheckTests.swift` (hoặc tạo `RealityCheckTests/AppStateTests.swift`)

- [ ] **Step 1: Viết failing test**

Tạo `RealityCheckTests/AppStateTests.swift`:

```swift
// RealityCheckTests/AppStateTests.swift
import Testing
@testable import RealityCheck

@Suite("AppState")
struct AppStateTests {

    @Test("pendingAction starts as none")
    func initialState() {
        let state = AppState()
        #expect(state.pendingAction == .none)
    }

    @Test("pendingAction transitions to openCreateForm then back to none")
    func pendingActionCycle() {
        let state = AppState()
        state.pendingAction = .openCreateForm
        #expect(state.pendingAction == .openCreateForm)
        state.pendingAction = .none
        #expect(state.pendingAction == .none)
    }
}
```

- [ ] **Step 2: Chạy test để xác nhận pass**

```bash
xcodebuild test \
  -scheme RealityCheck \
  -project RealityCheck.xcodeproj \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -only-testing:RealityCheckTests/AppStateTests \
  2>&1 | grep -E "passed|failed|error:|Test Suite"
```

Expected: `Test Suite 'AppStateTests' passed`

- [ ] **Step 3: Commit**

```bash
git add RealityCheckTests/AppStateTests.swift
git commit -m "test: add AppState pending action transition tests"
```

---

## Task 8: Previews

**Files:**
- Create: `RealityCheck/Previews/PreviewSampleData.swift`
- Create: `RealityCheck/Previews/CardSidebarView+Preview.swift`
- Create: `RealityCheck/Previews/CardDetailView+Preview.swift`
- Create: `RealityCheck/Previews/MenuBarCardView+Preview.swift`

- [ ] **Step 1: Tạo PreviewSampleData.swift**

```swift
// RealityCheck/Previews/PreviewSampleData.swift
import SwiftData
import Foundation

@MainActor
let previewContainer: ModelContainer = {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: RealityCard.self, configurations: config)

    let pinned = RealityCard(
        title: "Chi phí tháng này",
        type: .manual,
        value: 4_200_000,
        unit: "đ",
        contextLine: "so với tháng trước",
        isPinned: true
    )

    let countdown = RealityCard(
        title: "Deadline project",
        type: .formula,
        formula: .countdown,
        targetDate: Calendar.current.date(byAdding: .day, value: 14, to: Date()),
        unit: "ngày",
        contextLine: "còn lại"
    )

    let unpinned = RealityCard(
        title: "Tỉ lệ hoàn thành",
        type: .formula,
        formula: .divide,
        inputA: 7,
        inputALabel: "task xong",
        inputB: 10,
        inputBLabel: "tổng task",
        unit: "%",
        contextLine: "sprint hiện tại"
    )

    container.mainContext.insert(pinned)
    container.mainContext.insert(countdown)
    container.mainContext.insert(unpinned)
    return container
}()
```

- [ ] **Step 2: Tạo CardSidebarView+Preview.swift**

```swift
// RealityCheck/Previews/CardSidebarView+Preview.swift
import SwiftUI

#Preview("Sidebar — with cards") {
    ZStack {
        AuroraBackground()
        CardSidebarView(selection: .constant(nil))
    }
    .preferredColorScheme(.dark)
    .modelContainer(previewContainer)
    .environment(AppState())
}

#Preview("Sidebar — empty") {
    ZStack {
        AuroraBackground()
        CardSidebarView(selection: .constant(nil))
    }
    .preferredColorScheme(.dark)
    .modelContainer(try! ModelContainer(for: RealityCard.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true)))
    .environment(AppState())
}
```

- [ ] **Step 3: Tạo CardDetailView+Preview.swift**

```swift
// RealityCheck/Previews/CardDetailView+Preview.swift
import SwiftUI

#Preview("Detail — with card") {
    ZStack {
        AuroraBackground()
        CardDetailView(selection: RealityCard(
            title: "Chi phí", type: .manual,
            value: 4_200_000, unit: "đ",
            contextLine: "tháng này"
        ))
    }
    .preferredColorScheme(.dark)
    .modelContainer(previewContainer)
}

#Preview("Detail — empty placeholder") {
    ZStack {
        AuroraBackground()
        CardDetailView(selection: nil)
    }
    .preferredColorScheme(.dark)
    .modelContainer(previewContainer)
}
```

- [ ] **Step 4: Tạo MenuBarCardView+Preview.swift**

```swift
// RealityCheck/Previews/MenuBarCardView+Preview.swift
import SwiftUI

#Preview("MenuBar — with pinned card") {
    MenuBarCardView()
        .modelContainer(previewContainer)
        .environment(AppState())
}

#Preview("MenuBar — no pinned card") {
    MenuBarCardView()
        .modelContainer(try! ModelContainer(for: RealityCard.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true)))
        .environment(AppState())
}
```

- [ ] **Step 5: Build để xác nhận**

```bash
xcodebuild build \
  -scheme RealityCheck \
  -project RealityCheck.xcodeproj \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  2>&1 | grep -E "error:|BUILD"
```

Expected: `BUILD SUCCEEDED`

- [ ] **Step 6: Commit**

```bash
git add RealityCheck/Previews/PreviewSampleData.swift \
        RealityCheck/Previews/CardSidebarView+Preview.swift \
        RealityCheck/Previews/CardDetailView+Preview.swift \
        RealityCheck/Previews/MenuBarCardView+Preview.swift
git commit -m "feat: add previews for sidebar, detail, and menu bar views"
```

---

## Task 9: Full build và manual verification

- [ ] **Step 1: Chạy full test suite**

```bash
xcodebuild test \
  -scheme RealityCheck \
  -project RealityCheck.xcodeproj \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  2>&1 | grep -E "passed|failed|error:|BUILD"
```

Expected: tất cả tests pass, `BUILD SUCCEEDED`

- [ ] **Step 2: Manual checklist iOS**

Chạy app trên iOS Simulator:
- [ ] List cards hiển thị đúng (pinned ở trên, unpinned bên dưới)
- [ ] Tap card → CardFormView mở trong detail (hoặc navigate trên iOS)
- [ ] Nút "+" → sheet tạo card mới
- [ ] Swipe actions: pin, unpin, delete hoạt động

- [ ] **Step 3: Manual checklist macOS (nếu có Mac Catalyst build target)**

Chạy trên "My Mac (Mac Catalyst)":
- [ ] Main window: sidebar bên trái, detail bên phải
- [ ] Click card trong sidebar → form hiện bên phải
- [ ] Menu bar icon xuất hiện ở status bar
- [ ] Click icon → popover hiện pinned card (hoặc empty state)
- [ ] Nút "Mở app" → cửa sổ chính xuất hiện
- [ ] Nút "Thêm card" → cửa sổ chính mở + create sheet xuất hiện
- [ ] Nút "Thoát" → app thoát hoàn toàn
- [ ] Đóng main window → app vẫn còn ở menu bar (không terminate)
- [ ] App không hiện trong Dock khi đang chạy

---

## Self-Review Checklist

**Spec coverage:**
- [x] MenuBarExtra với pinned card + actions → Task 5
- [x] NavigationSplitView master-detail → Task 4
- [x] Background agent (`applicationShouldTerminateAfterLastWindowClosed`) → Task 1 (AppDelegate)
- [x] `LSUIElement` → Task 6
- [x] `AppState` signal → Task 1 + Task 2 (onChange) + Task 5 (pendingAction set)
- [x] `sharedContainer` extract → Task 4
- [x] Previews → Task 8
- [x] Unit test AppState → Task 7
- [x] iOS-only modifier guards → Task 2 (CardSidebarView)

**Type consistency:**
- `AppState.PendingAction`: `.none`, `.openCreateForm` — dùng nhất quán trong Task 1, 2, 5, 7
- `CardSidebarView(selection: $selectedCard)` — `selection: Binding<RealityCard?>` — nhất quán
- `CardDetailView(selection: selectedCard)` — `selection: RealityCard?` — nhất quán
- `sharedContainer` — defined và dùng trong Task 4, pass vào Task 5
