//
//  YesNoGoApp.swift
//  Yes? No? Go!
//
//  Created by Geoffrey Silva on 11/2/25.
//

import SwiftUI
import AppIntents

@main
struct YesNoGoApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onOpenURL { url in
                    handleDeepLink(url)
                }
                .onContinueUserActivity("FlipCoinIntent") { _ in
                    // Handle Siri shortcuts
                    QuickActionManager.shared.pendingQuickAction = "\(Bundle.main.bundleIdentifier ?? "").flipcoin"
                }
                .onContinueUserActivity("YesNoDecisionIntent") { _ in
                    QuickActionManager.shared.pendingQuickAction = "\(Bundle.main.bundleIdentifier ?? "").yesno"
                }
                .onContinueUserActivity("CustomChoiceIntent") { _ in
                    QuickActionManager.shared.pendingQuickAction = "\(Bundle.main.bundleIdentifier ?? "").custom"
                }
        }
    }
    
    init() {
        // Register App Shortcuts
        YesNoGoShortcuts.updateAppShortcutParameters()
    }
    
    private func handleDeepLink(_ url: URL) {
        // Handle deep links from quick actions
        guard url.scheme == "yesnogo" else { return }
        
        switch url.host {
        case "coin":
            QuickActionManager.shared.pendingQuickAction = "\(Bundle.main.bundleIdentifier ?? "").flipcoin"
        case "yesno":
            QuickActionManager.shared.pendingQuickAction = "\(Bundle.main.bundleIdentifier ?? "").yesno"
        case "custom":
            QuickActionManager.shared.pendingQuickAction = "\(Bundle.main.bundleIdentifier ?? "").custom"
        default:
            break
        }
    }
}