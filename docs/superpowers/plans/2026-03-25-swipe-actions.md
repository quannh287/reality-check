# Swipe Actions on Card List — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the long-press context menu on card rows with swipe-left (trailing edge) actions: pin/unpin and delete, where delete shows a confirmation alert.

**Architecture:** Migrate `CardListView` from `ScrollView + VStack` to `List` (required for `.swipeActions`), add swipe actions per-row with distinct buttons for pinned vs. unpinned cards, add `unpinCard` to `CardListViewModel`. All changes isolated in a git worktree on `feature/swipe-actions`.

**Tech Stack:** SwiftUI (`.swipeActions`, `.alert`, `List`), SwiftData (`@Query`, `ModelContext`), Swift Testing (`@Suite`, `@Test`, `#expect`), WidgetKit (`WidgetCenter`).

**Spec:** `docs/superpowers/specs/2026-03-25-swipe-actions-design.md`

---

## File Map

| File | Change |
|------|--------|
| `RealityCheck/ViewModels/CardListViewModel.swift` | Add `unpinCard(_ card:context:)` method |
| `RealityCheck/Views/CardListView.swift` | Migrate to `List`, add `.swipeActions`, remove `.contextMenu`, add delete alert |
| `RealityCheckTests/RealityCheckTests.swift` | Append `CardListViewModelTests` suite (already registered in project — no new file needed) |

No new files are created. The test suite is appended to the existing boilerplate `RealityCheckTests.swift` which is already a member of the `RealityCheckTests` target.

---

## Task 1: Set up git worktree

**Files:** none — git setup only

- [ ] **Step 1: Create worktree**

Run from project root:
```bash
git worktree add worktrees/feature-swipe-actions -b feature/swipe-actions
```

Expected output: `Preparing worktree (new branch 'feature/swipe-actions')`

- [ ] **Step 2: Verify worktree**

```bash
git worktree list
```

Expected: two entries — project root on `main`, and `worktrees/feature-swipe-actions` on `feature/swipe-actions`.

> All subsequent steps are performed inside `worktrees/feature-swipe-actions/`.

---

## Task 2: Add `unpinCard` to `CardListViewModel` (TDD)

**Files:**
- Modify: `RealityCheckTests/RealityCheckTests.swift` (append new suite)
- Modify: `RealityCheck/ViewModels/CardListViewModel.swift`

### Background

`CardListViewModel` is an `@Observable` class with two existing methods:
- `pinCard(_ card:from:context:)` — sets one card pinned, unsets all others, calls `WidgetCenter.shared.reloadAllTimelines()`
- `deleteCard(_ card:context:)` — calls `context.delete(card)`

`unpinCard` follows the same pattern as `pinCard`: it mutates the `RealityCard` model object directly, then calls `WidgetCenter`. The `context` parameter is accepted for API consistency but not used in the method body (same as `pinCard`).

Tests in this project use **Swift Testing** (not XCTest): `import Testing`, `@Suite`, `@Test`, `#expect`. See `RealityCheckTests/RealityCardTests.swift` for reference style.

`RealityCard` has an `updatedAt: Date` property (confirmed by existing `pinCard` usage of `card.updatedAt = Date()`).

`withAnimation` inside a test context executes the closure synchronously — the animation is cosmetic, the property mutation happens immediately.

### Steps

- [ ] **Step 1: Append the test suite to `RealityCheckTests/RealityCheckTests.swift`**

The file currently contains only the default Xcode boilerplate stub. Append a new `CardListViewModelTests` suite after the existing struct:

```swift
// RealityCheckTests/RealityCheckTests.swift
import Testing

struct RealityCheckTests {

    @Test func example() async throws {
        // Write your test here and use APIs like `#expect(...)` to check expected conditions.
    }

}

// MARK: - CardListViewModelTests

import SwiftData
@testable import RealityCheck

@Suite("CardListViewModel")
struct CardListViewModelTests {

    private func makeContext() throws -> ModelContext {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: RealityCard.self, configurations: config)
        return ModelContext(container)
    }

    @Test("unpinCard sets isPinned to false")
    func unpinCardSetsIsPinnedFalse() throws {
        let context = try makeContext()
        let card = RealityCard(title: "Test", type: .manual)
        card.isPinned = true
        context.insert(card)

        CardListViewModel().unpinCard(card, context: context)

        #expect(card.isPinned == false)
    }

    @Test("unpinCard updates updatedAt timestamp")
    func unpinCardUpdatesTimestamp() throws {
        let context = try makeContext()
        let card = RealityCard(title: "Test", type: .manual)
        card.isPinned = true
        context.insert(card)

        let before = Date()
        CardListViewModel().unpinCard(card, context: context)

        #expect(card.updatedAt >= before)
    }
}
```

- [ ] **Step 2: Run tests — expect FAIL (method does not exist yet)**

```bash
xcodebuild test -scheme RealityCheck -project RealityCheck.xcodeproj \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -only-testing:RealityCheckTests/CardListViewModelTests
```

Expected: compile error — `value of type 'CardListViewModel' has no member 'unpinCard'`

- [ ] **Step 3: Add `unpinCard` to `CardListViewModel`**

Open `RealityCheck/ViewModels/CardListViewModel.swift`. Current content:

```swift
// RealityCheck/ViewModels/CardListViewModel.swift
import SwiftUI
import SwiftData
import WidgetKit

