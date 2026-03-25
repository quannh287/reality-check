# Design: Swipe Actions on Card List

**Date:** 2026-03-25
**Status:** Approved

## Overview

Add swipe-left (trailing edge) actions to card rows in `CardListView`, replacing the existing long-press context menu. Each card reveals two action buttons: one for pin/unpin and one for delete. Delete requires an alert confirmation.

## Layout Change

Replace `ScrollView + VStack` with `List` styled to match the existing Aurora/GlassKit aesthetic:

```swift
List { ... }
    .listStyle(.plain)
    .scrollContentBackground(.hidden)
```

Each row uses:
```swift
.listRowBackground(Color.clear)
.listRowSeparator(.hidden)
.listRowInsets(EdgeInsets(top: 5, leading: 16, bottom: 5, trailing: 16))
```

`SectionLabel`, entry animations (`appeared` state), and section structure (pinned / unpinned) remain unchanged. Visual output is identical to the current layout.

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

No other ViewModel changes needed. Existing `pinCard` and `deleteCard` are reused as-is.

## Parallel Work

Implementation runs on a git worktree at a local path inside the project directory, branching off `main` as `feature/swipe-actions`. This isolates changes from any other Claude Code session working on `main`.

## Files Changed

| File | Change |
|------|--------|
| `RealityCheck/Views/CardListView.swift` | Replace ScrollView/VStack with List; add swipeActions, remove contextMenu, add alert state |
| `RealityCheck/ViewModels/CardListViewModel.swift` | Add `unpinCard` method |

No new files created. Widget target files are not affected.
