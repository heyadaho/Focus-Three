# Focus Three — Product Requirements Document

**Version:** 1.0
**Platform:** macOS (14 Sonoma+)
**Author:** Ed
**Date:** March 2026
**Status:** Draft — Ready for Review

---

## Table of Contents

1. [Overview](#1-overview)
2. [Target Users](#2-target-users)
3. [Product Scope](#3-product-scope--v10)
4. [Feature Requirements](#4-feature-requirements)
5. [UX & Design Principles](#5-ux--design-principles)
6. [Technical Architecture](#6-technical-architecture)
7. [Phased Roadmap](#7-phased-roadmap)
8. [Getting Started — Development](#8-getting-started--development)
9. [Open Questions](#9-open-questions)
10. [Iteration & Future Thinking](#10-iteration--future-thinking)
11. [Decision Log](#11-decision-log)
12. [Revision History](#12-revision-history)

---

## 1. Overview

Focus Three is a lightweight macOS menu bar application that prompts the user each morning to identify their top three priorities for the day. By constraining focus to exactly three things, it helps knowledge workers avoid context-switching overload and finish each day with a clear sense of progress.

The app lives unobtrusively in the menu bar, launches at login, and takes under 60 seconds to interact with. It is intentionally minimal — a sharp tool for a single job.

### 1.1 Problem Statement

Knowledge workers face an ever-growing task list with no natural forcing function to prioritise. Common failure modes:

- Starting each day reactively (Slack, email) rather than intentionally
- Tackling 10+ tasks and completing none well
- Losing clarity on what "done" looks like for the day
- Feeling busy but not productive

Focus Three solves this by creating a daily ritual: a brief moment of intentional commitment before work begins.

### 1.2 Vision

> A focused day starts with a focused question. Focus Three is the lightest possible intervention — present every morning, gone after 30 seconds, remembered all day.

### 1.3 Success Metrics

| Metric | Target (Month 3) | Notes |
|--------|-----------------|-------|
| Daily prompt completion rate | ≥ 80% of weekdays | Measured from local logs |
| Time to complete daily input | < 60 seconds | From first click to dismiss |
| App memory footprint | < 30 MB | Must not slow login |
| User retention (1-week) | ≥ 70% | Daily active use |

---

## 2. Target Users

### 2.1 Primary User

Ed — Product Design Manager. Works across multiple projects and teams simultaneously. Needs a lightweight morning ritual to cut through incoming noise and stay outcome-focused throughout the day.

### 2.2 Persona: The Distracted Knowledge Worker

- **Role:** Manager, designer, or IC in a fast-moving organisation
- **Problem:** Too many inputs, not enough focus
- **Environment:** macOS, multiple apps open, always context-switching
- **Goal:** End the day with clarity on what was achieved
- **Frustration:** Complex task managers that become another thing to maintain

---

## 3. Product Scope — v1.0

### 3.1 In Scope

- macOS menu bar icon (persistent, always visible)
- Login item — auto-launches at system startup
- Morning prompt: input field for 3 priorities (triggered once per day or on demand)
- View today's three items from the menu bar dropdown
- Mark items as complete
- Reset or re-enter priorities for the day
- Minimal, native-feeling macOS UI
- Local data storage only (no account, no sync)

### 3.2 Out of Scope (v1.0)

- Cloud sync or cross-device support
- Calendar or task manager integrations
- Analytics or reporting
- Notifications or push reminders
- Team or shared features
- iOS / iPadOS companion app

---

## 4. Feature Requirements

Priority definitions:
- **Must Have** = v1.0 launch blocker
- **Should Have** = v1.1
- **Could Have** = future roadmap

| Feature | Priority | Phase | Status | Notes |
|---------|----------|-------|--------|-------|
| Menu bar icon with status indicator | Must Have | 1 | ⬜ To Do | Shows if priorities have been set today |
| Morning prompt on first launch | Must Have | 1 | ⬜ To Do | Appears once per day, auto-focused input |
| 3-item input (no more, no less) | Must Have | 1 | ⬜ To Do | Enforces constraint — disables 4th field |
| Dropdown view of today's items | Must Have | 1 | ⬜ To Do | Accessible from menu bar at any time |
| Mark item as complete (strikethrough) | Must Have | 1 | ⬜ To Do | Visual confirmation of progress |
| Re-open prompt to edit today's items | Must Have | 1 | ⬜ To Do | Allow refinement if plans change |
| Launches at login (Login Item) | Must Have | 1 | ⬜ To Do | Auto-registered on first install |
| Prompt time customisation | Should Have | 2 | ⬜ To Do | User sets preferred trigger time |
| Snooze prompt | Should Have | 2 | ⬜ To Do | Delay by 15 / 30 / 60 min |
| Day history (last 7 days) | Should Have | 2 | ⬜ To Do | Review past priorities in popover |
| Carry-over incomplete items | Should Have | 2 | ⬜ To Do | Offer to roll unfinished items to tomorrow |
| Keyboard shortcut to open | Should Have | 2 | ⬜ To Do | Global hotkey (user-configurable) |
| Weekly summary view | Could Have | 3 | ⬜ To Do | Simple list of past weeks |
| End-of-day reflection prompt | Could Have | 3 | ⬜ To Do | Optional — "How did today go?" |
| Export history (CSV/Markdown) | Could Have | 3 | ⬜ To Do | For users who want to analyse patterns |
| Themes (light / dark / accent colour) | Could Have | 3 | ⬜ To Do | macOS dark mode auto-follows system |
| AI-assisted priority suggestions | Could Have | 4 | ⬜ To Do | Suggests based on calendar / recent history |
| iCloud sync | Could Have | 4 | ⬜ To Do | Sync history across Mac devices |

---

## 5. UX & Design Principles

### 5.1 Design Philosophy

Focus Three should feel like a native macOS app — not an Electron port or a web wrapper. Every interaction should be fast, intentional, and satisfying. The app competes on quality of experience, not quantity of features.

### 5.2 UI Components

#### Menu Bar Icon
- Use SF Symbols for the icon (e.g. `checkmark.circle` or `list.number`)
- Two states: empty ring (no priorities set) / filled ring (priorities set)
- Badge with a count of incomplete items (optional, Phase 2)

#### Morning Prompt Window
- Floating panel — not a full window, not a sheet
- Appears centred on screen or anchored to menu bar icon
- Three numbered input fields (1, 2, 3) — Tab moves between them
- Return key on field 3 submits if all fields are filled
- Subtle animation on appearance (spring / fade)
- Title: "What are your three things today?"
- Character limit per item: 80 characters
- Dismiss without saving should warn if fields are populated

#### Dropdown Popover
- Opens on click of menu bar icon
- Shows date + greeting ("Good morning, Ed")
- Three items with completion toggles
- Footer: "Edit" button + "Quit" option
- Width: fixed at 320pt

### 5.3 Design Stack

| Decision | Choice |
|----------|--------|
| Language | Swift |
| UI Framework | SwiftUI (native macOS) |
| Minimum macOS | Sonoma (14.0) |
| Appearance | Follows system light/dark mode automatically |
| Typography | System font (SF Pro) throughout |
| Icons | SF Symbols 5 |

### 5.4 Accessibility

- Full VoiceOver support for all interactive elements
- Keyboard-navigable — no mouse required
- Respects Reduce Motion preference
- Minimum tap/click target: 44×44pt

---

## 6. Technical Architecture

### 6.1 Tech Stack

| Layer | Choice |
|-------|--------|
| Language | Swift 5.9+ |
| UI Framework | SwiftUI + AppKit (NSStatusItem for menu bar) |
| Data Storage | SwiftData |
| Build Tool | Xcode 15+ |
| Minimum Target | macOS 14.0 Sonoma |
| Distribution | Direct download (DMG) initially; Mac App Store optional |

### 6.2 Architecture Overview

#### App Entry Point
- `@main App` struct with `NSApplicationDelegate`
- `NSStatusItem` for menu bar presence
- `NSPopover` for the dropdown UI
- `LSUIElement = YES` in Info.plist (hides Dock icon)

#### Data Model

```swift
// DailyFocus — one record per day
DailyFocus {
    date: Date
    items: [FocusItem]
    completedAt: Date?
}

// FocusItem — one of the three priorities
FocusItem {
    id: UUID
    text: String
    isComplete: Bool
    order: Int  // 0, 1, 2
}
```

#### Login Item
- Use `ServiceManagement` framework (`SMAppService`) — the modern macOS API
- Toggle exposed in Settings panel within the app
- Never prompts for admin password

#### State Management
- `@Observable` — single source of truth
- `FocusStore`: manages today's items, persistence, and prompt trigger logic

### 6.3 File / Folder Structure

```
FocusThree/
├── App/
│   ├── FocusThreeApp.swift       # @main entry point
│   └── AppDelegate.swift         # NSStatusItem setup
├── Models/
│   ├── DailyFocus.swift          # SwiftData model
│   └── FocusItem.swift           # SwiftData model
├── Store/
│   └── FocusStore.swift          # @Observable state + persistence
├── Views/
│   ├── MenuBarPopover.swift       # Dropdown popover
│   ├── MorningPromptView.swift    # Daily input panel
│   └── SettingsView.swift        # Login item toggle, prefs
├── Utilities/
│   └── LoginItemManager.swift    # SMAppService wrapper
├── Resources/
│   └── Assets.xcassets
└── docs/
    └── FocusThree_PRD_v1.md      # This file
```

### 6.4 Key Entitlements

```xml
com.apple.security.app-sandbox: YES
<!-- No network entitlements required for v1.0 -->
```

---

## 7. Phased Roadmap

| Phase | Name | Key Deliverables | Estimated Effort |
|-------|------|-----------------|-----------------|
| 1 | MVP | Menu bar icon, morning prompt, 3-item input, completion toggle, login item | 2–3 weeks |
| 2 | Habit Layer | Prompt scheduling, snooze, 7-day history, carry-overs, global hotkey | 2–3 weeks |
| 3 | Reflection | Weekly summary, end-of-day prompt, CSV export, themes | 2 weeks |
| 4 | Intelligence | AI suggestions, iCloud sync, optional App Store distribution | 3–4 weeks |

---

## 8. Getting Started — Development

### 8.1 Prerequisites

- Xcode 15 or later
- macOS Sonoma 14.0+ (development machine)
- Apple Developer account (for signing + login item entitlements)
- Git for version control

### 8.2 Project Setup

1. Create new Xcode project → macOS → App
2. Select SwiftUI interface, Swift language
3. Set Bundle ID: `com.yourname.focusthree`
4. Enable App Sandbox entitlement
5. Add `LSUIElement = YES` to Info.plist (hides from Dock)
6. Implement `NSStatusItem` in `AppDelegate` or `@main App`

### 8.3 Distribution

- **v1.0:** Direct DMG download (notarised via Xcode)
- **v2+:** Consider Mac App Store for discoverability and auto-updates
- Use **Sparkle** framework for auto-update if staying outside App Store

---

## 9. Open Questions

| # | Question | Decision | Date |
|---|----------|----------|------|
| 1 | What is the ideal trigger for the morning prompt? Login vs. first screen unlock vs. a set time? | Start with login. Add time-based option in Phase 2. | — |
| 2 | Should the app enforce exactly 3 items, or allow 1–3? | Enforce 3 — part of the product's value proposition. | — |
| 3 | What happens if the user doesn't set priorities? Silent or prompt again? | Re-prompt gently once. No nagging. | — |
| 4 | App name: is "Focus Three" final? Check App Store availability. | Alternatives: Triad, ThreeToday, FocusSet | — |

---

## 10. Iteration & Future Thinking

### 10.1 Designed to Extend

Architecture decisions that support future growth:

- SwiftData from Phase 1 — easier than migrating from UserDefaults later
- Separate `FocusStore` from UI layers for testability
- Use feature flags (simple `UserDefaults` booleans) to gate Phase 2+ features during development
- Version the data model from day one

### 10.2 Ideas Parking Lot

Not committed — preserved for future consideration:

- Integration with Apple Calendar — auto-suggest based on meetings today
- Widgets: Today's three items on the macOS desktop or Lock Screen
- Pomodoro mode: 25-min focus blocks tied to each of the three items
- Team mode: Share your three things with your manager or team in Slack
- End-of-week email digest to yourself
- Siri shortcut: "What are my three things today?"
- "Energy" tagging: mark items as Deep Work, Quick Win, or Collaborative

### 10.3 Things That Should Never Change

These constraints are intentional product principles, not limitations:

- **Maximum of three items** — not four, not optional
- **No social features or leaderboards**
- **No AI by default** — intelligence should be opt-in
- **No account required** for core functionality
- **App should never send data anywhere** without explicit user action

---

## 11. Decision Log

> This section is updated by Claude Code as the project progresses. Each entry records an architectural or product decision made during development that differs from or extends the original PRD.

| # | Decision | Rationale | Date |
|---|----------|-----------|------|
| — | — | — | — |

---

## 12. Revision History

| Version | Date | Changes | Author |
|---------|------|---------|--------|
| 1.0 | March 2026 | Initial PRD created | Ed |
