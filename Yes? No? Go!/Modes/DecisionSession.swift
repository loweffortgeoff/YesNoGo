//
//  DecisionSession.swift
//  Yes? No? Go!
//
//  The single source of truth for a decision: the visible mode, the shared
//  result state, and the six flows that produce a result. The mode views render
//  from it; ContentView owns the chrome around it.
//

import Observation
import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

@Observable
final class DecisionSession {
    var mode: DecisionMode = .coin

    // Shared result state
    var isAnimating = false
    var result = ""
    var showResult = false
    var showAlert = false

    // Coin
    var coinAngle: Double = 0
    var coinLift: CGFloat = 0

    // Yes / No
    var yesNoWasYes = true

    // Custom picker
    var customOptions: [CustomOption] = [CustomOption(), CustomOption()]
    var wheelChoices: [String] = []
    var wheelAngle: Double = 0
    var showWheel = false

    // Rock Paper Scissors
    var rpsChoice: RPSChoice = .rock

    // Random number
    var rngMinText = "1"
    var rngMaxText = "100"
    var rngNoImmediateRepeat = false
    var rngErrorMessage: String?
    var lastGeneratedRandomNumber: Int?

    // Feedback triggers
    var tapTrigger = 0
    var revealTrigger = 0
    var errorTrigger = 0

    private var decisionTask: Task<Void, Never>?
    private let quickActions = QuickActionManager.shared
    private let sound = SoundPlayer.shared

    // MARK: - Mode Switching

    func switchMode(_ newMode: DecisionMode) {
        guard newMode != mode else { return }

        decisionTask?.cancel()
        isAnimating = false
        sound.play("select")

        withAnimation(.snappy(duration: 0.35)) {
            mode = newMode
            resetResultState()
        }
    }

    private func resetResultState() {
        showResult = false
        showWheel = false
        result = ""
        rngErrorMessage = nil
        wheelChoices = []
        wheelAngle = 0
        coinLift = 0
    }

    private func run(_ mode: DecisionMode, reduceMotion: Bool) {
        switch mode {
        case .coin: flipCoin(reduceMotion: reduceMotion)
        case .yesno: generateYesNo(reduceMotion: reduceMotion)
        case .custom: chooseCustom(reduceMotion: reduceMotion)
        case .rps: playRPS(reduceMotion: reduceMotion)
        case .orb: askOrb(reduceMotion: reduceMotion)
        case .rng: generateRandomNumber(reduceMotion: reduceMotion)
        }
    }

    /// Cancels a flow that is mid-flight, for example when the view goes away.
    func cancelCurrentFlow() {
        decisionTask?.cancel()
    }

    // MARK: - Quick Actions

