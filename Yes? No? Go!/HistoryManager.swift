//
//  HistoryManager.swift
//  Yes? No? Go!
//
//  Created by Geoffrey Silva on 3/17/26.
//

import Foundation
import SwiftUI

struct HistoryEntry: Codable, Identifiable {
    let id: UUID
    let mode: String
    let result: String
    let detail: String?
    let timestamp: Date

    init(mode: String, result: String, detail: String? = nil) {
        self.id = UUID()
        self.mode = mode
        self.result = result
        self.detail = detail
        self.timestamp = Date()
    }
}

@Observable
class HistoryManager {
    static let shared = HistoryManager()

    private static let storageKey = "resultHistory"
    private static let maxPerMode = 50

    var entries: [HistoryEntry] = []

    private init() {
        load()
    }

    func add(mode: String, result: String, detail: String? = nil) {
        let entry = HistoryEntry(mode: mode, result: result, detail: detail)
        entries.insert(entry, at: 0)
        trimEntries(for: mode)
        save()
    }

    func entries(for mode: String) -> [HistoryEntry] {
        entries.filter { $0.mode == mode }
    }

    func clearHistory(for mode: String) {
        entries.removeAll { $0.mode == mode }
        save()
    }

    // MARK: - Stats

    func coinStats() -> (heads: Int, tails: Int) {
        let modeEntries = entries(for: "coin")
        let heads = modeEntries.filter { $0.result == "HEADS" }.count
        let tails = modeEntries.filter { $0.result == "TAILS" }.count
        return (heads, tails)
    }

    func yesNoStats() -> (yes: Int, no: Int) {
        let modeEntries = entries(for: "yesno")
        let yes = modeEntries.filter { $0.result == "YES!" }.count
        let no = modeEntries.filter { $0.result == "NO!" }.count
        return (yes, no)
    }

    func rpsStats() -> (rock: Int, paper: Int, scissors: Int) {
        let modeEntries = entries(for: "rps")
        let rock = modeEntries.filter { $0.result == "Rock" }.count
        let paper = modeEntries.filter { $0.result == "Paper" }.count
        let scissors = modeEntries.filter { $0.result == "Scissors" }.count
        return (rock, paper, scissors)
    }

    func customStats() -> [(option: String, count: Int)] {
        let modeEntries = entries(for: "custom")
        var counts: [String: Int] = [:]
        for entry in modeEntries {
            counts[entry.result, default: 0] += 1
        }
        return counts.map { (option: $0.key, count: $0.value) }
            .sorted { $0.count > $1.count }
    }

    func orbStats() -> (positive: Int, neutral: Int, negative: Int) {
        let positiveResponses = Set([
            "It is certain", "Without a doubt", "Yes, definitely",
            "You may rely on it", "As I see it, yes", "Most likely",
            "Outlook good", "Signs point to yes", "Yes",
            "It is decidedly so", "The stars align in your favor"
        ])
        let neutralResponses = Set([
            "Ask again later", "Better not tell you now",
            "Cannot predict now", "Concentrate and ask again",
            "Reply hazy, try again", "Fate whispers... maybe"
        ])

        let modeEntries = entries(for: "orb")
        var positive = 0, neutral = 0, negative = 0
        for entry in modeEntries {
            if positiveResponses.contains(entry.result) {
                positive += 1
            } else if neutralResponses.contains(entry.result) {
                neutral += 1
            } else {
                negative += 1
            }
        }
        return (positive, neutral, negative)
    }

    func rngStats() -> (average: Double, lowest: Int, highest: Int)? {
        let modeEntries = entries(for: "rng")
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
