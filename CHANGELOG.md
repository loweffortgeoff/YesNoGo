# Changelog

## In Progress

### 2026-10-15 — Settings

#### Changed
- **Settings** — The info sheet is now Settings, laid out like Offshoots: a form on the brand canvas, card-colored rows, and a large title. The toolbar button is a gear. The Substack link is gone.
- **Other apps** — App Store links use the id-only URL (`https://apps.apple.com/app/id…`). A name slug breaks on "Task(ed)".
- **Weather in Words** — The row opens `id6806063498`. The previous id, `6760272161`, no longer opens the app. The icon is the current light and dark app icon.

#### Removed
- **Tip jar** — The settings row, the purchase screen, and the StoreKit manager are gone. The app no longer offers in-app tips.

---

### 2026-10-14 — Version 1.7.0 and Xcode Cloud Platforms

#### Changed
- **Version** — `MARKETING_VERSION` is 1.7.0.
- **Platforms** — The app target builds for iPhone and iPad only (`SUPPORTED_PLATFORMS = iphoneos iphonesimulator`, device family `1,2`). It no longer lists macOS or visionOS, which the code has never compiled for.

#### Fixed
- **Xcode Cloud archive actions failed** — they targeted macOS and visionOS. They now match the platforms the app supports.

---

### 2026-10-13 — UI Modernization: Palette, Motion, and Layout

#### Changed
- **Palette** — New `ModeTheme` and `DecisionMode` types. The six full-bleed primary-color gradients are replaced by a navy canvas with a soft accent wash, and one muted accent per mode. The palette is anchored on the app icon: navy, gold, and silver. The material wash that muddied the card is gone.
- **Typography and contrast** — All text now uses `.primary` and `.secondary`. The dead high-contrast branch in `primaryTextColor` and `secondaryTextColor` is removed. Hero glyphs and the RNG number scale with Dynamic Type through `@ScaledMetric`.
- **Motion** — `DispatchQueue` sleeps are replaced by an async task timeline. Haptics use `.sensoryFeedback` instead of manual feedback generators. Added `.symbolEffect`, `.contentTransition(.numericText())`, and a `PhaseAnimator` idle for the orb. The Custom picker is now a spinning wheel instead of a manual swirl.
- **Layout** — The mode selector is an equal-width segmented bar, so the sixth mode is no longer clipped. The mode name is the navigation title. History and credits moved into a real toolbar, removing the hardcoded 56pt top padding.
- **Mode identity** — Coin faces use `crown.fill` and `bird.fill` in the brand gold coin, replacing the crown and eagle emoji.
- **Widget** — Palette matches the app. Symbols corrected (`centsign.circle.fill`, `questionmark.circle.fill`, `shuffle`, `bubbles.and.sparkles.fill`).

#### Fixed
- **Widget and deep links did nothing** — `yesnogo://` was never registered. The prepared `Info-QuickActions.plist` is promoted to the real `Info.plist` and wired into the app target.
- **Quick actions were never delivered** — `UIApplicationShortcutItem` taps reached no handler, and a cold launch through a deep link or shortcut lost the action. The app is scene based, so UIKit delivers both to the scene delegate, not the app delegate. `AppDelegate` now installs `SceneDelegate`, which handles the cold and warm callbacks for shortcut items and URLs. Verified cold and warm on iOS 18.6 and iOS 27.0.
- **The quick action menu showed "Flip Coin" twice** — the three items listed in `Info.plist` and the three the app registers at launch all appeared, and iOS shows at most four. Quick actions are now registered at launch only.
- **A quick action could fire after the user had moved on** — the delayed run after a quick action was not cancelable, so switching modes inside the delay still played the old mode's sound, animation, and history entry. It now runs only while the requested mode is still on screen.
- **The Rock Paper Scissors emojis kept bobbing after the result** — the repeating animation was applied in both directions, so the emojis never settled and overlapped the caption.
- **With Reduce Motion on, the custom wheel pointer marked the wrong option** — the wheel skipped the spin but still sat at its start angle, so the pointer disagreed with the announced winner for the whole delay.
- **History stats were English-only** — `coinStats`, `yesNoStats`, `rpsStats`, and `orbStats` matched localized result text, so percentages were wrong in every non-English locale. Entries now store a locale-independent outcome token, with a fallback for existing records.
- Custom option rows use stable identity, so text field state stays with the right row when an option is removed.

#### Removed
- `Yes__No__Go_App.swift` — unused duplicate `App` struct.
- `TipJarSectionView.swift` at the repo root — never in any target; a same-named type lives in `TipJarView.swift`.
- `YesNoGoWidgetExtension/` — orphaned folder the project does not reference.
- Live Activity and Control widget — untouched Xcode templates. The app never started a Live Activity, and the Control widget was a "Start Timer" placeholder.
- Repo-root image dumps (`yesnogo*.png/jpg`, `Untitled design3.png`) and `tmp/pdfs/yes-no-go-app-summary-1.png` — untracked; files stay on disk. Asset Catalog images and all sounds remain tracked. Root `*.png`/`*.jpg`/`*.jpeg` added to `.gitignore`.

---

### 2026-10-13 — UI Modernization: Internal Structure

#### Changed
- **Structure** — `ContentView.swift` (1297 lines) is split into one file per view, grouped into `App/`, `Design/`, `History/`, `Modes/`, and `Support/`. The decision state and the six flows move into `Modes/DecisionSession.swift`; `ContentView` is chrome only (124 lines). Move-only: no behavior, copy, timing, or visual change.
- **Sound** — `playSound` moves into a small `SoundPlayer` type in `Support/SoundPlayer.swift`.

---

### 2026-04-08 — AboutSectionView Cleanup

#### Changed
- Synced `AboutSectionView.swift` to shared template (added `import StoreKit`, fixed AisleWise icon name)
- Removed duplicate Rate & Review from `TipJarView.swift` — `AboutSectionView` is now the single source of truth

---

## Shipped — Current: v1.6.4

### 2026-03-30 — Result History

#### New
- **Result History** — Per-mode results log added

---

### 2025-11-03 — Initial Release

#### Notes
- First App Store release
