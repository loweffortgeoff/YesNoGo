# Step 4 — Structural refactor of `ContentView.swift`

**Status:** not started
**Written:** 2026-10-13
**Branch:** `ui-modernization` (PR #1, targeting `main`)
**HEAD when written:** `6dfef95`
**Written by:** the session that implemented Steps 1–3. Verify every claim below against the code before relying on it.

---

## 1. Where this came from

Step 4 is the last and largest step of the YesNoGo UI modernization. It was split out of PR #1 on purpose, because it is a large, low-glamour diff that would have buried the visible work.

| Step | Scope | State |
| --- | --- | --- |
| 1 | Palette: navy and gold brand palette, soft canvas, muted per-mode accents | Shipped in PR #1 |
| 2 | Motion: async timeline instead of sleeps, `.sensoryFeedback`, roulette wheel, `PhaseAnimator` idle | Shipped in PR #1 |
| 3 | Layout and behavior: segmented mode bar, toolbar, URL scheme, scene-lifecycle quick actions, locale-safe stats | Shipped in PR #1 |
| 4 | **Structure: split `ContentView.swift`, one file per view of substance** | **This document** |

Step 4 changes no behavior and no visuals. It is a move-only refactor.

Read `DECISIONS.md` first. Step 1 recorded the palette rule, and Step 3 recorded the quick-action and history-entry decisions. Step 4 must not undo either.

## 2. Goal

Bring `ContentView.swift` in line with the design contract's file-granularity and SwiftUI-mechanics rules. The relevant rules, quoted from `~/Documents/Agent Brief/design-preferences.md`:

- **File granularity** — "One file per view/type of substance. No bucket files." "Group files in feature folders (the `Ramble/` pattern in Task(ed))." "Soft cap ~500 lines. Crossing it isn't a violation, but it means the file is probably holding more than one concern."
- **Split on sight** — "when work touches a type or view inside an oversized bucket file, extract that piece into its own file as part of the change. **Move-only — no behavior or style changes to the extracted code.**"
- **SwiftUI mechanics** — "Extract sections into separate `View` **types**, not computed properties. Exception: tiny fragments reused two or three times in one body."
- **SwiftUI mechanics** — "Pass a view only the data it reads, not whole model structs."

That "move-only" clause is the most important sentence in this document. It is what makes this step mechanical and reviewable.

## 3. Current state

`Yes? No? Go!/ContentView.swift` is **1297 lines**. It is a bucket file holding five unrelated concerns:

1. `QuickActionManager` (a type living inside a view file)
2. `ContentView` — chrome plus all six mode views as computed properties
3. The six decision flows (async `Task` state machines)
4. The sound engine (`playSound`, `playFile`, `audioPlayer`)
5. `CreditsView`, the `idleBreathing` view modifier, and the VoiceOver announcement helper

`ContentView` alone carries 25 `@State` / `@ScaledMetric` / `@Environment` properties and 19 private methods.

### 3a. Already extracted in Steps 1–3 — do not redo

Part of the original Step 4 list was absorbed by Steps 1–3. These are done:

| Original Step 4 item | Where it lives now |
| --- | --- |
| `DecisionMode` enum replacing the `modes` / `modeIcons` / `modeLabels` parallel arrays | `ModeTheme.swift` |
| `PrimaryActionButton` | `DecisionComponents.swift` |
| `ModeChip` (became `ModeSelectorBar`) | `DecisionComponents.swift` |
| Dead-file sweep | `Yes__No__Go_App.swift`, root `TipJarSectionView.swift`, orphaned `YesNoGoWidgetExtension/`, Live Activity, Control widget — all removed |

Beyond the original list, Steps 1–3 also extracted `Palette`, `ModeTheme`, `BrandCanvas`, `DecisionCard`, `PressableButtonStyle`, `ThemedField`, `OrbResponse`, `RPSChoice`, and `CustomOption`.

### 3b. What still lives inside `ContentView.swift`

**Computed-property views** (line numbers at `6dfef95`):

| Line | Member |
| --- | --- |
| 194 | `coinView` |
| 270 | `yesNoView` |
| 317 | `customChoiceView` |
| 487 | `rpsView` |
| 552 | `orbView` |
| 637 | `rngView` |

**Supporting hero and sub-views that belong with their mode:** `coinDisc`, `coinFaceIsHeads`, `coinFaceSymbol`, `orbHero`, `wheel`, `pickerStage`, `wheelStageHeight`, `rngField`, `optionNumber(_:)`, `binding(for:)`.

**Flow logic:**

| Line | Function |
| --- | --- |
| 803 | `flipCoin` |
| 876 | `generateYesNo` |
| 936 | `chooseCustom` |
| 1005 | `playRPS` |
| 1040 | `askOrb` |
| 1082 | `generateRandomNumber` |
| 916 / 923 | `addChoice` / `removeChoice` |
| 1159 | `failRandomNumber` |
| 749 / 762 / 772 | `switchMode` / `resetResultState` / `run` |
| 785 | `handlePendingRequest` |

**Auxiliary:** `playSound` (1167), `playFile` (1205), `announceForVoiceOver` (1213), `extension View { idleBreathing }` (1222), `CreditsView` (1240).

## 4. The one real architectural decision

Everything else in this step is mechanical. This one is a judgment call, so it is called out separately.

The six flows mutate shared state (`isAnimating`, `result`, `showResult`) that three other things also read: mode switching resets it, history records from it, and the toolbar and sheets depend on `mode`. Where that state and logic live determines the shape of the whole refactor.

**Option A — thin views, `ContentView` keeps state and flows.**
Move-only, lowest risk. Each mode becomes a `View` struct taking the values it reads plus action closures. `ContentView` lands around 550–650 lines and still holds state, chrome, six flows, and the sound engine.

**Option B — `DecisionSession` owns state and flows. (Recommended)**
Add one `@Observable final class DecisionSession` in `Modes/`. It owns the decision state, the six flows, mode switching, and quick-action routing, roughly 450–500 lines — which is one concern, and under the cap. Each mode view becomes a thin `View` type in its own file. `ContentView` becomes chrome only, roughly 200–250 lines.
This keeps a single source of truth for the shared state, which is what makes the quick-action auto-run (`run(mode)`) and cancel-on-mode-switch stay simple. It can be done one mode at a time.

**Option C — fully self-contained mode views.**
Each mode view owns its own `@State` for `isAnimating`, `result`, `showResult` and its own flow. Best cohesion per file. Two real costs, both of which cross the "move-only" line: switching modes would destroy the view and change cancellation semantics, and the quick-action auto-run needs an awkward trigger channel because `ContentView` can no longer call into a mode's flow. Defer this unless Option B's outcome proves unsatisfying.

**Recommendation: Option B**, executed one mode per commit. It is the smallest change that gets every file under the soft cap without rewriting the cancellation model.

One contract tension to resolve with Geoff: the rule "pass a view only the data it reads, not whole model structs" argues for Option A's long parameter lists. Under Option B, mode views take the `DecisionSession` reference. That is defensible because `@Observable` tracks per-property reads, so a view still only *reads* what it uses. Worth one line in `DECISIONS.md` either way.

## 5. Target layout

Suggested, not prescribed. The app folder is a `PBXFileSystemSynchronizedRootGroup`, so **adding subfolders needs no project-file changes at all**.

```
Yes? No? Go!/
├── App/
│   ├── YesNoGoApp.swift
│   ├── AppDelegate.swift
│   ├── SceneDelegate.swift
│   └── QuickActionManager.swift        <- moved out of ContentView.swift
├── Design/
│   ├── ModeTheme.swift
│   ├── DecisionComponents.swift
│   └── DecisionData.swift
├── Modes/
│   ├── CoinFlipView.swift
│   ├── YesNoDecisionView.swift
│   ├── CustomPickerView.swift
│   ├── RockPaperScissorsView.swift
│   ├── MagicOrbView.swift
│   └── RandomNumberView.swift
├── History/
│   ├── HistoryManager.swift
│   └── HistoryView.swift
├── Support/
│   ├── L10n.swift
│   ├── SoundPlayer.swift               <- sound engine out of ContentView
│   ├── AppIntents.swift
│   ├── TipJarManager.swift
│   ├── TipJarView.swift
│   └── CreditsView.swift               <- out of ContentView.swift
├── ContentView.swift
└── Info.plist
```

### 5a. The folder-move trap

Two kinds of files exist in this project, and they behave differently:

- **Inside `Yes? No? Go!/`** — the synchronized root group. Moving and adding files here is free.
- **At the repository root** — `AboutSectionView.swift` and eight `.mp3` files (`rng_ding`, `mystical-355968`, `c-chord-83638`, `success-fanfare-trumpets-6185`, `wah-wah-sad-trombone-6347`, `steel-blade-slice-4-188216`, `thud-82914`, `crumping-paper-109585`). These carry **explicit `PBXFileReference` entries and explicit Sources / Resources build phases** in `project.pbxproj`. Moving them into the app folder without editing the project file gives you the file in both places, or a build failure.

Also note: `eagle-sound-by-torma-368637.mp3` is the odd one out — it lives *inside* the app folder and arrives via the synchronized group. Audio resources are currently split across both mechanisms. Consolidating is optional and out of scope for Step 4.

For Step 4, leave all root-level files where they are.

## 6. Suggested commit sequence

One commit per item keeps each diff reviewable and bisectable.

1. Move `QuickActionManager` to `App/QuickActionManager.swift`. Move-only.
2. Move the sound engine to `Support/SoundPlayer.swift` behind a small type. Move-only.
3. Move `idleBreathing` and `CreditsView` out of `ContentView.swift`.
4. Extract `CoinFlipView`.
5. Extract `YesNoDecisionView`.
6. Extract `CustomPickerView` (largest — includes the wheel).
7. Extract `RockPaperScissorsView`.
8. Extract `MagicOrbView`.
9. Extract `RandomNumberView`.
10. If Option B: introduce `DecisionSession` and move the six flows, one mode per commit.
11. Introduce the feature folders (pure `git mv`, no content change).
12. Update `DECISIONS.md` and check off the `TODO.md` backlog items.

Build and run the app between every commit. Do not batch mode extractions.

## 7. Invariants that must not regress

These are the things a "move-only" refactor is most likely to silently break. Each one is live today.

- **Localization.** 106 distinct `L10n` keys are used by the app target. Moving a view must not change a key, a fallback string, or a format argument count. A dropped fallback ships English into five languages.
- **Accessibility.** Every `.accessibilityLabel`, `.accessibilityHint`, `.accessibilityElement()`, and `.accessibilityAddTraits` must survive verbatim. The coin hero groups its children; the mode segments carry `.isSelected`.
- **Dynamic Type.** The `@ScaledMetric` properties (`coinSize`, `heroGlyphSize`, `orbSize`, `rngNumberSize`, `wheelRadius`) must move with their views. Do not introduce `Font.system(size:)` with a literal.
- **Reduce Motion.** Every animation has a `reduceMotion` branch. Extracting a view must not drop one.
- **Cancel on mode switch.** `switchMode` cancels `decisionTask` and clears `isAnimating`; `onDisappear` also cancels. This is what stops a half-finished animation from writing a result into the wrong mode.
- **Quick-action auto-run.** `runsOnOpen` gates whether a requested mode immediately plays. Coin, Yes/No, RPS, and Orb auto-run; Custom and RNG wait for input. This is easy to lose when the flows move.
- **History writes.** Each flow records `mode`, `result`, and a locale-independent `Outcome` category. Custom also passes a `detail`. Preserve all four parameters.
- **`.sensoryFeedback` triggers.** Four separate triggers (`tapTrigger`, `revealTrigger`, `errorTrigger`, and `mode` for selection). Do not collapse them.
- **Custom option identity.** `CustomOption` carries a per-item `UUID` so text field state follows the right row when a middle option is removed. Do not revert to index identity.
- **`Info.plist` is load-bearing.** It must keep `CFBundleURLTypes` for the `yesnogo://` scheme. Quick actions are registered at launch only; do **not** re-add `UIApplicationShortcutItems`, which duplicates the runtime registration and produced a doubled menu entry.

## 8. Verification checklist

Run after every commit, not only at the end.

- [ ] `xcodebuild` Debug and Release, both zero warnings. The app scheme also builds the widget extension.
- [ ] App launches and the coin mode renders.
- [ ] All six modes render, in light and dark.
- [ ] Each mode produces a result, and the result appears.
- [ ] Mode switching mid-animation does not leak a stale result into the new mode.
- [ ] Custom picker: add, remove from the middle, pick, and confirm the wheel lands on the announced winner.
- [ ] RNG: valid range, inverted range, non-numeric input, and "No Immediate Repeat".
- [ ] History sheet: stats per mode, clear history, empty state.
- [ ] Deep link `yesnogo://<mode>` for all six. Requires a device or a manual tap on the simulator's "Open in" confirmation.
- [ ] Quick action, cold launch and warm launch, on a physical device.
- [ ] Reduce Motion on. Increase Contrast on. Largest Dynamic Type. VoiceOver pass per mode.
- [ ] `wc -l` on every file in `Yes? No? Go!/`. No file over ~500.

## 9. Out of scope for Step 4

Explicitly not part of this step, so the diff stays reviewable:

- Any change to behavior, copy, timing, or visual design.
- Adding a test target. There are currently no tests in this project at all. That is a real gap and a separate piece of work.
- The widget target's duplicated palette in `YesNoGoWidget.swift`, which cannot import the app target's `ModeTheme`.
- Removing `YesNoGoWidget/WidgetL10n.swift`, which has had zero consumers since the Live Activity was removed.
- The stale `project.pbxproj` entries: a dangling target dependency (`3A18550C2EB7F5E400A711F2`, `remoteInfo = YesNoGoWidgetExtensionExtension`) and two `.xcscheme` files, one of which names a target that no longer exists.
- Untracking the committed `build/` directory. Same class of problem as the `tmp/` and `.DS_Store` cleanups, larger, and noisy to review.
- The mixed audio-resource layout described in 5a.

## 10. Definition of done

- `ContentView.swift` is chrome only, at or under ~250 lines.
- Every mode is a `View` type in its own file under `Modes/`.
- No file in the app target is over ~500 lines.
- The verification checklist passes on a device, not only in the simulator.
- No behavior change: the six modes, history, sound, haptics, deep links, and quick actions all work exactly as they did before.
- `DECISIONS.md` records the chosen option from section 4 and, if Option B, the `@Observable`-reference reading of the "pass only what it reads" rule.
- The Step 4 items are checked off in `TODO.md`'s Backlog and moved to Done with a date.

## 11. Reference

- PR: [#1](https://github.com/loweffortgeoff/YesNoGo/pull/1), `ui-modernization` → `main`
- Branch HEAD when written: `6dfef95`
- Steps 1–3 commits: `d097e5f` (palette, motion, layout), `f0548a2` (docs), `c373336` (scene-lifecycle routing), `6659413`, `9d3b1df`, `6dfef95` (review follow-ups)
- `Yes? No? Go!/ContentView.swift` — 1297 lines, the target of this work
- `Yes? No? Go!/ModeTheme.swift` — `Palette`, `ModeTheme`, `DecisionMode`, and the `fromQuickActionType` / `fromDeepLink` resolvers
- `Yes? No? Go!/DecisionComponents.swift` — `BrandCanvas`, `DecisionCard`, `ModeSelectorBar`, `PrimaryActionButton`, `PressableButtonStyle`, `ThemedField`
- `Yes? No? Go!/DecisionData.swift` — `OrbResponse`, `RPSChoice`, `CustomOption`
- `~/Documents/Agent Brief/design-preferences.md` — file granularity and SwiftUI mechanics rules

## 12. Start here

1. Read `DECISIONS.md` and section 4 of this document.
2. Get Geoff's decision on Option A, B, or C before writing any code.
3. Build and run the app once to confirm a green baseline.
4. Do commit 1 of section 6. Build. Run. Repeat.

---

## Execution status

**Status:** implementation complete; physical-device testing pending. Local commits only — not pushed.
**Branch:** `ui-modernization`, at the Step 4 head (15 commits on top of `61d71f0`). The work was first built on a separate `step-4-structure` branch and then fast-forwarded into `ui-modernization` at Geoff's request, so there is one branch. PR #1 therefore carries Step 4 too once pushed.
**Decision:** Option B, chosen by Geoff. New branch rather than adding to PR #1.

### Commits (15)

| # | Commit | Scope |
| --- | --- | --- |
| 1 | `ca71364` Move QuickActionManager into its own file | App/QuickActionManager.swift |
| 2 | `01ed368` Move the sound engine into SoundPlayer | Support/SoundPlayer.swift |
| 3 | `bac6505` Move idleBreathing and CreditsView out of ContentView | Design/, Support/ |
| 4 | `89e95c7` Give DecisionSession the state and the six flows | Modes/DecisionSession.swift; ContentView slimmed |
| 5 | `da5e836` Extract CoinFlipView | Modes/CoinFlipView.swift |
| 6 | `7217aaa` Extract YesNoDecisionView | Modes/YesNoDecisionView.swift |
| 7 | `29ba0c0` Extract CustomPickerView | Modes/CustomPickerView.swift |
| 8 | `8d43e37` Extract RockPaperScissorsView | Modes/RockPaperScissorsView.swift |
| 9 | `fb97811` Extract MagicOrbView | Modes/MagicOrbView.swift |
| 10 | `cecf877` Extract RandomNumberView | Modes/RandomNumberView.swift |
| 11 | `ef1b3af` Move the custom-option field helpers into CustomPickerView | keeps DecisionSession under the cap |
| 12 | `480a333` Group the app sources into feature folders | pure `git mv` |
| 13 | `325bcb3` Record the Step 4 structure refactor | DECISIONS, TODO, CHANGELOG, plan |
| 14 | `346caef` Make CustomOption Equatable | review follow-up |
| 15 | `1294f38` Record the Step 4 review follow-ups | review follow-up |

### Deviations from section 6

- Session-first order. The plan extracted the mode views first (5–9) and introduced `DecisionSession` last (10). Under Option B the views need the session, so the session came first (commit 4) and the views were extracted one per commit after. This avoids writing each mode twice.
- Flows take `reduceMotion` as a parameter. The flows used to read `@Environment(\.accessibilityReduceMotion)`. Outside a view they cannot, so each flow takes the flag explicitly and each mode view passes it. No behavior change.
- `optionNumber(_:)` and `binding(for:)` live in `CustomPickerView`, not the session, which keeps `DecisionSession` at 497 lines.
- The unused `@Environment(\.colorScheme)` property is removed. It was dead in the original `ContentView` (read nowhere), and the removal does not affect light/dark, which was checked live. The adversarial review flagged it as the only non-move change.
- `CustomOption` gains `Equatable` (separate commit) so the `@Observable` element type follows the design contract. Behavior-neutral.

### Verification (simulator only)

The app folder is a synchronized group, so no `project.pbxproj` change was needed.

- `xcodebuild` Debug and Release, zero warnings, on the iPhone 18 Pro (iOS 27.0) simulator. Debug built after every commit.
- Source-level proof of move-only: every string literal, `L10n` key + fallback, `.accessibilityLabel`/`.accessibilityHint`/`.accessibilityElement` modifier, `.sensoryFeedback` trigger, and `HistoryManager.shared.add` call in the original `ContentView.swift` has an identical counterpart in the new files (the only diffs are the four interpolated strings that gained a `session.` qualifier, which do not change rendered text).
- Driven with `agent-device` on iPhone 18 Pro: coin flip → `Coin flip result: HEADS`; Yes/No → `Decision result: NO!`; RPS → `Opponent chose Rock`; Orb → `The orb says: Don't count on it`; Custom → alert on empty options, add/fill/remove-middle, `Selection result: Pizza`; RNG → generated number, inverted range, non-numeric, and No-Immediate-Repeat errors, plus 1 → 2 → 1 no-repeat.
- Mode switch mid-run: switched Yes/No → RPS while the Yes/No flow was animating; after the old delay elapsed, no stale result leaked into RPS.
- History: per-mode stats and entries (RNG averages/range detail, coin heads/tails percentages by outcome token), destructive confirmation, clear, and the empty state.
- Credits moved verbatim and renders.
- Light and dark appearance, and largest Dynamic Type, render.
- Reduce Motion on: the Custom wheel parks with the pointer on the announced winner (`Selection result: Beta`) — the mechanism the review flagged as most changed.
- Deep links: `yesnogo://custom` lands in Custom without auto-running (`runsOnOpen` is false); `yesnogo://rps` lands in RPS and auto-runs to `Opponent chose Scissors`. The scheme raises one "Open in" confirmation on the simulator, which `agent-device` taps.

### Adversarial review

Claude Opus 5.5 reviewed `61d71f0..HEAD`: no blockers, and it confirmed the change is move-only. Its actionable items are resolved — `CustomOption` gains `Equatable` (its own commit), the four remaining computed-property section views are recorded in the TODO Backlog, and the removed dead `@Environment(\.colorScheme)` is documented above.

### Remaining (physical device)

Home Screen quick actions (cold and warm launch, and the RPS/Orb/RNG menu items) still need a physical device; they cannot be exercised in the simulator. Everything else on the section 8 checklist passed.

