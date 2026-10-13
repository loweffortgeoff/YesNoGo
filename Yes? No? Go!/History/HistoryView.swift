//
//  HistoryView.swift
//  Yes? No? Go!
//
//  Created by Geoffrey Silva on 3/17/26.
//

import SwiftUI

struct HistoryView: View {
    let mode: DecisionMode

    @Environment(\.dismiss) private var dismiss
    @State private var showClearConfirmation = false

    private var history: HistoryManager { HistoryManager.shared }

    private var modeLabel: String { mode.label }

    private var modeEntries: [HistoryEntry] {
        history.entries(for: mode)
    }

    var body: some View {
        NavigationStack {
            List {
                if !modeEntries.isEmpty {
                    statsSection
                }

                if modeEntries.isEmpty {
                    Section {
                        ContentUnavailableView(
                            "No Results Yet",
                            systemImage: mode.icon,
                            description: Text("Start using \(modeLabel) to build your history.")
                        )
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel("No results yet. Start using \(modeLabel) to build your history.")
                    }
                } else {
                    Section(header: Text("Recent Results")) {
                        ForEach(modeEntries) { entry in
                            historyRow(entry)
                        }
                    }

                    Section {
                        Button(role: .destructive) {
                            showClearConfirmation = true
                        } label: {
                            HStack {
                                Spacer()
                                Label("Clear History", systemImage: "trash")
                                Spacer()
                            }
                        }
                        .accessibilityLabel("Clear \(modeLabel) history")
                        .accessibilityHint("Removes all past results for this mode")
                    }
                }
            }
            .navigationTitle("\(modeLabel) History")
            .navigationBarTitleDisplayMode(.inline)
            .tint(mode.theme.tint)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .accessibilityLabel("Close history")
                }
            }
            .confirmationDialog(
                "Clear all \(modeLabel) history?",
                isPresented: $showClearConfirmation,
                titleVisibility: .visible
            ) {
                Button("Clear History", role: .destructive) {
                    history.clearHistory(for: mode)
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This cannot be undone.")
            }
        }
    }

    // MARK: - Stats Section

    @ViewBuilder
    private var statsSection: some View {
        Section(header: Text("Stats")) {
            switch mode {
            case .coin:
                coinStatsView
            case .yesno:
                yesNoStatsView
            case .rps:
                rpsStatsView
            case .custom:
                customStatsView
            case .orb:
                orbStatsView
            case .rng:
                rngStatsView
            }

            HStack {
                Text("Total")
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(modeEntries.count)")
                    .fontWeight(.semibold)
            }
        }
    }

    @ViewBuilder
    private var coinStatsView: some View {
        let stats = history.coinStats()
        let total = stats.heads + stats.tails
        statRow("👑 Heads", count: stats.heads, total: total)
        statRow("🦅 Tails", count: stats.tails, total: total)
    }

    @ViewBuilder
    private var yesNoStatsView: some View {
        let stats = history.yesNoStats()
        let total = stats.yes + stats.no
        statRow("✅ Yes", count: stats.yes, total: total)
        statRow("❌ No", count: stats.no, total: total)
    }

    @ViewBuilder
    private var rpsStatsView: some View {
        let stats = history.rpsStats()
        let total = stats.rock + stats.paper + stats.scissors
        statRow("🪨 Rock", count: stats.rock, total: total)
        statRow("📄 Paper", count: stats.paper, total: total)
        statRow("✂️ Scissors", count: stats.scissors, total: total)
    }

    @ViewBuilder
    private var customStatsView: some View {
        let stats = history.customStats()
        if let top = stats.first {
            HStack {
                Text("Most Picked")
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(top.option) (\(top.count)×)")
                    .fontWeight(.semibold)
            }
        }
        if stats.count > 1 {
            HStack {
                Text("Unique Options")
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(stats.count)")
                    .fontWeight(.semibold)
            }
        }
    }

    @ViewBuilder
    private var orbStatsView: some View {
        let stats = history.orbStats()
        let total = stats.positive + stats.neutral + stats.negative
        statRow("🟢 Positive", count: stats.positive, total: total)
        statRow("🟡 Neutral", count: stats.neutral, total: total)
        statRow("🔴 Negative", count: stats.negative, total: total)
    }

    @ViewBuilder
    private var rngStatsView: some View {
        if let stats = history.rngStats() {
            HStack {
                Text("Average")
                    .foregroundStyle(.secondary)
                Spacer()
                Text(String(format: "%.1f", stats.average))
                    .fontWeight(.semibold)
            }
            HStack {
                Text("Lowest")
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(stats.lowest)")
                    .fontWeight(.semibold)
            }
            HStack {
                Text("Highest")
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(stats.highest)")
                    .fontWeight(.semibold)
            }
        }
    }

    // MARK: - Helpers

    private func statRow(_ label: String, count: Int, total: Int) -> some View {
        HStack {
            Text(label)
                .foregroundStyle(.secondary)
            Spacer()
            if total > 0 {
                Text("\(count) (\(percentage(count, of: total))%)")
                    .fontWeight(.semibold)
            } else {
                Text("0")
                    .fontWeight(.semibold)
            }
        }
        .accessibilityElement(children: .combine)
    }

    private func percentage(_ count: Int, of total: Int) -> Int {
        guard total > 0 else { return 0 }
        return Int(round(Double(count) / Double(total) * 100))
    }

    private func historyRow(_ entry: HistoryEntry) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(entry.result)
                    .fontWeight(.medium)
                if let detail = entry.detail {
                    Text(detail)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            Text(entry.timestamp, format: .dateTime.month(.abbreviated).day().hour().minute())
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .accessibilityElement(children: .combine)
    }
}
