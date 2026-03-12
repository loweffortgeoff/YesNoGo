# Yes? No? Go!

A random decision maker for iOS — 6 modes to help you decide anything, instantly.

![Platform](https://img.shields.io/badge/platform-iOS%2018.6+-blue)
![Swift](https://img.shields.io/badge/Swift-6-orange)
![SwiftUI](https://img.shields.io/badge/UI-SwiftUI-purple)

## Overview

Can't decide? Yes? No? Go! gives you six ways to make a choice — flip a coin, ask yes or no, pick from custom options, play rock paper scissors, consult the magic orb, or generate a random number. With widgets, Siri Shortcuts, and haptic feedback.

## Features

### Decision Modes
- **Coin Flip** — Heads or tails with animated rotation and sound effects
- **Yes / No** — Binary answer generator with animated reveal
- **Custom Picker** — Add 2–6 options and let the app choose
- **Rock Paper Scissors** — Emoji-based game play
- **Magic Orb** — Fortune-teller style mystical responses
- **Random Number** — Generate within a custom range

### Extras
- **Quick Actions** — 3D Touch shortcuts for instant access to any mode
- **Siri Shortcuts** — Voice command support via AppIntents
- **Home Screen Widgets** — Quick access from the home and lock screens
- **Live Activities** — Dynamic Island experiences
- **Haptic Feedback** — Impact, selection, and notification haptics
- **Sound Effects** — Custom audio for different outcomes
- **Accessibility** — VoiceOver, high contrast, and reduce motion support
- **Tip Jar** — Optional in-app purchases (4 tiers)

## Tech Stack

| Technology | Purpose |
|-----------|---------|
| **SwiftUI** | All UI — views, animations, themes |
| **WidgetKit** | Home screen & lock screen widgets |
| **AppIntents** | Siri Shortcuts integration |
| **ActivityKit** | Live Activities |
| **AVFoundation** | Sound effect playback |
| **AudioToolbox** | Haptic feedback |
| **StoreKit** | Tip jar purchases |

## Project Structure

```
Yes? No? Go!/
├── YesNoGoApp.swift            # App entry point
├── ContentView.swift           # All modes & UI logic
├── QuickActionManager.swift    # 3D Touch shortcuts
├── TipJarManager.swift         # StoreKit purchases
├── AboutSectionView.swift      # Cross-app about section
└── Audio/                      # Sound effect files

YesNoGoWidget/
├── YesNoGoWidget.swift         # Widget definition

YesNoGoWidgetExtension/
└── Widget extension bundle
```

## Privacy

- No analytics or tracking
- No third-party dependencies
- No data collection

## Developer

Built by [Low Effort Apps](https://www.loweffortapps.dev)
