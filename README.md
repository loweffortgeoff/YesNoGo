# Yes? No? Go!

A random decision maker for iOS — 6 modes to help you decide anything, instantly.

![Platform](https://img.shields.io/badge/platform-iOS%2018.0+-blue)
![Swift](https://img.shields.io/badge/Swift-6-orange)
![SwiftUI](https://img.shields.io/badge/UI-SwiftUI-purple)

## Overview

Can't decide? Yes? No? Go! gives you six ways to make a choice — flip a coin, ask yes or no, pick from custom options, play rock paper scissors, consult the magic orb, or generate a random number. With widgets, Siri Shortcuts, haptic feedback, and a per-mode results log.

## Features

### Decision Modes
- **Coin Flip** — Heads or tails with animated rotation and sound effects
- **Yes / No** — Binary answer generator with animated reveal
- **Custom Picker** — Add 2–6 options and let the app choose
- **Rock Paper Scissors** — Emoji-based game play
- **Magic Orb** — Fortune-teller style mystical responses
- **Random Number** — Generate within a custom range

### Past Results Log
- Per-mode history with recent results and timestamps
- Mode-specific statistics (percentages, averages, most-picked)
- Clear history per mode with confirmation

### Extras
- **Quick Actions** — 3D Touch shortcuts for instant access to any mode
- **Siri Shortcuts** — Voice command support via AppIntents
- **Home Screen Widgets** — Quick access from the home and lock screens
- **Haptic Feedback** — Sensory feedback on selection and every result
- **Sound Effects** — Custom audio for different outcomes
- **Localization** — Multi-language support
- **Accessibility** — VoiceOver, high contrast, and reduce motion support
- **Tip Jar** — Optional in-app purchases (4 tiers)

## Tech Stack

| Technology | Purpose |
|-----------|---------|
| **SwiftUI** | All UI — views, animations, themes |
| **WidgetKit** | Home screen & lock screen widgets |
| **AppIntents** | Siri Shortcuts integration |
| **AVFoundation** | Sound effect playback |
| **AudioToolbox** | Haptic feedback |
| **StoreKit** | Tip jar purchases |

## Project Structure

```
Yes? No? Go!/
├── YesNoGoApp.swift            # App entry point
├── AppDelegate.swift           # Installs the scene delegate
├── SceneDelegate.swift         # Quick action and deep link delivery
├── ContentView.swift           # Mode coordinator, decision flows, sound
├── ModeTheme.swift             # Brand palette and the DecisionMode type
├── DecisionComponents.swift    # Canvas, card, mode selector, action button
├── DecisionData.swift          # Orb responses, RPS choices, custom options
├── HistoryManager.swift        # Past results storage & stats
├── HistoryView.swift           # Per-mode history & statistics UI
├── AppIntents.swift            # Siri Shortcuts definitions
├── TipJarManager.swift         # StoreKit purchases
├── TipJarView.swift            # Tip jar UI
└── L10n.swift                  # Localization helper

Repository root (shared with the app template)
├── AboutSectionView.swift      # Cross-app about section
└── *.mp3                       # Sound effects

YesNoGoWidget/
├── YesNoGoWidget.swift         # Widget definition
└── ...
```

## Design Notes

The app is one navy canvas. Each mode supplies a single muted accent, used only
for the hero element, the selected mode, and the primary action button. There
are no full-bleed gradients — see `DECISIONS.md` for why.

Deep links use the `yesnogo://` scheme (`yesnogo://coin`, `yesnogo://yesno`,
`yesnogo://custom`, `yesnogo://rps`, `yesnogo://orb`, `yesnogo://rng`). The
widgets rely on it. Home Screen quick actions use shortcut item types instead.

## Localization

Supported languages: English, Spanish, French, Italian, Portuguese (Brazil)

## Privacy

- No analytics or tracking
- No third-party dependencies
- No data collection

## Developer

Built by [Low Effort Apps](https://www.loweffortapps.app)
