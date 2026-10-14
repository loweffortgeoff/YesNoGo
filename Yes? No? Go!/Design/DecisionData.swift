//
//  DecisionData.swift
//  Yes? No? Go!
//
//  Static decision data for the Orb, Rock Paper Scissors, and Custom modes.
//

import Foundation

// MARK: - Orb Responses

/// One fortune from the magic orb.
/// Each response carries its category, so the history stats stay correct in
/// every language.
struct OrbResponse: Equatable {
    enum Category: String {
        case positive
        case neutral
        case negative

        /// The locale-independent token stored with a history entry.
        var outcome: Outcome {
            switch self {
            case .positive: return .orbPositive
            case .neutral: return .orbNeutral
            case .negative: return .orbNegative
            }
        }
    }

    let text: String
    let category: Category

    static let all: [OrbResponse] = [
        // Positive
        OrbResponse(text: L10n.string("orb.response.certain", fallback: "It is certain"), category: .positive),
        OrbResponse(text: L10n.string("orb.response.without_doubt", fallback: "Without a doubt"), category: .positive),
        OrbResponse(text: L10n.string("orb.response.yes_definitely", fallback: "Yes, definitely"), category: .positive),
        OrbResponse(text: L10n.string("orb.response.rely_on_it", fallback: "You may rely on it"), category: .positive),
        OrbResponse(text: L10n.string("orb.response.as_i_see_it_yes", fallback: "As I see it, yes"), category: .positive),
        OrbResponse(text: L10n.string("orb.response.most_likely", fallback: "Most likely"), category: .positive),
        OrbResponse(text: L10n.string("orb.response.outlook_good", fallback: "Outlook good"), category: .positive),
        OrbResponse(text: L10n.string("orb.response.signs_point_yes", fallback: "Signs point to yes"), category: .positive),
        OrbResponse(text: L10n.string("orb.response.yes", fallback: "Yes"), category: .positive),
        OrbResponse(text: L10n.string("orb.response.decidedly_so", fallback: "It is decidedly so"), category: .positive),
        OrbResponse(text: L10n.string("orb.response.stars_align", fallback: "The stars align in your favor"), category: .positive),

        // Neutral
        OrbResponse(text: L10n.string("orb.response.ask_again_later", fallback: "Ask again later"), category: .neutral),
        OrbResponse(text: L10n.string("orb.response.better_not_now", fallback: "Better not tell you now"), category: .neutral),
        OrbResponse(text: L10n.string("orb.response.cannot_predict_now", fallback: "Cannot predict now"), category: .neutral),
        OrbResponse(text: L10n.string("orb.response.concentrate_and_ask_again", fallback: "Concentrate and ask again"), category: .neutral),
        OrbResponse(text: L10n.string("orb.response.reply_hazy", fallback: "Reply hazy, try again"), category: .neutral),
        OrbResponse(text: L10n.string("orb.response.fate_whispers_maybe", fallback: "Fate whispers... maybe"), category: .neutral),

        // Negative
        OrbResponse(text: L10n.string("orb.response.dont_count_on_it", fallback: "Don't count on it"), category: .negative),
        OrbResponse(text: L10n.string("orb.response.my_reply_is_no", fallback: "My reply is no"), category: .negative),
        OrbResponse(text: L10n.string("orb.response.my_sources_say_no", fallback: "My sources say no"), category: .negative),
        OrbResponse(text: L10n.string("orb.response.outlook_not_good", fallback: "Outlook not so good"), category: .negative),
        OrbResponse(text: L10n.string("orb.response.very_doubtful", fallback: "Very doubtful"), category: .negative),
    ]
}

// MARK: - Rock Paper Scissors

enum RPSChoice: String, CaseIterable {
    case rock
    case paper
    case scissors

    var emoji: String {
        switch self {
        case .rock: return "🪨"
        case .paper: return "📄"
        case .scissors: return "✂️"
        }
    }

    var label: String {
        switch self {
        case .rock: return L10n.string("rps.choice.rock", fallback: "Rock")
        case .paper: return L10n.string("rps.choice.paper", fallback: "Paper")
        case .scissors: return L10n.string("rps.choice.scissors", fallback: "Scissors")
        }
    }

    var outcome: Outcome {
        switch self {
        case .rock: return .rock
        case .paper: return .paper
        case .scissors: return .scissors
        }
    }

    /// The sound played when this choice is revealed.
    var sound: String {
        switch self {
        case .rock: return "thud"
        case .paper: return "paper"
        case .scissors: return "slick"
        }
    }
}

// MARK: - Custom Options

/// One user-entered option. A stable id keeps text field state attached to the
/// right row when an option is removed.
struct CustomOption: Identifiable, Equatable {
    let id = UUID()
    var text: String = ""
}
