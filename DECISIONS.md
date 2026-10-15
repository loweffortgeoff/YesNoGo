# Decisions

## 2026-10-15 — Settings follows Offshoots, and the tip jar is gone
- The info sheet is Settings. It uses the same form treatment as Offshoots: `Palette.canvas` behind the form, `Palette.surface` on each row, a large title, and "We Also Make" above About.
- App Store links are `https://apps.apple.com/app/id<id>`. Building a slug from the display name produces `task(ed)`, which is not a valid path.
- Weather in Words is App Store id `6806063498`. `6760272161` was the previous listing. The row uses that app's current light and dark icon in one imageset.
- The tip jar is removed from the app, not only hidden. There is no StoreKit purchase code left.
- **Why:** The sheet was a credits list with a gradient tip jar on top, and the Weather row pointed at a dead listing with an old icon.

## 2026-10-13 — Root image dumps stay local
- Untrack repo-root marketing/source images (`yesnogo*.png/jpg`, `Untitled design3.png`) and the already-ignored `tmp/` PDF raster. Keep Asset Catalog copies and all `.mp3` sound files tracked.
- **Why:** Root files duplicated Assets.xcassets (or were one-off design dumps) and bloated the repo without feeding the app target. Sounds live at the root and are used by `SoundPlayer`.
- **Alternative considered:** Commit the dumps on `main` before merging `ui-modernization` — rejected; same blobs already exist on both branches, and new binary commits on `main` only add merge noise.

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

## 2026-10-13 — Decision state lives in DecisionSession
- Step 4 split `ContentView.swift` into one file per view. The decision state and the six flows now live in `Modes/DecisionSession.swift`, an `@Observable` class; `ContentView` is chrome only.
- Chosen over thin views that take closures because the flows mutate shared state (`isAnimating`, `result`, `showResult`) that mode switching, history, and the toolbar also read. One owner keeps cancel-on-mode-switch and quick-action auto-run in a single place.
- The mode views take the whole `DecisionSession` rather than a hand-picked parameter list. That still satisfies "pass a view only the data it reads": `@Observable` tracks per-property reads, so a view invalidates only on the properties it actually touches.
- The six flows take the Reduce Motion flag as a parameter instead of reading a view environment, so the flows can live outside a view and no hidden view state is read.

## 2026-04-08 — AboutSectionView is the shared template
- `AboutSectionView.swift` at `/Users/geoffreysilva/Developer/AboutSectionView.swift` is the canonical template across all apps
- Rate & Review lives only in `AboutSectionView` — removed duplicate from `TipJarView`

