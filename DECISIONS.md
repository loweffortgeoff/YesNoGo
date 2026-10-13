# Decisions

## 2026-10-13 — Palette is anchored on the app icon
- Navy, gold, and silver come from `yesnogodarkglass.jpg`. Every mode accent is a muted tone drawn from that family.
- The six full-bleed gradients are gone. The accent now appears only on the hero element, the selected mode, and the primary button. The canvas is near-neutral with a soft accent wash.
- A mode never owns a gradient background again. This is the rule that keeps the app from drifting back to loud colors.

## 2026-10-13 — Outcome tokens live in history entries
- `HistoryEntry.category` stores a locale-independent outcome token (`heads`, `yes`, `rock`, `orb.positive`, and so on).
- Stats classify on that token, not on displayed text. Entries saved before this change fall back to matching the old English strings.
- Adding an outcome to a new mode means adding a case to `Outcome`.

## 2026-10-13 — Quick actions and deep links belong to the scene delegate
- The app is scene based, so UIKit delivers shortcut items and incoming URLs to the scene delegate, never to the app delegate. `AppDelegate` only installs `SceneDelegate` through `application(_:configurationForConnecting:)`. `SceneDelegate` owns `connectionOptions.shortcutItem`, `connectionOptions.urlContexts`, `windowScene(_:performActionFor:)`, and `scene(_:openURLContexts:)`.
- SwiftUI's `.onOpenURL` is deliberately absent. Replacing the scene delegate takes SwiftUI out of scene-scoped events, so the scene callbacks are the only path. Verified cold and warm on iOS 18.6 and iOS 27.0.
- Every entry point writes one value: `QuickActionManager.shared.requestedMode`, typed as `DecisionMode`. `ContentView` consumes it on appear, on change, and when the scene becomes active. No bundle identifier is rebuilt at the call sites.
- Register quick actions at launch only. Do not also list them in `Info.plist`: iOS shows static and dynamic items together, capped at four, so the menu shows "Flip Coin" twice when both exist. `main` registers at launch only, and this app follows the same rule.
- The cost of that rule: a fresh install has no quick actions until the app has run once.
- Superseded: an earlier version of this entry said the app delegate owns shortcut items and that `ContentView` watched `pendingQuickAction`. The `d8027b8` attempt did exactly that, and the taps still went nowhere. `c373336` replaced it.

## 2026-04-08 — AboutSectionView is the shared template
- `AboutSectionView.swift` at `/Users/geoffreysilva/Developer/AboutSectionView.swift` is the canonical template across all apps
- Rate & Review lives only in `AboutSectionView` — removed duplicate from `TipJarView`