@Observable
final class CardListViewModel {
    func pinCard(_ card: RealityCard, from cards: [RealityCard], context: ModelContext) {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            for c in cards where c.isPinned { c.isPinned = false }
            card.isPinned = true
            card.updatedAt = Date()
        }
        WidgetCenter.shared.reloadAllTimelines()
    }

    func deleteCard(_ card: RealityCard, context: ModelContext) {
        context.delete(card)
    }
}
```

Add `unpinCard` after `pinCard`:

```swift
    func unpinCard(_ card: RealityCard, context: ModelContext) {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            card.isPinned = false
            card.updatedAt = Date()
        }
        WidgetCenter.shared.reloadAllTimelines()
    }
```

- [ ] **Step 4: Run tests — expect PASS**

```bash
xcodebuild test -scheme RealityCheck -project RealityCheck.xcodeproj \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -only-testing:RealityCheckTests/CardListViewModelTests
```

Expected: `Test Suite 'CardListViewModelTests' passed`

- [ ] **Step 5: Commit**

```bash
git add RealityCheck/ViewModels/CardListViewModel.swift \
        RealityCheckTests/RealityCheckTests.swift
git commit -m "feat: add unpinCard to CardListViewModel with tests"
```

---

## Task 3: Migrate CardListView to List with swipe actions

**Files:**
- Modify: `RealityCheck/Views/CardListView.swift`

### Background

**Current structure:**
```
NavigationStack
  ScrollView
    VStack(spacing: 10)
      .padding(.horizontal, 16)
      .padding(.top, 8)
      .padding(.bottom, 24)
      cardContent (SectionLabel + NavigationLink + ForEach with .contextMenu)
  .scrollContentBackground(.hidden)
```

**Why List is required:** `.swipeActions` only works inside `List`. There is no equivalent for `ScrollView`.

**List styling to match current look:**
- `.listStyle(.plain)` — removes grouped/inset styling
- `.scrollContentBackground(.hidden)` — keeps transparent background (moved from ScrollView)
- Per-row: `.listRowBackground(Color.clear)` + `.listRowSeparator(.hidden)` + `.listRowInsets(EdgeInsets(top: 5, leading: 16, bottom: 5, trailing: 16))`
- Remove the outer `VStack` padding (`.padding(.horizontal, 16)`) — row insets replace it
- Keep `.padding(.top, 8)` and `.padding(.bottom, 24)` on the `List` itself

**Entry animations:** The current per-row `.opacity` + `.offset(y:)` modifiers apply to the row's content view and work inside `List`. Keep them as-is. If visual artifacts appear (clipping at row boundary), remove `.offset(y:)` from affected rows and keep only the `.opacity` animation as fallback.

**Swipe button declaration order:** SwiftUI renders `.swipeActions` buttons right-to-left — the first button declared appears on the **far right** (closest to the screen edge). "Xoá" is declared **first** so it occupies the far-right destructive position. "Ghim"/"Bỏ ghim" is declared second and sits to its left.

**contextMenu removal:** The `.contextMenu` block on unpinned `ForEach` rows is completely removed. No `.contextMenu` should remain anywhere in `CardListView` after this change.

**Delete alert pattern:** A single `@State private var cardToDelete: RealityCard? = nil` drives the alert for both pinned and unpinned rows. Do NOT call `viewModel.deleteCard` directly from the swipe button — always set `cardToDelete` first to trigger the alert.

### Steps

- [ ] **Step 1: Replace the full content of `CardListView.swift`**

```swift
// RealityCheck/Views/CardListView.swift
import SwiftUI
import SwiftData

