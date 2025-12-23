//
//  AppIntents.swift
//  Yes? No? Go!
//
//  Created by Geoffrey Silva on 11/2/25.
//

import AppIntents
import Foundation

// MARK: - Flip Coin Intent
struct FlipCoinIntent: AppIntent {
    static var title: LocalizedStringResource = "Flip Coin"
    static var description = IntentDescription("Flip a coin to get heads or tails")
    static var openAppWhenRun: Bool = false
    
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let result = Bool.random() ? "HEADS" : "TAILS"
        let emoji = result == "HEADS" ? "👑" : "🦅"
        
        return .result(dialog: "\(emoji) \(result)!")
    }
}

// MARK: - Yes/No Decision Intent
struct YesNoDecisionIntent: AppIntent {
    static var title: LocalizedStringResource = "Yes or No Decision"
    static var description = IntentDescription("Get a random yes or no answer")
    static var openAppWhenRun: Bool = false
    
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let result = Bool.random() ? "YES" : "NO"
        let emoji = result == "YES" ? "✅" : "❌"
        
        return .result(dialog: "\(emoji) \(result)!")
    }
}

// MARK: - Custom Choice Intent
struct CustomChoiceIntent: AppIntent {
    static var title: LocalizedStringResource = "Pick Random Choice"
    static var description = IntentDescription("Pick a random choice from your custom options")
    static var openAppWhenRun: Bool = false
    
    @Parameter(title: "Options", description: "Enter your options separated by commas")
    var options: String
    
    static var parameterSummary: some ParameterSummary {
        Summary("Pick from \(\.$options)")
    }
    
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let choices = options.components(separatedBy: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        
        guard choices.count >= 2 else {
            throw AppIntentError.custom("Please provide at least 2 options separated by commas")
        }
        
        guard let randomChoice = choices.randomElement() else {
            throw AppIntentError.custom("Unable to pick a choice")
        }
        
        return .result(dialog: "🎉 The winner is: \(randomChoice)")
    }
}

// MARK: - Rock Paper Scissors Intent
struct RPSIntent: AppIntent {
    static var title: LocalizedStringResource = "Rock Paper Scissors"
    static var description = IntentDescription("Get a random rock, paper, or scissors choice")
    static var openAppWhenRun: Bool = false

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let choices = ["Rock", "Paper", "Scissors"]
        let emojis = ["🪨", "📄", "✂️"]
        let index = Int.random(in: 0..<3)

        return .result(dialog: "\(emojis[index]) \(choices[index])!")
    }
}

// MARK: - App Intent Error
enum AppIntentError: Swift.Error, CustomLocalizedStringResourceConvertible {
    case custom(String)
    
    var localizedStringResource: LocalizedStringResource {
        switch self {
        case .custom(let message):
            return LocalizedStringResource(stringLiteral: message)
        }
    }
}

// MARK: - App Shortcuts Provider
struct YesNoGoShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: FlipCoinIntent(),
            phrases: [
                "Flip a coin in \(.applicationName)",
                "Heads or tails with \(.applicationName)",
                "Coin flip in \(.applicationName)"
            ],
            shortTitle: "Flip Coin",
            systemImageName: "centsign.circle"
        )
        
        AppShortcut(
            intent: YesNoDecisionIntent(),
            phrases: [
                "Yes or no in \(.applicationName)",
                "Make a decision with \(.applicationName)",
                "Yes or no decision in \(.applicationName)"
            ],
            shortTitle: "Yes or No",
            systemImageName: "questionmark.circle"
        )
        
        AppShortcut(
            intent: CustomChoiceIntent(),
            phrases: [
                "Pick random choice in \(.applicationName)",
                "Choose randomly with \(.applicationName)",
                "Random selection in \(.applicationName)"
            ],
            shortTitle: "Random Choice",
            systemImageName: "shuffle"
        )

        AppShortcut(
            intent: RPSIntent(),
            phrases: [
                "Rock paper scissors in \(.applicationName)",
                "Play rock paper scissors with \(.applicationName)",
                "RPS in \(.applicationName)"
            ],
            shortTitle: "Rock Paper Scissors",
            systemImageName: "hand.raised"
        )
    }
}