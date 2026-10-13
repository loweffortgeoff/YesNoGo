//
//  ModeTheme.swift
//  Yes? No? Go!
//
//  Brand palette and per-mode accents.
//  The palette is anchored on the app icon: deep navy, gold, and silver.
//

import Foundation
import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

// MARK: - Palette

/// Colors shared by every mode.
enum Palette {
    /// The base color behind the soft accent wash.
    static let canvas = Color.adaptive(light: 0xEFF2F7, dark: 0x0E131C)
    /// The elevated card surface.
    static let surface = Color.adaptive(light: 0xFFFFFF, dark: 0x1C2534)
    /// Inset fill for text fields and result wells.
    static let field = Color.adaptive(light: 0xECF0F5, dark: 0x2A3547)
    /// Positive outcomes, for example a "yes" answer.
    static let success = Color.adaptive(light: 0x2E8B57, dark: 0x6FD39B)
    /// Negative outcomes, for example a "no" answer.
    static let danger = Color.adaptive(light: 0xBE4A3C, dark: 0xF08A7C)
    /// Muted silver, drawn from the coin in the app icon.
    static let silver = Color.adaptive(light: 0x7C8798, dark: 0xAEB9C8)
    /// Necklace gold, drawn from the coin in the app icon.
    static let gold = Color.adaptive(light: 0xB07E1C, dark: 0xEBC26C)
}

// MARK: - Mode Theme

/// The three colors that give a mode its identity.
struct ModeTheme: Equatable {
    /// Fill color for the hero element and the primary action button.
    let accent: Color
    /// Foreground color placed on top of `accent`.
    let onAccent: Color
    /// Contrast-safe accent for icons and small text on the canvas.
    let tint: Color

    /// Strength of the background wash, tuned per appearance.
    func washStrength(dark: Bool) -> Double {
        dark ? 0.26 : 0.18
    }
}

// MARK: - Decision Mode

/// The six decision modes. One case owns the mode id, icon, label, and theme.
enum DecisionMode: String, CaseIterable, Identifiable {
    case coin
    case yesno
    case custom
    case rps
    case orb
    case rng

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .coin: return "centsign.circle"
        case .yesno: return "questionmark.circle"
        case .custom: return "shuffle"
        case .rps: return "hand.raised"
        case .orb: return "bubbles.and.sparkles.fill"
        case .rng: return "number.circle"
        }
    }

    /// Full mode name, shown as the navigation title and to VoiceOver.
    var label: String {
        switch self {
        case .coin: return L10n.string("mode.coin", fallback: "Coin Flip")
        case .yesno: return L10n.string("mode.yesno", fallback: "Yes / No")
        case .custom: return L10n.string("mode.custom", fallback: "Custom")
        case .rps: return L10n.string("mode.rps", fallback: "RPS")
        case .orb: return L10n.string("mode.orb", fallback: "Orb")
        case .rng: return L10n.string("mode.rng", fallback: "RNG")
        }
    }

    /// Suffix of the home screen quick action and deep link registered by the app.
    var quickActionSuffix: String {
        switch self {
        case .coin: return "flipcoin"
        case .yesno: return "yesno"
        case .custom: return "custom"
        case .rps: return "rps"
        case .orb: return "orb"
        case .rng: return "rng"
        }
    }

    /// Whether the mode can produce a result with no further input.
    /// Custom and RNG need the user to enter a value first.
    var runsOnOpen: Bool {
        switch self {
        case .coin, .yesno, .rps, .orb: return true
        case .custom, .rng: return false
        }
    }

    // MARK: - External Entry Points

    /// The custom URL scheme the app registers, used by the widgets.
    static let urlScheme = "yesnogo"

    /// Resolves a Home Screen quick action type, for example
    /// `com.example.app.flipcoin`.
    static func fromQuickActionType(_ type: String) -> DecisionMode? {
        let bundleID = Bundle.main.bundleIdentifier ?? ""
        return allCases.first { type == "\(bundleID).\($0.quickActionSuffix)" }
    }

    /// Resolves a deep link such as `yesnogo://coin`.
    static func fromDeepLink(_ url: URL) -> DecisionMode? {
        guard url.scheme == urlScheme, let host = url.host else { return nil }
        return DecisionMode(rawValue: host)
    }

    var theme: ModeTheme {
        switch self {
        case .coin:
            return ModeTheme(
                accent: .adaptive(light: 0xE0B053, dark: 0xE8C06B),
                onAccent: .adaptive(light: 0x2A2004, dark: 0x241B03),
                tint: .adaptive(light: 0x9A6E17, dark: 0xF0CC80)
            )
        case .yesno:
            return ModeTheme(
                accent: .adaptive(light: 0x4C7ED8, dark: 0x8AAFF1),
                onAccent: .adaptive(light: 0xFFFFFF, dark: 0x0A1730),
                tint: .adaptive(light: 0x2F5FA8, dark: 0xA8C6FF)
            )
        case .custom:
            return ModeTheme(
                accent: .adaptive(light: 0x4E9E6E, dark: 0x83CBA1),
                onAccent: .adaptive(light: 0xFFFFFF, dark: 0x0A1F14),
                tint: .adaptive(light: 0x2F6B49, dark: 0xA7DFBB)
            )
        case .rps:
            return ModeTheme(
                accent: .adaptive(light: 0xCE6A58, dark: 0xEE9584),
                onAccent: .adaptive(light: 0xFFFFFF, dark: 0x2B1009),
                tint: .adaptive(light: 0xA84A38, dark: 0xF7B6A8)
            )
        case .orb:
            return ModeTheme(
                accent: .adaptive(light: 0x7B68C9, dark: 0xA996EA),
                onAccent: .adaptive(light: 0xFFFFFF, dark: 0x181033),
                tint: .adaptive(light: 0x56449B, dark: 0xC8BAFF)
            )
        case .rng:
            return ModeTheme(
                accent: .adaptive(light: 0x3E9498, dark: 0x74C7CB),
                onAccent: .adaptive(light: 0xFFFFFF, dark: 0x07201F),
                tint: .adaptive(light: 0x266A6E, dark: 0x9EDDE0)
            )
        }
    }
}

// MARK: - Adaptive Color Helper

extension Color {
    /// Builds a color that resolves differently in light and dark appearance.
    static func adaptive(light: UInt32, dark: UInt32) -> Color {
        #if canImport(UIKit)
        return Color(uiColor: UIColor { traits in
            UIColor(rgbHex: traits.userInterfaceStyle == .dark ? dark : light)
        })
        #else
        return Color(rgbHex: light)
        #endif
    }

    /// Builds a color from a packed 0xRRGGBB value.
    init(rgbHex: UInt32) {
        self.init(
            .sRGB,
            red: Double((rgbHex >> 16) & 0xFF) / 255,
            green: Double((rgbHex >> 8) & 0xFF) / 255,
            blue: Double(rgbHex & 0xFF) / 255,
            opacity: 1
        )
    }
}

#if canImport(UIKit)
private extension UIColor {
    convenience init(rgbHex: UInt32) {
        self.init(
            red: CGFloat((rgbHex >> 16) & 0xFF) / 255,
            green: CGFloat((rgbHex >> 8) & 0xFF) / 255,
            blue: CGFloat(rgbHex & 0xFF) / 255,
            alpha: 1
        )
    }
}
#endif
