# Release Notes — next version (version number to be set; the project is at 1.6.4)

Theme: Yes? No? Go! gets a new look and a working widget. The six loud gradients are gone. The app is now one navy canvas with a single muted accent per mode. Widgets and Home Screen quick actions now work as intended.

## NEW

- New look. A navy canvas with navy, gold and silver, matched to the app icon. Each mode has one muted accent. It marks the main picture, the selected mode and the main button.
- The mode name is now the screen title. History and credits are in the toolbar.
- The mode bar has six equal-width buttons. The sixth mode is no longer cut off.
- Coin faces are a gold crown and a gold bird, not emoji.
- The Custom picker is now a spinning wheel with a pointer.
- The Magic Orb moves gently while it waits.
- Numbers in Random Number roll when they change.

## IMPROVED

- Text uses the system colors and scales with your text size. The big symbols and the Random Number also scale.
- Haptics use the newer system haptic feedback.
- Animations run on a smoother timeline.
- The widget uses the same palette as the app. Its symbols now match the modes.

## FIXED

- Widget taps did nothing. They now open the right mode.
- Home Screen quick actions did nothing, and a cold launch lost the action. They now work from a cold and a warm start.
- The quick action menu showed "Flip Coin" twice. It now shows each action once.
- A quick action could run after you had moved to another mode. It now runs only if its mode is still on screen.
- Rock Paper Scissors emoji kept bobbing after the result. They now settle.
- With Reduce Motion on, the Custom wheel pointer showed the wrong option. It now matches the winner.
- History statistics were wrong in languages other than English. They now work in every language, and old entries still count.
- Option rows in Custom keep your typing with the right row when you remove another row.

## What to Test

Paste into the TestFlight "What to Test" field.

This build changes the look of every screen and fixes widgets and quick actions. Please test on a real iPhone if you can.

- Open each of the six modes. Run each one a few times. Check that the colors, the animation, the sound and the result all look right.
- Quick actions (press and hold the app icon). Check that you see Flip Coin, Yes or No and Custom, each once. Tap each one. Do this once after you force-close the app, and once while the app is open in the background.
- Widgets: add one to the Home Screen or Lock Screen. Tap it. The app must open on the matching mode.
- Custom: add 2 to 6 options and spin. The pointer must point at the option the app announces. Remove an option from the middle of the list. Your typing must stay with the right rows.
- Rock Paper Scissors: after the result, the emoji must stop moving and must not overlap the caption.
- History: open it for each mode. Check the list, the percentages and the averages. Clear one mode.
- Turn on Reduce Motion in Settings. Run each mode. The result must still be correct.
- Use a larger text size in Settings. Check that the mode bar, the buttons and the big result still fit.
- Set the phone to Spanish, French, Italian or Portuguese (Brazil). Run a few coin flips and open History. The percentages must be right.
- Upgrade from the App Store version with old history. Check that your old results still show.
- Tip Jar: open it. Tiers must show App Store prices. TestFlight purchases are free.
- Tell us about any screen where text is cut off, hard to read, or the wrong color.
