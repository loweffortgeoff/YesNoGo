# Decisions

## 2026-10-13 — Palette is anchored on the app icon
- Navy, gold, and silver come from `yesnogodarkglass.jpg`. Every mode accent is a muted tone drawn from that family.
- The six full-bleed gradients are gone. The accent now appears only on the hero element, the selected mode, and the primary button. The canvas is near-neutral with a soft accent wash.
- A mode never owns a gradient background again. This is the rule that keeps the app from drifting back to loud colors.

## 2026-10-13 — Outcome tokens live in history entries
- `HistoryEntry.category` stores a locale-independent outcome token (`heads`, `yes`, `rock`, `orb.positive`, and so on).
- Stats classify on that token, not on displayed text. Entries saved before this change fall back to matching the old English strings.
- Adding an outcome to a new mode means adding a case to `Outcome`.

## 2026-10-13 — Home Screen quick actions need an app delegate
- SwiftUI has no handler for `UIApplicationShortcutItem`. `AppDelegate` owns it.
- Deep links and shortcut items can arrive after the scene appears on a cold launch, so `ContentView` also reacts to `pendingQuickAction` changes.

## 2026-04-08 — AboutSectionView is the shared template
- `AboutSectionView.swift` at `/Users/geoffreysilva/Developer/AboutSectionView.swift` is the canonical template across all apps
- Rate & Review lives only in `AboutSectionView` — removed duplicate from `TipJarView`

