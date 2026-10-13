//
//  AppDelegate.swift
//  Yes? No? Go!
//
//  Home Screen quick action delivery. SwiftUI has no built-in handler for
//  `UIApplicationShortcutItem`, so the app adopts a delegate for it.
//

import UIKit

final class AppDelegate: NSObject, UIApplicationDelegate {
    /// Cold launch through a quick action.
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        if let item = launchOptions?[.shortcutItem] as? UIApplicationShortcutItem {
            QuickActionManager.shared.pendingQuickAction = item.type
        }
        return true
    }

    /// Quick action chosen while the app is already running or backgrounded.
    func application(
        _ application: UIApplication,
        performActionFor shortcutItem: UIApplicationShortcutItem,
        completionHandler: @escaping (Bool) -> Void
    ) {
        QuickActionManager.shared.pendingQuickAction = shortcutItem.type
        completionHandler(true)
    }
}
