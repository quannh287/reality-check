# Design: Swipe Actions on Card List

**Date:** 2026-03-25
**Status:** Approved

## Overview

Add swipe-left (trailing edge) actions to card rows in `CardListView`, replacing the existing long-press context menu. Each card reveals two action buttons: one for pin/unpin and one for delete. Delete requires an alert confirmation.

## Layout Change

Replace `ScrollView + VStack` with `List` styled to match the existing Aurora/GlassKit aesthetic.

**Why `List` is required:** `.swipeActions` is a SwiftUI modifier that only works on rows inside a `List`. It is not available for views inside `ScrollView + VStack`. The migration to `List` is a technical constraint, not a preference.

```swift
List { ... }
    .listStyle(.plain)
    .scrollContentBackground(.hidden)  // moved from ScrollView — same effect
```

Each row uses:
```swift
.listRowBackground(Color.clear)
.listRowSeparator(.hidden)
.listRowInsets(EdgeInsets(top: 5, leading: 16, bottom: 5, trailing: 16))
// listRowInsets fully replaces system defaults — no double-padding risk
```

The outer `VStack` padding (`.padding(.horizontal, 16)`) is removed; row insets take over.

`SectionLabel` and section structure (pinned / unpinned) remain unchanged. The `emptyState` view is placed as an inline row.

### Entry Animations

The current per-row `appeared`-driven animations use `.opacity` + `.offset(y:)` applied to each row's content view. These modifiers are applied to the view itself — not to List layout — so they work inside `List` rows. However, `.offset(y:)` inside a List row affects rendering within the allocated row height; on first test during implementation, if any visual artifact appears (clipping, layout jitter), the fallback is to replace per-row `offset` with a `.transition(.opacity.combined(with: .move(edge: .top)))` applied to each row using `.listRowSeparator` and list insertion animation. This decision is made during implementation.

## Swipe Actions

Applied via `.swipeActions(edge: .trailing, allowsFullSwipe: false)` on each card row.

`allowsFullSwipe: false` prevents accidental deletion on fast swipes.

### Pinned card
| Button | Icon | Tint | Action |
|--------|------|------|--------|
| Bỏ ghim | `pin.slash` | `.auroraYellow` | `viewModel.unpinCard(card, context:)` |
| Xoá | `trash` | `.red` (role: `.destructive`) | Set `cardToDelete = card` |

### Unpinned cards
| Button | Icon | Tint | Action |
|--------|------|------|--------|
| Ghim | `pin` | `.auroraGreen` | `viewModel.pinCard(card, from: cards, context:)` |
| Xoá | `trash` | `.red` (role: `.destructive`) | Set `cardToDelete = card` |

**Color rationale:** `.auroraYellow` for "bỏ ghim" (caution/warning tone) and `.auroraGreen` for "ghim" (positive/action tone) are intentional UI choices. They do not follow the formula-type color system from `Color+Aurora.swift`.

The existing `.contextMenu` on unpinned cards is removed entirely.

## Delete Confirmation Alert

A single `@State private var cardToDelete: RealityCard? = nil` tracks the pending deletion. Tapping "Xoá" in swipe sets this value; no deletion happens immediately.

```swift
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
```

**Delete during animation:** Calling `context.delete(card)` while a row is still animating out is safe. SwiftData + `@Query` automatically removes the model object from the query result and drives the List row removal. No crash risk from concurrent animation and deletion.

## ViewModel Changes

Add `unpinCard` to `CardListViewModel`:

```swift
func unpinCard(_ card: RealityCard, context: ModelContext) {
    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
        card.isPinned = false
        card.updatedAt = Date()
    }
    WidgetCenter.shared.reloadAllTimelines()
}
```

**Autosave:** Both `unpinCard` and existing `pinCard`/`deleteCard` rely on SwiftData's autosave. No explicit `context.save()` call is needed or added.

No other ViewModel changes needed. Existing `pinCard` and `deleteCard` are reused as-is.

## Parallel Work

Implementation runs on a git worktree at a local path inside the project directory (`<project-root>/worktrees/feature-swipe-actions`), branching off `main` as `feature/swipe-actions`. This isolates changes from any other Claude Code session working on `main`.

## Files Changed

| File | Change |
|------|--------|
| `RealityCheck/Views/CardListView.swift` | Replace ScrollView/VStack with List; add swipeActions; remove contextMenu; add `cardToDelete` alert state |
| `RealityCheck/ViewModels/CardListViewModel.swift` | Add `unpinCard` method |

No new files created. Widget target files are not affected (swipe actions are main-app UI only).
