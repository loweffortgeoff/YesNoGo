//
//  HistoryManager.swift
//  Yes? No? Go!
//
//  Created by Geoffrey Silva on 3/17/26.
//

import Foundation
import SwiftUI

// MARK: - Outcome

/// A locale-independent outcome token. Stats classify on this value, so the
/// percentages stay correct in every language.
enum Outcome: String {
    case heads
    case tails
    case yes
    case no
    case rock
    case paper
    case scissors
    case orbPositive = "orb.positive"
    case orbNeutral = "orb.neutral"
    case orbNegative = "orb.negative"
}

// MARK: - History Entry

struct HistoryEntry: Codable, Identifiable {
    let id: UUID
    let mode: String
    let result: String
    let detail: String?
    /// Outcome token. `nil` for modes whose result is free-form, such as Custom and RNG.
    let category: String?
    let timestamp: Date

    init(mode: String, result: String, detail: String? = nil, category: Outcome? = nil) {
        self.id = UUID()
        self.mode = mode
        self.result = result
        self.detail = detail
        self.category = category?.rawValue
        self.timestamp = Date()
    }

    /// Resolves the outcome token. Entries saved before categories existed fall
    /// back to the stored, localized text.
    var outcome: Outcome? {
        if let category, let value = Outcome(rawValue: category) {
            return value
        }
        for (text, value) in Self.legacyTextToOutcome where text == result {
            return value
        }
        return nil
    }

    /// English result text from builds before outcome categories existed.
    private static let legacyTextToOutcome: [(String, Outcome)] = {
        let positive = [
            "It is certain", "Without a doubt", "Yes, definitely",
            "You may rely on it", "As I see it, yes", "Most likely",
            "Outlook good", "Signs point to yes", "Yes",
            "It is decidedly so", "The stars align in your favor"
        ]
        let neutral = [
            "Ask again later", "Better not tell you now",
            "Cannot predict now", "Concentrate and ask again",
            "Reply hazy, try again", "Fate whispers... maybe"
        ]

        var pairs: [(String, Outcome)] = [
            ("HEADS", .heads), ("TAILS", .tails),
            ("YES!", .yes), ("NO!", .no),
            ("Rock", .rock), ("Paper", .paper), ("Scissors", .scissors)
        ]
        pairs += positive.map { ($0, Outcome.orbPositive) }
        pairs += neutral.map { ($0, Outcome.orbNeutral) }
        return pairs
    }()
}

// MARK: - History Manager

@Observable
class HistoryManager {
    static let shared = HistoryManager()

    private static let storageKey = "resultHistory"
    private static let maxPerMode = 50

    var entries: [HistoryEntry] = []

    private init() {
        load()
    }

    func add(mode: DecisionMode, result: String, detail: String? = nil, category: Outcome? = nil) {
        let entry = HistoryEntry(mode: mode.rawValue, result: result, detail: detail, category: category)
        entries.insert(entry, at: 0)
        trimEntries(for: mode.rawValue)
        save()
    }

    func entries(for mode: DecisionMode) -> [HistoryEntry] {
        entries.filter { $0.mode == mode.rawValue }
    }

    func clearHistory(for mode: DecisionMode) {
        entries.removeAll { $0.mode == mode.rawValue }
        save()
    }

    // MARK: - Stats

    func coinStats() -> (heads: Int, tails: Int) {
        let modeEntries = entries(for: .coin)
        return (
            heads: modeEntries.filter { $0.outcome == .heads }.count,
            tails: modeEntries.filter { $0.outcome == .tails }.count
        )
    }

    func yesNoStats() -> (yes: Int, no: Int) {
        let modeEntries = entries(for: .yesno)
        return (
            yes: modeEntries.filter { $0.outcome == .yes }.count,
            no: modeEntries.filter { $0.outcome == .no }.count
        )
    }

    func rpsStats() -> (rock: Int, paper: Int, scissors: Int) {
        let modeEntries = entries(for: .rps)
        return (
            rock: modeEntries.filter { $0.outcome == .rock }.count,
            paper: modeEntries.filter { $0.outcome == .paper }.count,
            scissors: modeEntries.filter { $0.outcome == .scissors }.count
        )
    }

    func customStats() -> [(option: String, count: Int)] {
        let modeEntries = entries(for: .custom)
        var counts: [String: Int] = [:]
        for entry in modeEntries {
            counts[entry.result, default: 0] += 1
        }
        return counts.map { (option: $0.key, count: $0.value) }
            .sorted { $0.count > $1.count }
    }

    func orbStats() -> (positive: Int, neutral: Int, negative: Int) {
        let modeEntries = entries(for: .orb)
        var positive = 0, neutral = 0, negative = 0
        for entry in modeEntries {
            switch entry.outcome {
            case .orbPositive: positive += 1
            case .orbNeutral: neutral += 1
            case .orbNegative: negative += 1
            default: negative += 1
            }
        }
        return (positive, neutral, negative)
    }

    func rngStats() -> (average: Double, lowest: Int, highest: Int)? {
        let modeEntries = entries(for: .rng)
        let numbers = modeEntries.compactMap { Int($0.result) }
        guard !numbers.isEmpty else { return nil }
        let sum = numbers.reduce(0, +)
        return (
            average: Double(sum) / Double(numbers.count),
            lowest: numbers.min()!,
            highest: numbers.max()!
        )
    }

    // MARK: - Persistence

    private func save() {
        guard let data = try? JSONEncoder().encode(entries) else { return }
        UserDefaults.standard.set(data, forKey: Self.storageKey)
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: Self.storageKey),
              let decoded = try? JSONDecoder().decode([HistoryEntry].self, from: data) else {
            return
        }
        entries = decoded
    }

    private func trimEntries(for mode: String) {
        var modeCount = 0
        var indicesToRemove: [Int] = []
        for (index, entry) in entries.enumerated() where entry.mode == mode {
            modeCount += 1
            if modeCount > Self.maxPerMode {
                indicesToRemove.append(index)
            }
        }
        for index in indicesToRemove.reversed() {
            entries.remove(at: index)
        }
    }
}
