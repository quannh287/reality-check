# Reality Check — App Design Spec

**Date:** 2026-03-23
**Phase:** 1
**Platform:** Native iOS (Swift/SwiftUI) + macOS (shared WidgetKit)

## Problem

When facing major career/financial decisions (quitting a job, switching roles), emotions and excitement can override rational thinking. There's no tool that forces you to confront your actual situation — finances, job stability, obligations — before making impulsive moves.

## Solution

A native iOS/macOS app with two parts:

1. **App** — Create and manage "Reality Cards", each representing one hard fact about your current situation
2. **Widget** — Display one chosen card on your home screen as a bold, unavoidable number with context

The widget is the primary interface. It shows a single powerful number (e.g., **"47 ngày"** — runway if you quit today) that you see every time you look at your phone. The app is just where you enter and update data.

## Architecture

```
┌─────────────┐     App Groups      ┌─────────────┐
│   App        │  ──────────────→   │   Widget     │
│  (SwiftUI)   │   (shared data)    │  (WidgetKit) │
│              │                     │              │
│ • CRUD cards │                     │ • Read card  │
│ • Input data │                     │ • Bold number│
│ • Pin to     │                     │ • Context    │
│   widget     │                     │   line       │
└─────────────┘                     └─────────────┘
       │
       ▼
  SwiftData (local)
```

- **App ↔ Widget communication:** App Groups shared container
- **Persistence:** SwiftData stored in App Groups container so both app and widget can access it
- **Widget refresh:** WidgetKit timeline, refreshes when app updates data via `WidgetCenter.shared.reloadAllTimelines()`

## Data Model

### Reality Card

| Field       | Type              | Description                                          |
|-------------|-------------------|------------------------------------------------------|
| id          | UUID              | Unique identifier                                    |
| title       | String            | Card name — "Runway", "Job stability"                |
| type        | enum: manual/formula | How the display value is determined               |
| value       | Double?           | Direct value (manual type only)                      |
| inputA      | Double?           | First input for formula                              |
| inputB      | Double?           | Second input for formula                             |
| inputALabel | String?           | Label for input A — "Tiết kiệm"                     |
| inputBLabel | String?           | Label for input B — "Chi phí / tháng"                |
| formula     | enum?             | divide / count / subtract / countdown                |
| targetDate  | Date?             | For countdown formula                                |
| unit        | String            | Display unit — "ngày", "tháng", "triệu", "job"      |
| contextLine | String            | Text below the number — "runway nếu nghỉ việc"      |
| isPinned    | Bool              | Whether this card is shown on the widget             |
| createdAt   | Date              | Creation timestamp                                   |
| updatedAt   | Date              | Last update timestamp                                |

### Formula Templates

| Formula    | Operation | Example                        | Output        |
|------------|-----------|--------------------------------|---------------|
| divide     | A ÷ B     | 30tr ÷ 15tr                   | "2 tháng"     |
| count      | A / B     | 1 confirmed / 3 total jobs    | "1/3 job"     |
| subtract   | A − B     | 20tr income − 15tr expenses   | "5tr dư"      |
| countdown  | target − today | Days until a specific date | "12 ngày"     |

### Computed Display Value

```
switch card.type:
  case .manual:
    return card.value
  case .formula:
    switch card.formula:
      case .divide:    return card.inputA / card.inputB          // → Double, formatted as number
      case .count:     return "\(Int(card.inputA))/\(Int(card.inputB))"  // → String, special display format
      case .subtract:  return card.inputA - card.inputB          // → Double, formatted as number
      case .countdown: return daysBetween(today, card.targetDate) // → Int, formatted as number
```

## App Screens

### 1. Card List (Main Screen)

- Header: "Reality Check" title + "+" button
- Pinned section: card currently shown on widget, highlighted with accent border
- Cards section: remaining cards in a list
- Each card shows: computed value (large), unit, context line, type badge (manual/formula)
- Swipe to delete
- Tap to edit
- Long press to pin/unpin from widget

### 2. Create/Edit Card

- Title input
- Type toggle: Manual / Formula
- **If Manual:** value input + unit input
- **If Formula:** formula picker (divide/count/subtract/countdown) + input A (with label) + input B (with label) or target date (for countdown) + unit input
- Context line input

### 3. Settings

- Notification time picker (default: 8:00 AM)
- Notification on/off toggle
- Live widget preview at bottom showing how it will look
- Cancel / Save navigation

## Widget

### Appearance

- **Size:** Small (iOS), small (macOS) — single size for Phase 1
- **Layout:** Centered vertically
  - Large bold number (42pt, weight 800)
  - Unit label below (11pt, uppercase, muted)
  - Context line at bottom (10pt, muted)
- **Color:** Phase 1 uses a single accent color (#FF4444, red) for all card numbers. No heuristics, no per-card configuration. This keeps the widget visually consistent and simple to implement.

### Behavior

- Displays the pinned Reality Card
- If no card is pinned, shows placeholder prompting user to open app
- Tapping widget opens the app
- Refreshes when app updates data

## Notifications

- **Daily summary:** Scheduled local notification at a user-configured time (default: 8:00 AM)
- **Content:** Shows the pinned card's value and context line
- Example: "Reality Check: 47 ngày — runway nếu nghỉ việc hôm nay"
- **Settings:** Configurable notification time, can disable

## Tech Stack

| Component      | Technology                |
|----------------|---------------------------|
| UI Framework   | SwiftUI                   |
| Persistence    | SwiftData                 |
| Widget         | WidgetKit                 |
| Notifications  | UserNotifications         |
| Data Sharing   | App Groups                |
| Platforms      | iOS 17+ / macOS 14+       |

## Phase 1 Scope

### Included

- Create / edit / delete Reality Cards
- Manual cards (direct value input)
- Formula cards (4 templates: divide, count, subtract, countdown)
- Pin a card to Widget
- iOS Widget (small size)
- macOS Widget (shared WidgetKit code)
- Daily notification summary
- SwiftData local storage

### Excluded (Phase 2+)

- Detailed dashboard / analytics
- Decision history / journal
- Android version
- Custom formulas beyond templates
- Cloud sync / backup
- Multiple widget sizes (medium, large)
- Custom card colors
- Data export/import

## Error Handling

- No card pinned → widget shows "Mở app để tạo Reality Card đầu tiên"
- Division by zero → show "∞" with warning context
- Countdown past date → show "0 ngày" or negative with different styling
- Empty card list → onboarding prompt suggesting first card to create

## Testing Strategy

- Unit tests: formula computation, data model validation
- UI tests: card CRUD flow, widget pin/unpin
- Widget tests: timeline generation, display value rendering
