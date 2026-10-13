# Changelog

## In Progress

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
- **Quick actions were never delivered** — `UIApplicationShortcutItem` taps reached no handler, and a cold launch through a deep link or shortcut lost the action. Added `AppDelegate` and a cold-launch race fix in `ContentView`.
- **History stats were English-only** — `coinStats`, `yesNoStats`, `rpsStats`, and `orbStats` matched localized result text, so percentages were wrong in every non-English locale. Entries now store a locale-independent outcome token, with a fallback for existing records.
- Custom option rows use stable identity, so text field state stays with the right row when an option is removed.

#### Removed
- `Yes__No__Go_App.swift` — unused duplicate `App` struct.
- `TipJarSectionView.swift` at the repo root — never in any target; a same-named type lives in `TipJarView.swift`.
- `YesNoGoWidgetExtension/` — orphaned folder the project does not reference.
- Live Activity and Control widget — untouched Xcode templates. The app never started a Live Activity, and the Control widget was a "Start Timer" placeholder.

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