    func handlePendingRequest(reduceMotion: Bool) {
        guard let requested = quickActions.requestedMode else { return }
        quickActions.requestedMode = nil

        switchMode(requested)

        // Custom and RNG need user input before they can produce a result.
        guard requested.runsOnOpen else { return }

        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(450))
            // The user may switch modes during the delay. Start the flow only
            // while the requested mode is still the visible one.
            guard mode == requested else { return }
            run(requested, reduceMotion: reduceMotion)
        }
    }

    // MARK: - Coin Flow

    func flipCoin(reduceMotion: Bool) {
        guard !isAnimating else { return }

        decisionTask?.cancel()
        sound.play("coin")
        tapTrigger += 1
        isAnimating = true
        showResult = false

        let isHeads = Bool.random()

        // Land on the requested face, whatever face the coin currently rests on.
        let restingHalfTurns = Int((coinAngle / 180).rounded())
        var halfTurnsToAdd = 10
        if (restingHalfTurns + halfTurnsToAdd) % 2 != (isHeads ? 0 : 1) {
            halfTurnsToAdd += 1
        }
        let destination = Double(restingHalfTurns + halfTurnsToAdd) * 180

        if reduceMotion {
            coinAngle = destination
        } else {
            withAnimation(.easeOut(duration: 1.6)) {
                coinAngle = destination
            }
            withAnimation(.easeOut(duration: 0.7)) {
                coinLift = -64
            }
        }

        let coinResult = isHeads
            ? L10n.string("coin.result.heads", fallback: "HEADS")
            : L10n.string("coin.result.tails", fallback: "TAILS")

        decisionTask = Task { @MainActor in
            if !reduceMotion {
                try? await Task.sleep(for: .milliseconds(700))
                guard !Task.isCancelled else { return }
                withAnimation(.easeIn(duration: 0.8)) {
                    coinLift = 0
                }
                try? await Task.sleep(for: .milliseconds(800))
            } else {
                try? await Task.sleep(for: .milliseconds(250))
            }
            guard !Task.isCancelled else { return }

            result = coinResult
            isAnimating = false
            HistoryManager.shared.add(
                mode: .coin,
                result: coinResult,
                category: isHeads ? .heads : .tails
            )
            revealTrigger += 1

            withAnimation(.spring(duration: 0.5, bounce: 0.28)) {
                showResult = true
            }

            sound.play(isHeads ? "crown" : "eagle")

            let spokenSide = isHeads
                ? L10n.string("coin.result.heads.spoken", fallback: "heads")
                : L10n.string("coin.result.tails.spoken", fallback: "tails")
            announceForVoiceOver(
                L10n.format("vo.coin.landed_format", fallback: "Coin landed on %@", spokenSide)
            )
        }
    }

    // MARK: - Yes / No Flow

    func generateYesNo(reduceMotion: Bool) {
        guard !isAnimating else { return }

        decisionTask?.cancel()
        sound.play("decision")
        tapTrigger += 1
        isAnimating = true
        showResult = false

        let isYes = Bool.random()

        decisionTask = Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(reduceMotion ? 350 : 1400))
            guard !Task.isCancelled else { return }

            yesNoWasYes = isYes
            result = isYes
                ? L10n.string("yesno.result.yes", fallback: "YES!")
                : L10n.string("yesno.result.no", fallback: "NO!")
            isAnimating = false
            HistoryManager.shared.add(mode: .yesno, result: result, category: isYes ? .yes : .no)
            revealTrigger += 1

            withAnimation(.spring(duration: 0.5, bounce: 0.28)) {
                showResult = true
            }

            sound.play(isYes ? "yesChord" : "noTrombone")

            let answer = isYes
                ? L10n.string("yesno.answer.yes.spoken", fallback: "yes")
                : L10n.string("yesno.answer.no.spoken", fallback: "no")
            announceForVoiceOver(
                L10n.format("vo.answer.is_format", fallback: "The answer is %@", answer)
            )
        }
    }

    // MARK: - Custom Picker Flow

    func addChoice() {
        guard customOptions.count < 6 else { return }
        withAnimation(.snappy(duration: 0.3)) {
            customOptions.append(CustomOption())
        }
    }

    func removeChoice(id: CustomOption.ID) {
        guard customOptions.count > 2 else { return }
        withAnimation(.snappy(duration: 0.3)) {
            customOptions.removeAll { $0.id == id }
        }
    }

    /// The 1-based position of an option, used for its placeholder and label.
    func optionNumber(_ id: CustomOption.ID) -> Int {
        (customOptions.firstIndex { $0.id == id } ?? 0) + 1
    }

    /// A binding to one option's text, so field state follows the row's id
    /// rather than its index.
    func binding(for id: CustomOption.ID) -> Binding<String> {
        Binding(
            get: { self.customOptions.first { $0.id == id }?.text ?? "" },
            set: { newValue in
                guard let index = self.customOptions.firstIndex(where: { $0.id == id }) else { return }
                self.customOptions[index].text = newValue
            }
        )
    }

    private var validCustomChoices: [String] {
        customOptions
            .map(\.text)
            .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    }

    func chooseCustom(reduceMotion: Bool) {
        let choices = validCustomChoices

        guard choices.count >= 2 else {
            errorTrigger += 1
            sound.play("error")
            showAlert = true
            return
        }

        guard !isAnimating else { return }

        decisionTask?.cancel()
        sound.play("shuffle")
        tapTrigger += 1
        isAnimating = true
        showResult = false

        let winnerIndex = Int.random(in: 0..<choices.count)
        let winner = choices[winnerIndex]

        let step = 360.0 / Double(choices.count)
        wheelChoices = choices
        // Park the pointer on the winner. The spin below is skipped under
        // Reduce Motion, so the wheel must start at the winning angle or the
        // pointer marks the wrong option.
        wheelAngle = reduceMotion ? -Double(winnerIndex) * step : 0

        withAnimation(.easeIn(duration: 0.25)) {
            showWheel = true
        }

        if !reduceMotion {
            var destination = -Double(winnerIndex) * step
            // Always spin forward at least four full turns.
            while destination < 4 * 360 {
                destination += 360
            }
            withAnimation(.timingCurve(0.12, 0.9, 0.16, 1, duration: 2.4)) {
                wheelAngle = destination
            }
        }

        decisionTask = Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(reduceMotion ? 500 : 2500))
            guard !Task.isCancelled else { return }

            result = winner
            isAnimating = false
            wheelChoices = []
            wheelAngle = 0
            HistoryManager.shared.add(
                mode: .custom,
                result: winner,
                detail: "From: \(choices.joined(separator: ", "))"
            )
            revealTrigger += 1
            sound.play("success")

            withAnimation(.spring(duration: 0.5, bounce: 0.28)) {
                showWheel = false
                showResult = true
            }

            announceForVoiceOver(
                L10n.format("vo.winner.is_format", fallback: "The winner is %@", winner)
            )
        }
    }

    // MARK: - Rock Paper Scissors Flow

    func playRPS(reduceMotion: Bool) {
        guard !isAnimating else { return }

        decisionTask?.cancel()
        sound.play("decision")
        tapTrigger += 1
        isAnimating = true
        showResult = false

        let choice = RPSChoice.allCases.randomElement() ?? .rock

        decisionTask = Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(reduceMotion ? 300 : 1100))
            guard !Task.isCancelled else { return }

            rpsChoice = choice
            result = choice.label
            isAnimating = false
            HistoryManager.shared.add(mode: .rps, result: choice.label, category: choice.outcome)
            revealTrigger += 1

            withAnimation(.spring(duration: 0.5, bounce: 0.28)) {
                showResult = true
            }

            sound.play(choice.sound)

            announceForVoiceOver(
                L10n.format("vo.rps.opponent_chose_format", fallback: "Opponent chose %@", choice.label)
            )
        }
    }

    // MARK: - Orb Flow

    func askOrb(reduceMotion: Bool) {
        guard !isAnimating else { return }

        decisionTask?.cancel()
        sound.play("decision")
        tapTrigger += 1
        isAnimating = true
        showResult = false

        let fallback = OrbResponse(
            text: L10n.string("orb.response.silent", fallback: "The orb is silent"),
            category: .neutral
        )
        let response = OrbResponse.all.randomElement() ?? fallback

        decisionTask = Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(reduceMotion ? 400 : 1500))
            guard !Task.isCancelled else { return }

            result = response.text
            isAnimating = false
            HistoryManager.shared.add(
                mode: .orb,
                result: response.text,
                category: response.category.outcome
            )
            revealTrigger += 1

            withAnimation(.spring(duration: 0.5, bounce: 0.28)) {
                showResult = true
            }

            sound.play("mystical")

            announceForVoiceOver(
                L10n.format("orb.a11y.says_format", fallback: "The orb says: %@", response.text)
            )
        }
    }

    // MARK: - Random Number Flow

    func generateRandomNumber(reduceMotion: Bool) {
        let trimmedMin = rngMinText.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedMax = rngMaxText.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedMin.isEmpty else {
            failRandomNumber(L10n.string("rng.error.enter_min", fallback: "Enter a minimum number."))
            return
        }

        guard !trimmedMax.isEmpty else {
            failRandomNumber(L10n.string("rng.error.enter_max", fallback: "Enter a maximum number."))
            return
        }

        guard let minValue = Int(trimmedMin), let maxValue = Int(trimmedMax) else {
            failRandomNumber(L10n.string("rng.error.whole_numbers_only", fallback: "Use whole numbers only (no decimals)."))
            return
        }

        guard minValue <= maxValue else {
            failRandomNumber(L10n.string("rng.error.min_le_max", fallback: "Minimum must be less than or equal to maximum."))
            return
        }

        let valueCount = maxValue - minValue + 1

        if rngNoImmediateRepeat && valueCount < 2 {
            failRandomNumber(
                L10n.string(
                    "rng.error.no_repeat_range",
                    fallback: "No Immediate Repeat requires a range with at least two possible values."
                )
            )
            return
        }

        guard !isAnimating else { return }

        rngErrorMessage = nil
        decisionTask?.cancel()
        isAnimating = true
        tapTrigger += 1
        showResult = false

        decisionTask = Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(reduceMotion ? 100 : 420))
            guard !Task.isCancelled else { return }

            var generated = Int.random(in: minValue...maxValue)
            if rngNoImmediateRepeat, let previous = lastGeneratedRandomNumber, valueCount > 1 {
                while generated == previous {
                    generated = Int.random(in: minValue...maxValue)
                }
            }

            result = String(generated)
            lastGeneratedRandomNumber = generated
            isAnimating = false
            HistoryManager.shared.add(
                mode: .rng,
                result: String(generated),
                detail: "Range: \(minValue)–\(maxValue)"
            )
            revealTrigger += 1

            withAnimation(.spring(duration: 0.4, bounce: 0.2)) {
                showResult = true
            }

            sound.play("rngDing")

            announceForVoiceOver(
                L10n.format("rng.a11y.generated_number_format", fallback: "Generated number: %d", generated)
            )
        }
    }

    func clearRandomNumberError() {
        rngErrorMessage = nil
    }

    private func failRandomNumber(_ message: String) {
        rngErrorMessage = message
        errorTrigger += 1
        sound.play("error")
    }

    // MARK: - Accessibility

    private func announceForVoiceOver(_ message: String) {
        #if canImport(UIKit)
        UIAccessibility.post(notification: .announcement, argument: message)
        #endif
    }
}
