//
//  AppDelegate.swift
//  Yes? No? Go!
//
//  The project generates a scene manifest, so this app is scene based. Home
//  Screen quick actions arrive on the scene delegate, never on the app
//  delegate. This delegate only installs the scene delegate.
//

import UIKit

final class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        configurationForConnecting connectingSceneSession: UISceneSession,
        options: UIScene.ConnectionOptions
    ) -> UISceneConfiguration {
        let configuration = UISceneConfiguration(
            name: "Default Configuration",
            sessionRole: connectingSceneSession.role
        )
        configuration.delegateClass = SceneDelegate.self
        return configuration
    }
}
