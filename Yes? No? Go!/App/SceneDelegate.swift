//
//  SceneDelegate.swift
//  Yes? No? Go!
//
//  External entry points. The app is scene based, so UIKit delivers Home Screen
//  quick actions and incoming URLs to the scene delegate, never to the app
//  delegate. Both are forwarded to `QuickActionManager` for the UI to pick up.
//

import UIKit

final class SceneDelegate: NSObject, UIWindowSceneDelegate {
    /// Launching the app, optionally through a quick action or a deep link.
    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        if let item = connectionOptions.shortcutItem {
            request(DecisionMode.fromQuickActionType(item.type))
        }

        if let url = connectionOptions.urlContexts.first?.url {
            request(DecisionMode.fromDeepLink(url))
        }
    }

    /// Quick action chosen while the app is already running or backgrounded.
    func windowScene(
        _ windowScene: UIWindowScene,
        performActionFor shortcutItem: UIApplicationShortcutItem,
        completionHandler: @escaping (Bool) -> Void
    ) {
        request(DecisionMode.fromQuickActionType(shortcutItem.type))
        completionHandler(true)
    }

    /// Deep link opened while the app is already running or backgrounded.
    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        guard let url = URLContexts.first?.url else { return }
        request(DecisionMode.fromDeepLink(url))
    }

    private func request(_ mode: DecisionMode?) {
        guard let mode else { return }
        QuickActionManager.shared.requestedMode = mode
    }
}
