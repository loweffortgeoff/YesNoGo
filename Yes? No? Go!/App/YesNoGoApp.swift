//
//  YesNoGoApp.swift
//  Yes? No? Go!
//
//  Created by Geoffrey Silva on 11/2/25.
//

import SwiftUI
import AppIntents
#if canImport(UIKit)
import UIKit
#endif

@main
struct YesNoGoApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    registerLocalizedQuickActions()
                }
                .onContinueUserActivity("FlipCoinIntent") { _ in
                    QuickActionManager.shared.requestedMode = .coin
                }
                .onContinueUserActivity("YesNoDecisionIntent") { _ in
                    QuickActionManager.shared.requestedMode = .yesno
                }
                .onContinueUserActivity("CustomChoiceIntent") { _ in
                    QuickActionManager.shared.requestedMode = .custom
                }
                .onContinueUserActivity("RPSIntent") { _ in
                    QuickActionManager.shared.requestedMode = .rps
                }
        }
    }
    
    init() {
        // Register App Shortcuts
        YesNoGoShortcuts.updateAppShortcutParameters()
    }

    @MainActor
    private func registerLocalizedQuickActions() {
        #if os(iOS)
        let bundleID = Bundle.main.bundleIdentifier ?? ""

        UIApplication.shared.shortcutItems = [
            UIApplicationShortcutItem(
                type: "\(bundleID).flipcoin",
                localizedTitle: L10n.string("quick_action.flip.title", fallback: "Flip Coin"),
                localizedSubtitle: L10n.string("quick_action.flip.subtitle", fallback: "Get heads or tails"),
                icon: UIApplicationShortcutIcon(type: .play),
                userInfo: nil
            ),
            UIApplicationShortcutItem(
                type: "\(bundleID).yesno",
                localizedTitle: L10n.string("quick_action.yesno.title", fallback: "Yes or No"),
                localizedSubtitle: L10n.string("quick_action.yesno.subtitle", fallback: "Make a decision"),
                icon: UIApplicationShortcutIcon(type: .search),
                userInfo: nil
            ),
            UIApplicationShortcutItem(
                type: "\(bundleID).custom",
                localizedTitle: L10n.string("quick_action.custom.title", fallback: "Random Choice"),
                localizedSubtitle: L10n.string("quick_action.custom.subtitle", fallback: "Pick from options"),
                icon: UIApplicationShortcutIcon(type: .shuffle),
                userInfo: nil
            ),
        ]
        #endif
    }
}