struct CardListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \RealityCard.updatedAt, order: .reverse) private var cards: [RealityCard]
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
            .navigationTitle("Reality Check")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(.hidden, for: .navigationBar)
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
            .navigationDestination(for: RealityCard.self) { card in
                CardFormView(card: card)
                    .navigationTransition(.zoom(sourceID: card.id, in: namespace))
            }
            .sheet(isPresented: $showingCreateForm) {
                NavigationStack { CardFormView(card: nil) }
            }
            .alert("Xoá thẻ?", isPresented: Binding(
                get: { cardToDelete != nil },
                set: { if !$0 { cardToDelete = nil } }
            )) {
                Button("Xoá", role: .destructive) {
                    if let card = cardToDelete {
                        viewModel.deleteCard(card, context: modelContext)
                        cardToDelete = nil
                    }
                }
                Button("Huỷ", role: .cancel) { cardToDelete = nil }
            } message: {
                Text("Hành động này không thể hoàn tác.")
            }
        }
        .background(.clear)
        .onAppear {
            withAnimation(.spring(duration: 0.4)) { appeared = true }
        }
    }

    // MARK: - Card content

    @ViewBuilder
    private var cardContent: some View {
        // Pinned section
        if let pinned = pinnedCard {
            SectionLabel("Đã ghim")
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 8)
                .animation(.spring(duration: 0.4), value: appeared)
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets(top: 5, leading: 16, bottom: 5, trailing: 16))

            NavigationLink(value: pinned) {
                GlassCard(card: pinned, style: .pinned)
            }
            .buttonStyle(.plain)
            .matchedTransitionSource(id: pinned.id, in: namespace)
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
                    Label("Xoá", systemImage: "trash")
                }
                Button {
                    viewModel.unpinCard(pinned, context: modelContext)
                } label: {
                    Label("Bỏ ghim", systemImage: "pin.slash")
                }
                .tint(.auroraYellow)
            }
        }

        // Unpinned section
        if !unpinnedCards.isEmpty {
            if pinnedCard != nil {
                SectionLabel("Tất cả thẻ")
                    .padding(.top, 4)
                    .opacity(appeared ? 1 : 0)
                    .animation(.spring(duration: 0.4).delay(0.03), value: appeared)
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                    .listRowInsets(EdgeInsets(top: 5, leading: 16, bottom: 5, trailing: 16))
            }

            ForEach(Array(unpinnedCards.enumerated()), id: \.element.id) { index, card in
                NavigationLink(value: card) {
                    GlassCard(card: card, style: .unpinned)
                }
                .buttonStyle(.plain)
                .matchedTransitionSource(id: card.id, in: namespace)
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
                        Label("Xoá", systemImage: "trash")
                    }
                    Button {
                        viewModel.pinCard(card, from: cards, context: modelContext)
                    } label: {
                        Label("Ghim", systemImage: "pin")
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

            Text("Chưa có Reality Card nào")
                .font(.headline)
                .foregroundStyle(.primary)

            Text("Tạo card đầu tiên để\nđối diện thực tế")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            GlassButton("＋ Tạo card đầu tiên", style: .primary) {
                showingCreateForm = true
            }
            .padding(.top, 4)
        }
        .frame(maxWidth: .infinity)
    }
}
```

- [ ] **Step 2: Verify no `.contextMenu` remains**

Search the file for `contextMenu` — expect zero results:
```bash
grep -n "contextMenu" RealityCheck/Views/CardListView.swift
```
Expected: no output.

- [ ] **Step 3: Build — expect success**

```bash
xcodebuild build -scheme RealityCheck -project RealityCheck.xcodeproj \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
```

Expected: `** BUILD SUCCEEDED **`

If `.auroraYellow` or `.auroraGreen` cause compile errors, check `RealityCheck/Core/Extensions/Color+Aurora.swift` for the exact property names.

- [ ] **Step 4: Visual check — entry animations**

Launch in simulator. If any card row clips at its top/bottom edge during the entry animation (`.offset(y:)` pushes content outside row bounds), remove the `.offset(y: appeared ? 0 : N)` modifier from the affected rows — keep only `.opacity`. Fade-in alone is the fallback.

- [ ] **Step 5: Run all tests**

```bash
xcodebuild test -scheme RealityCheck -project RealityCheck.xcodeproj \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
```

Expected: all tests pass.

- [ ] **Step 6: Commit**

```bash
git add RealityCheck/Views/CardListView.swift
git commit -m "feat: migrate CardListView to List with swipe actions"
```

---

## Task 4: Merge worktree branch to main

- [ ] **Step 1: Switch to main and merge**

From project root (not worktree):
```bash
git checkout main
git merge feature/swipe-actions --no-ff -m "feat: add swipe actions to card list (pin/unpin + delete)"
```

- [ ] **Step 2: Remove worktree**

```bash
git worktree remove worktrees/feature-swipe-actions
```

- [ ] **Step 3: Final build on main**

```bash
xcodebuild build -scheme RealityCheck -project RealityCheck.xcodeproj \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
```

Expected: `** BUILD SUCCEEDED **`
