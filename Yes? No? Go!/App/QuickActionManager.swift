//
//  QuickActionManager.swift
//  Yes? No? Go!
//
//  Carries a mode requested from outside the app: a Home Screen quick action, a
//  deep link, or a Siri continuation. The scene delegate sets it and the UI
//  consumes it.
//

import Observation

@Observable
final class QuickActionManager {
    static let shared = QuickActionManager()

    var requestedMode: DecisionMode?

    private init() {}
}
