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
        let isHeads = Bool.random()
        let result = isHeads
            ? L10n.string("intent.flip.result.heads", fallback: "HEADS")
            : L10n.string("intent.flip.result.tails", fallback: "TAILS")
        let emoji = isHeads ? "👑" : "🦅"

        return .result(dialog: L10n.format("intent.flip.dialog.format", fallback: "%@ %@!", emoji, result))
    }
}

// MARK: - Yes/No Decision Intent
struct YesNoDecisionIntent: AppIntent {
    static var title: LocalizedStringResource = "Yes or No Decision"
    static var description = IntentDescription("Get a random yes or no answer")
    static var openAppWhenRun: Bool = false
    
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let isYes = Bool.random()
        let result = isYes
            ? L10n.string("intent.yesno.result.yes", fallback: "YES")
            : L10n.string("intent.yesno.result.no", fallback: "NO")
        let emoji = isYes ? "✅" : "❌"

        return .result(dialog: L10n.format("intent.yesno.dialog.format", fallback: "%@ %@!", emoji, result))
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
            throw AppIntentError.insufficientOptions
        }
        
        guard let randomChoice = choices.randomElement() else {
            throw AppIntentError.unableToPickChoice
        }
        
        return .result(dialog: L10n.format("intent.custom.dialog.winner_format", fallback: "🎉 The winner is: %@", randomChoice))
    }
}

// MARK: - Rock Paper Scissors Intent
struct RPSIntent: AppIntent {
    static var title: LocalizedStringResource = "Rock Paper Scissors"
    static var description = IntentDescription("Get a random rock, paper, or scissors choice")
    static var openAppWhenRun: Bool = false

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let choices = [
            L10n.string("intent.rps.choice.rock", fallback: "Rock"),
            L10n.string("intent.rps.choice.paper", fallback: "Paper"),
            L10n.string("intent.rps.choice.scissors", fallback: "Scissors"),
        ]
        let emojis = ["🪨", "📄", "✂️"]
        let index = Int.random(in: 0..<3)

        return .result(dialog: L10n.format("intent.rps.dialog.format", fallback: "%@ %@!", emojis[index], choices[index]))
    }
}

// MARK: - App Intent Error
enum AppIntentError: Swift.Error, CustomLocalizedStringResourceConvertible {
    case insufficientOptions
    case unableToPickChoice
    
    var localizedStringResource: LocalizedStringResource {
        switch self {
        case .insufficientOptions:
            return LocalizedStringResource(
                stringLiteral: L10n.string(
                    "intent.custom.error.insufficient_options",
                    fallback: "Please provide at least 2 options separated by commas"
                )
            )
        case .unableToPickChoice:
            return LocalizedStringResource(
                stringLiteral: L10n.string(
                    "intent.custom.error.unable_to_pick",
                    fallback: "Unable to pick a choice"
                )
            )
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
