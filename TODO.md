# YesNoGo TODO

## Next
- [ ] Create promo video for ASC
- [ ] Verify Home Screen quick actions on a physical device (cannot be exercised in the simulator)

## Planned
- [ ] Apple Watch App — Quick decisions from your wrist — coin flip and yes/no on watchOS

## Backlog
- [ ] Split `ContentView.swift` into feature folders (Coin, YesNo, Custom, RPS, Orb, RNG), one file per mode view. It is still ~1500 lines and holds all six modes.
- [ ] Extract the per-mode views from computed properties into `View` types, per the design contract.
- [ ] Move `playSound` into a small `SoundPlayer` type and preload the audio players.
- [ ] Localize the hardcoded English accessibility labels ("Past results", "Credits and information", "Close history", and others).
- [ ] Register Home Screen quick actions for RPS, Orb, and RNG. Only coin, yes/no, and custom exist today.
- [ ] Widget palette is duplicated in `YesNoGoWidget.swift` because the widget target does not share app sources. Consider a shared file added to both targets.
- [ ] `WidgetL10n.swift` now has no consumers after the Live Activity removal.
- [ ] Note on the design contract: `ForEach(Array(choices.enumerated()), id: \.offset)` is used for the picker wheel and RPS emoji, and index identity is used for the editable custom option list. Index identity is correct for the editable list; the two static collections could take element identity instead.
- [ ] Reboot-free way to reset a stuck simulator alert: two simulators had a pending location prompt that blocked app launch and could not be dismissed without rebooting the device.
- [ ] Performance: the custom option `Binding` is rebuilt on every keystroke. Fine at 6 options, worth watching if the limit grows.

## Developer Notes
- The app deploys to iOS 18.6, but the widget target deploys to 26.2. That mismatch is existing and unverified.
- The project file carries a dangling target dependency (`3A18550C2EB7F5E400A711F2`, `remoteInfo = YesNoGoWidgetExtensionExtension`) that refers to a target which no longer exists. Builds succeed, but it is stale.
- `YesNoGoWidgetExtension.xcscheme` and `YesNoGoWidgetExtensionExtension.xcscheme` are tracked. The second names a target that does not exist.
- The whole `build/` directory is committed to the repo.

## Exploring
- [ ] Group Decisions — Share a decision link with friends and see everyone's pick
- [ ] Custom Themes — Personalize the look with color themes and mode icons
