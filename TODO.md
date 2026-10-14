# YesNoGo TODO

## Next
- [ ] Create promo video for ASC
- [ ] Verify Home Screen quick actions on a physical device (cannot be exercised in the simulator)

## Planned
- [ ] Apple Watch App — Quick decisions from your wrist — coin flip and yes/no on watchOS

## Backlog
- [ ] Extract the four remaining section views that are still computed properties into `View` types: `coinDisc` (`CoinFlipView`), `orbHero` (`MagicOrbView`), `pickerStage` and `wheel` (`CustomPickerView`). They are used once each, so the contract's small-fragment exception does not apply.
- [ ] Preload the audio players in `SoundPlayer` (`playFile` builds a new `AVAudioPlayer` on every play).
- [ ] Localize the hardcoded English accessibility labels ("Past results", "Credits and information", "Close history", and others).
- [ ] Register Home Screen quick actions for RPS, Orb, and RNG. Only coin, yes/no, and custom exist today.
- [ ] Widget palette is duplicated in `YesNoGoWidget.swift` because the widget target does not share app sources. Consider a shared file added to both targets.
- [ ] `WidgetL10n.swift` now has no consumers after the Live Activity removal.
- [ ] Note on the design contract: `ForEach(Array(choices.enumerated()), id: \.offset)` is used for the picker wheel and RPS emoji, and index identity is used for the editable custom option list. Index identity is correct for the editable list; the two static collections could take element identity instead.
- [ ] Reboot-free way to reset a stuck simulator alert: two simulators had a pending location prompt that blocked app launch and could not be dismissed without rebooting the device.
- [ ] Performance: the custom option `Binding` is rebuilt on every keystroke. Fine at 6 options, worth watching if the limit grows.
- [ ] iPad multi-window: `UIApplicationSupportsMultipleScenes` is true and every scene shares `QuickActionManager.shared`, so a deep link opened in one window can be consumed by another. Set the flag to NO, or route the request per scene.
- [ ] History stat labels do not localize. `HistoryView.statRow` takes a `String`, so SwiftUI passes labels such as "👑 Heads" through untranslated. Take `LocalizedStringKey` and add the strings to the catalog.
- [ ] A fresh install shows no Home Screen quick actions until the app has launched once, because they are registered at launch only. This matches `main`. Decide whether to list them in `Info.plist` as well, with translated titles in `InfoPlist.xcstrings`, to cover the never-launched case without duplicating the menu.

## Developer Notes
- The app deploys to iOS 18.6, but the widget target deploys to 26.2. That mismatch is existing and unverified.
- The project file carries a dangling target dependency (`3A18550C2EB7F5E400A711F2`, `remoteInfo = YesNoGoWidgetExtensionExtension`) that refers to a target which no longer exists. Builds succeed, but it is stale.
- `YesNoGoWidgetExtension.xcscheme` and `YesNoGoWidgetExtensionExtension.xcscheme` are tracked. The second names a target that does not exist.
- The whole `build/` directory is committed to the repo.

## Exploring
- [ ] Group Decisions — Share a decision link with friends and see everyone's pick
- [ ] Custom Themes — Personalize the look with color themes and mode icons

## Done
- [x] 2026-10-14 — Narrow `SUPPORTED_PLATFORMS` to iPhone and iPad and drop device family 7, so the Xcode Cloud archive actions no longer target macOS or visionOS. Build verified in the simulator; the cloud run itself is not yet checked.
- [x] 2026-10-13 — Split `ContentView.swift` into feature folders (`App/`, `Design/`, `History/`, `Modes/`, `Support/`), one file per mode view.
- [x] 2026-10-13 — Extract the per-mode views from computed properties into `View` types, and move the decision state and the six flows into `Modes/DecisionSession.swift` (Option B).
- [x] 2026-10-13 — Move `playSound` into a small `SoundPlayer` type.
