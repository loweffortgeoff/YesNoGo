//
//  ContentView.swift
//  Yes? No? Go!
//
//  Created by Geoffrey Silva on 11/1/25.
//

import SwiftUI
#if canImport(UIKit)
import UIKit
#endif
import AVFoundation
import AudioToolbox

// MARK: - Quick Action Manager

/// Carries a mode requested from outside the app: a Home Screen quick action, a
/// deep link, or a Siri continuation. The scene delegate sets it and the UI
/// consumes it.
@Observable
final class QuickActionManager {
    static let shared = QuickActionManager()

    var requestedMode: DecisionMode?

    private init() {}
}

// MARK: - Content View

struct ContentView: View {
    @State private var mode: DecisionMode = .coin
    @State private var isAnimating = false
    @State private var result = ""
    @State private var showResult = false
    @State private var showAlert = false
    @State private var showCredits = false
    @State private var showHistory = false

    // Coin
    @State private var coinAngle: Double = 0
    @State private var coinLift: CGFloat = 0

    // Yes / No
    @State private var yesNoWasYes = true

    // Custom picker
    @State private var customOptions: [CustomOption] = [CustomOption(), CustomOption()]
    @State private var wheelChoices: [String] = []
    @State private var wheelAngle: Double = 0
    @State private var showWheel = false

    // Rock Paper Scissors
    @State private var rpsChoice: RPSChoice = .rock

    // Random number
    @State private var rngMinText = "1"
    @State private var rngMaxText = "100"
    @State private var rngNoImmediateRepeat = false
    @State private var rngErrorMessage: String?
    @State private var lastGeneratedRandomNumber: Int?

    // Feedback triggers
    @State private var tapTrigger = 0
    @State private var revealTrigger = 0
    @State private var errorTrigger = 0

    @State private var decisionTask: Task<Void, Never>?
    @State private var audioPlayer: AVAudioPlayer?

    private let quickActions = QuickActionManager.shared

    @ScaledMetric(relativeTo: .largeTitle) private var coinSize: CGFloat = 128
    @ScaledMetric(relativeTo: .largeTitle) private var heroGlyphSize: CGFloat = 58
    @ScaledMetric(relativeTo: .largeTitle) private var orbSize: CGFloat = 148
    @ScaledMetric(relativeTo: .largeTitle) private var rngNumberSize: CGFloat = 56

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ZStack {
                BrandCanvas(theme: mode.theme)

                ScrollView {
                    VStack(spacing: 18) {
                        ModeSelectorBar(
                            selection: mode,
                            showsLabels: horizontalSizeClass == .regular,
                            onSelect: switchMode
                        )

                        DecisionCard(theme: mode.theme) {
                            modeContent
                                .id(mode)
                                .transition(.opacity.combined(with: .scale(scale: 0.97)))
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 4)
                    .padding(.bottom, 24)
                }
                .scrollBounceBehavior(.basedOnSize)
            }
            .navigationTitle(mode.label)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .tint(mode.theme.tint)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        showHistory = true
                    } label: {
                        Image(systemName: "clock.arrow.circlepath")
                    }
                    .accessibilityLabel("Past results")
                    .accessibilityHint("View history and stats for the current mode")
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showCredits = true
                    } label: {
                        Image(systemName: "info.circle")
                    }
                    .accessibilityLabel("Credits and information")
                    .accessibilityHint("View sound credits and app information")
                }
            }
            .alert(
                L10n.string("custom.alert.min_choices", fallback: "Please enter at least 2 choices!"),
                isPresented: $showAlert
            ) {
                Button(L10n.string("common.ok", fallback: "OK")) { }
            }
            .sheet(isPresented: $showHistory) {
                HistoryView(mode: mode)
            }
            .sheet(isPresented: $showCredits) {
                CreditsView()
            }
            .sensoryFeedback(.selection, trigger: mode)
            .sensoryFeedback(.impact(weight: .medium), trigger: tapTrigger)
            .sensoryFeedback(.success, trigger: revealTrigger)
            .sensoryFeedback(.error, trigger: errorTrigger)
            .onAppear {
                handlePendingRequest()
            }
            .onChange(of: quickActions.requestedMode) { _, _ in
                // Covers the cold launch case, where the quick action or URL
                // arrives before this view is on screen.
                handlePendingRequest()
            }
            .onChange(of: scenePhase) { _, newPhase in
                if newPhase == .active {
                    handlePendingRequest()
                }
            }
            .onDisappear {
                decisionTask?.cancel()
            }
        }
    }

    // MARK: - Mode Content

    @ViewBuilder
    private var modeContent: some View {
        switch mode {
        case .coin: coinView
        case .yesno: yesNoView
        case .custom: customChoiceView
        case .rps: rpsView
        case .orb: orbView
        case .rng: rngView
        }
    }

    // MARK: - Coin

    private var coinFaceIsHeads: Bool {
        Int((coinAngle / 180).rounded()) % 2 == 0
    }

    private var coinFaceSymbol: String {
        coinFaceIsHeads ? "crown.fill" : "bird.fill"
    }

    private var coinView: some View {
        VStack(spacing: 28) {
            ZStack {
                Circle()
                    .fill(mode.theme.accent.opacity(0.22))
                    .frame(width: coinSize * 1.3, height: coinSize * 1.3)
                    .blur(radius: 24)

                coinDisc
                    .rotation3DEffect(.degrees(coinAngle), axis: (x: 0, y: 1, z: 0), perspective: 0.35)
                    .offset(y: coinLift)
            }
            .frame(height: coinSize * 1.45)
            .accessibilityElement()
            .accessibilityLabel(isAnimating ? "Coin is flipping" : "Coin showing \(coinFaceIsHeads ? "heads" : "tails")")
            .accessibilityHint(isAnimating ? "Wait for the coin to land" : "The coin is ready to flip")

            if showResult {
                VStack(spacing: 6) {
                    Image(systemName: coinFaceSymbol)
                        .font(.title2)
                        .foregroundStyle(mode.theme.tint)
                        .symbolEffect(.bounce, value: revealTrigger)

                    Text(result)
                        .font(.largeTitle.weight(.bold))
                        .foregroundStyle(.primary)
                }
                .transition(.opacity.combined(with: .scale(scale: 0.9)))
                .accessibilityLabel(L10n.format("a11y.coin.result_format", fallback: "Coin flip result: %@", result))
                .accessibilityHint("The coin landed on \(result.lowercased())")
            }

            PrimaryActionButton(
                title: isAnimating ? "Flipping..." : "Flip Coin!",
                theme: mode.theme,
                isBusy: isAnimating,
                action: flipCoin
            )
            .accessibilityLabel(isAnimating ? "Flipping coin" : "Flip coin")
            .accessibilityHint(
                isAnimating
                    ? "Please wait while the coin is being flipped"
                    : "Tap to flip the coin and get heads or tails"
            )
        }
    }

    private var coinDisc: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [mode.theme.accent, mode.theme.tint],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            Circle()
                .strokeBorder(.white.opacity(0.5), lineWidth: 3)

            Image(systemName: coinFaceSymbol)
                .font(.system(size: heroGlyphSize, weight: .semibold))
                .foregroundStyle(mode.theme.onAccent)
                .rotation3DEffect(
                    .degrees(coinFaceIsHeads ? 0 : 180),
                    axis: (x: 0, y: 1, z: 0)
                )
        }
        .frame(width: coinSize, height: coinSize)
        .shadow(color: mode.theme.accent.opacity(0.35), radius: 12, y: 8)
    }

    // MARK: - Yes / No

    private var yesNoView: some View {
        VStack(spacing: 28) {
            Text("🤔")
                .font(.system(size: heroGlyphSize * 1.9))
                .opacity(isAnimating ? 0.6 : 1)
                .scaleEffect(isAnimating && !reduceMotion ? 1.12 : 1)
                .animation(reduceMotion ? nil : .easeInOut(duration: 0.7), value: isAnimating)
                .accessibilityLabel(isAnimating ? "Thinking and deciding" : "Thinking emoji, ready to decide")
                .accessibilityHint(
                    isAnimating
                        ? "Wait while a yes or no decision is being made"
                        : "Tap the button below to get a yes or no answer"
                )

            if showResult {
                VStack(spacing: 6) {
                    Text(result)
                        .font(.system(size: heroGlyphSize, weight: .bold))
                        .foregroundStyle(yesNoWasYes ? Palette.success : Palette.danger)

                    Image(systemName: yesNoWasYes ? "checkmark.seal.fill" : "xmark.seal.fill")
                        .font(.title2)
                        .foregroundStyle(yesNoWasYes ? Palette.success : Palette.danger)
                        .symbolEffect(.bounce, value: revealTrigger)
                }
                .transition(.opacity.combined(with: .scale(scale: 0.9)))
                .accessibilityLabel(L10n.format("a11y.decision.result_format", fallback: "Decision result: %@", result))
                .accessibilityHint("The answer to your yes or no question is \(result)")
            }

            PrimaryActionButton(
                title: isAnimating ? "Deciding..." : "Yes or No?",
                theme: mode.theme,
                isBusy: isAnimating,
                action: generateYesNo
            )
            .accessibilityLabel(isAnimating ? "Making decision" : "Get yes or no answer")
            .accessibilityHint(
                isAnimating
                    ? "Please wait while a decision is being made"
                    : "Tap to get a random yes or no answer to your question"
            )
        }
    }

    // MARK: - Custom Picker

    private var customChoiceView: some View {
        VStack(spacing: 20) {
            Text("Enter Your Options")
                .font(.title3.weight(.bold))
                .foregroundStyle(.primary)

            VStack(spacing: 12) {
                ForEach(customOptions) { option in
                    HStack(spacing: 10) {
                        ThemedField(accent: mode.theme.accent) {
                            TextField(
                                L10n.format(
                                    "custom.option.placeholder_format",
                                    fallback: "Option %d...",
                                    optionNumber(option.id)
                                ),
                                text: binding(for: option.id)
                            )
                            .foregroundStyle(.primary)
                            .disabled(isAnimating)
                        }
                        .accessibilityLabel(
                            L10n.format("custom.option.label_format", fallback: "Option %d", optionNumber(option.id))
                        )
                        .accessibilityHint("Enter a choice for random selection")

                        if customOptions.count > 2 {
                            Button {
                                removeChoice(id: option.id)
                            } label: {
                                Image(systemName: "xmark")
                                    .font(.footnote.weight(.semibold))
                                    .foregroundStyle(Palette.danger)
                                    .frame(width: 36, height: 36)
                                    .background(Palette.danger.opacity(0.14), in: Circle())
                            }
                            .disabled(isAnimating)
                            .accessibilityLabel(
                                L10n.format(
                                    "custom.option.remove_label_format",
                                    fallback: "Remove option %d",
                                    optionNumber(option.id)
                                )
                            )
                            .accessibilityHint("Remove this option from the list")
                        }
                    }
                }
            }

            Button {
                addChoice()
            } label: {
                Label("Add Option", systemImage: "plus")
                    .font(.subheadline.weight(.semibold))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 9)
            }
            .buttonStyle(.bordered)
            .disabled(customOptions.count >= 6 || isAnimating)
            .accessibilityLabel("Add option")
            .accessibilityHint(
                customOptions.count >= 6
                    ? "Maximum of 6 options reached"
                    : "Add another option to choose from"
            )

            if showWheel || showResult {
                pickerStage
                    .frame(minHeight: wheelStageHeight)
            }

            PrimaryActionButton(
                title: isAnimating ? "Choosing..." : "Pick for Me!",
                theme: mode.theme,
                isBusy: isAnimating,
                action: chooseCustom
            )
            .accessibilityLabel(isAnimating ? "Making selection" : "Pick random option")
            .accessibilityHint(
                isAnimating
                    ? "Please wait while a random choice is being selected"
                    : "Tap to randomly select one of your custom options"
            )
        }
    }

    private var wheelStageHeight: CGFloat { wheelRadius * 2 + 60 }

    @ScaledMetric(relativeTo: .body) private var wheelRadius: CGFloat = 88

    private func optionNumber(_ id: CustomOption.ID) -> Int {
        (customOptions.firstIndex { $0.id == id } ?? 0) + 1
    }

    private func binding(for id: CustomOption.ID) -> Binding<String> {
        Binding(
            get: { customOptions.first { $0.id == id }?.text ?? "" },
            set: { newValue in
                guard let index = customOptions.firstIndex(where: { $0.id == id }) else { return }
                customOptions[index].text = newValue
            }
        )
    }

    @ViewBuilder
    private var pickerStage: some View {
        if showResult {
            VStack(spacing: 8) {
                Text("The winner is...")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)

                Text(result)
                    .font(.title2.weight(.bold))
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.center)

                Text("🎉")
                    .font(.largeTitle)
            }
            .transition(.opacity.combined(with: .scale(scale: 0.9)))
            .accessibilityLabel(L10n.format("a11y.selection.result_format", fallback: "Selection result: %@", result))
            .accessibilityHint("The randomly chosen option from your custom choices is \(result)")
        } else if showWheel {
            wheel
                .transition(.opacity)
        }
    }

    private var wheel: some View {
        let choices = wheelChoices
        let step = 360.0 / Double(max(choices.count, 1))

        return ZStack {
            Circle()
                .strokeBorder(mode.theme.accent.opacity(0.25), lineWidth: 1)
                .frame(width: wheelRadius * 2 + 44, height: wheelRadius * 2 + 44)

            ForEach(Array(choices.enumerated()), id: \.offset) { index, choice in
                let angle = Double(index) * step * .pi / 180

                Text(choice)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                    .frame(maxWidth: 118)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(mode.theme.accent.opacity(0.16), in: Capsule())
                    .overlay(
                        Capsule().strokeBorder(mode.theme.accent.opacity(0.4), lineWidth: 1)
                    )
                    // Counter-rotate so each option stays upright while the wheel turns.
                    .rotationEffect(.degrees(-wheelAngle))
                    .offset(x: sin(angle) * wheelRadius, y: -cos(angle) * wheelRadius)
            }
        }
        .rotationEffect(.degrees(wheelAngle))
        .frame(width: wheelRadius * 2 + 60, height: wheelRadius * 2 + 60)
        .overlay(alignment: .top) {
            Image(systemName: "arrowtriangle.down.fill")
                .font(.footnote)
                .foregroundStyle(mode.theme.tint)
                .offset(y: -6)
        }
    }

    // MARK: - Rock Paper Scissors

    private var rpsView: some View {
        VStack(spacing: 26) {
            HStack(spacing: 18) {
                ForEach(Array(RPSChoice.allCases.enumerated()), id: \.offset) { index, choice in
                    Text(choice.emoji)
                        .font(.system(size: heroGlyphSize * 1.1))
                        .opacity(isAnimating ? 0.55 : 1)
                        .scaleEffect(isAnimating && !reduceMotion ? 1.14 : 1)
                        .animation(
                            reduceMotion
                                ? nil
                                : .easeInOut(duration: 0.42)
                                    .repeatForever(autoreverses: true)
                                    .delay(Double(index) * 0.12),
                            value: isAnimating
                        )
                }
            }
            .accessibilityElement()
            .accessibilityLabel(isAnimating ? "Choosing rock, paper, or scissors" : "Hand emojis, ready to play")
            .accessibilityHint(
                isAnimating
                    ? "Wait while a choice is being made"
                    : "Tap the button below to see what the opponent chose"
            )

            Text("Think of your choice...")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            if showResult {
                VStack(spacing: 10) {
                    Text("Opponent chose:")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)

                    Text(rpsChoice.emoji)
                        .font(.system(size: heroGlyphSize * 1.5))

                    Text(rpsChoice.label)
                        .font(.title.weight(.bold))
                        .foregroundStyle(.primary)
                }
                .transition(.opacity.combined(with: .scale(scale: 0.9)))
                .accessibilityLabel("Opponent chose \(rpsChoice.label)")
                .accessibilityHint("Compare this to your mental choice to see if you won")
            }

            PrimaryActionButton(
                title: isAnimating ? "Choosing..." : "Shoot!",
                theme: mode.theme,
                isBusy: isAnimating,
                action: playRPS
            )
            .accessibilityLabel(isAnimating ? "Making choice" : "Reveal opponent's choice")
            .accessibilityHint(
                isAnimating
                    ? "Please wait while a choice is being made"
                    : "Tap to see what the opponent chose"
            )
        }
    }

    // MARK: - Magic Orb

    private var orbView: some View {
        VStack(spacing: 26) {
            orbHero
                .accessibilityElement()
                .accessibilityLabel(
                    isAnimating
                        ? L10n.string("orb.a11y.label.contemplating", fallback: "The orb is contemplating")
                        : L10n.string("orb.a11y.label.ready", fallback: "Crystal orb, ready to reveal your fate")
                )
                .accessibilityHint(
                    isAnimating
                        ? L10n.string("orb.a11y.hint.wait", fallback: "Wait while the orb reveals its wisdom")
                        : L10n.string("orb.a11y.hint.ask", fallback: "Tap the button below to ask the orb")
                )

            if showResult {
                VStack(spacing: 8) {
                    Text("The orb speaks:")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Text(result)
                        .font(.title3.weight(.bold))
                        .foregroundStyle(.primary)
                        .multilineTextAlignment(.center)
                }
                .transition(.opacity.combined(with: .scale(scale: 0.94)))
                .accessibilityLabel(L10n.format("orb.a11y.says_format", fallback: "The orb says: %@", result))
            } else {
                Text("Ask your question...")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            PrimaryActionButton(
                title: isAnimating
                    ? L10n.string("orb.button.consulting", fallback: "Consulting...")
                    : L10n.string("orb.button.ask", fallback: "Ask the Orb"),
                theme: mode.theme,
                isBusy: isAnimating,
                action: askOrb
            )
            .accessibilityLabel(
                isAnimating
                    ? L10n.string("orb.button.a11y.label.consulting", fallback: "Consulting the orb")
                    : L10n.string("orb.button.a11y.label.ask", fallback: "Ask the orb")
            )
            .accessibilityHint(
                isAnimating
                    ? L10n.string("orb.button.a11y.hint.wait", fallback: "Please wait while the orb reveals its wisdom")
                    : L10n.string("orb.button.a11y.hint.ask", fallback: "Tap to ask the orb for guidance")
            )
        }
    }

    private var orbHero: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            mode.theme.accent.opacity(0.55),
                            mode.theme.accent.opacity(0.16),
                            .clear
                        ],
                        center: .center,
                        startRadius: 8,
                        endRadius: orbSize * 0.72
                    )
                )
                .frame(width: orbSize * 1.3, height: orbSize * 1.3)
                .blur(radius: isAnimating ? 8 : 3)

            Text("🔮")
                .font(.system(size: heroGlyphSize * 1.9))
                .opacity(isAnimating ? 0.75 : 1)
                .scaleEffect(isAnimating && !reduceMotion ? 1.06 : 1)
                .animation(reduceMotion ? nil : .easeInOut(duration: 1.1), value: isAnimating)
        }
        .frame(height: orbSize * 1.3)
        .idleBreathing(!reduceMotion, scale: 1.035, duration: 2.8)
    }

    // MARK: - Random Number

    private var rngView: some View {
        VStack(spacing: 18) {
            VStack(spacing: 6) {
                Text("Random Number Generator")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(.primary)

                Text("Generate a random whole number within a selected range.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            VStack(spacing: 12) {
                rngField(
                    title: "Minimum Number",
                    placeholder: "1",
                    text: $rngMinText
                )

                rngField(
                    title: "Maximum Number",
                    placeholder: "100",
                    text: $rngMaxText
                )
            }

            Toggle(isOn: $rngNoImmediateRepeat) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("No Immediate Repeat")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                    Text("Prevents the next generated number from matching the previous one.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .disabled(isAnimating)
            .onChange(of: rngNoImmediateRepeat) { _, _ in
                rngErrorMessage = nil
            }

            if let rngErrorMessage {
                Text(rngErrorMessage)
                    .font(.footnote)
                    .foregroundStyle(Palette.danger)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .transition(.opacity)
            }

            VStack(spacing: 8) {
                Text("Generated Number")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)

                if showResult {
                    Text(result)
                        .font(.system(size: rngNumberSize, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)
                        .contentTransition(.numericText())
                        .transition(.opacity.combined(with: .scale(scale: 0.96)))
                        .accessibilityLabel(
                            L10n.format("a11y.rng.result_format", fallback: "Generated number: %@", result)
                        )
                } else {
                    Text("Your generated number will appear here.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .padding(.horizontal, 12)
            .background(Palette.field, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .animation(.snappy(duration: 0.3), value: result)

            PrimaryActionButton(
                title: isAnimating ? "Generating..." : "Generate Number",
                theme: mode.theme,
                isBusy: isAnimating,
                action: generateRandomNumber
            )
            .accessibilityLabel(isAnimating ? "Generating..." : "Generate Number")
            .accessibilityHint(
                isAnimating
                    ? "Please wait while a number is generated"
                    : "Tap to generate a random number in your selected range"
            )
        }
    }

    private func rngField(title: String, placeholder: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.primary)

            ThemedField(accent: mode.theme.accent) {
                TextField(placeholder, text: text)
                    .keyboardType(.numbersAndPunctuation)
                    .foregroundStyle(.primary)
                    .disabled(isAnimating)
            }
        }
        .onChange(of: text.wrappedValue) { _, _ in
            rngErrorMessage = nil
        }
    }

    // MARK: - Mode Switching

    private func switchMode(_ newMode: DecisionMode) {
        guard newMode != mode else { return }

        decisionTask?.cancel()
        isAnimating = false
        playSound("select")

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

    private func run(_ mode: DecisionMode) {
        switch mode {
        case .coin: flipCoin()
        case .yesno: generateYesNo()
        case .custom: chooseCustom()
        case .rps: playRPS()
        case .orb: askOrb()
        case .rng: generateRandomNumber()
        }
    }

    // MARK: - Quick Actions

    private func handlePendingRequest() {
        guard let requested = quickActions.requestedMode else { return }
        quickActions.requestedMode = nil

        switchMode(requested)

        // Custom and RNG need user input before they can produce a result.
        guard requested.runsOnOpen else { return }

        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(450))
            guard !Task.isCancelled else { return }
            run(requested)
        }
    }

    // MARK: - Coin Flow

    private func flipCoin() {
        guard !isAnimating else { return }

        decisionTask?.cancel()
        playSound("coin")
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

            playSound(isHeads ? "crown" : "eagle")

            let spokenSide = isHeads
                ? L10n.string("coin.result.heads.spoken", fallback: "heads")
                : L10n.string("coin.result.tails.spoken", fallback: "tails")
            announceForVoiceOver(
                L10n.format("vo.coin.landed_format", fallback: "Coin landed on %@", spokenSide)
            )
        }
    }

    // MARK: - Yes / No Flow

    private func generateYesNo() {
        guard !isAnimating else { return }

        decisionTask?.cancel()
        playSound("decision")
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

            playSound(isYes ? "yesChord" : "noTrombone")

            let answer = isYes
                ? L10n.string("yesno.answer.yes.spoken", fallback: "yes")
                : L10n.string("yesno.answer.no.spoken", fallback: "no")
            announceForVoiceOver(
                L10n.format("vo.answer.is_format", fallback: "The answer is %@", answer)
            )
        }
    }

    // MARK: - Custom Picker Flow

    private func addChoice() {
        guard customOptions.count < 6 else { return }
        withAnimation(.snappy(duration: 0.3)) {
            customOptions.append(CustomOption())
        }
    }

    private func removeChoice(id: CustomOption.ID) {
        guard customOptions.count > 2 else { return }
        withAnimation(.snappy(duration: 0.3)) {
            customOptions.removeAll { $0.id == id }
        }
    }

    private var validCustomChoices: [String] {
        customOptions
            .map(\.text)
            .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    }

    private func chooseCustom() {
        let choices = validCustomChoices

        guard choices.count >= 2 else {
            errorTrigger += 1
            playSound("error")
            showAlert = true
            return
        }

        guard !isAnimating else { return }

        decisionTask?.cancel()
        playSound("shuffle")
        tapTrigger += 1
        isAnimating = true
        showResult = false

        let winnerIndex = Int.random(in: 0..<choices.count)
        let winner = choices[winnerIndex]

        wheelChoices = choices
        wheelAngle = 0

        withAnimation(.easeIn(duration: 0.25)) {
            showWheel = true
        }

        if !reduceMotion {
            let step = 360.0 / Double(choices.count)
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
            playSound("success")

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

    private func playRPS() {
        guard !isAnimating else { return }

        decisionTask?.cancel()
        playSound("decision")
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

            playSound(choice.sound)

            announceForVoiceOver(
                L10n.format("vo.rps.opponent_chose_format", fallback: "Opponent chose %@", choice.label)
            )
        }
    }

    // MARK: - Orb Flow

    private func askOrb() {
        guard !isAnimating else { return }

        decisionTask?.cancel()
        playSound("decision")
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

            playSound("mystical")

            announceForVoiceOver(
                L10n.format("orb.a11y.says_format", fallback: "The orb says: %@", response.text)
            )
        }
    }

    // MARK: - Random Number Flow

    private func generateRandomNumber() {
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

            playSound("rngDing")

            announceForVoiceOver(
                L10n.format("rng.a11y.generated_number_format", fallback: "Generated number: %d", generated)
            )
        }
    }

    private func failRandomNumber(_ message: String) {
        rngErrorMessage = message
        errorTrigger += 1
        playSound("error")
    }

    // MARK: - Sound

    private func playSound(_ soundName: String) {
        // Use system sounds for lightweight playback
        switch soundName {
        case "coin":
            AudioServicesPlaySystemSound(1306) // Peek sound - bright and metallic like coin
        case "decision":
            AudioServicesPlaySystemSound(1057) // SMS Received 1 - subtle chime
        case "shuffle":
            AudioServicesPlaySystemSound(1519) // Begin Video Record - shuffling sound
        case "select":
            AudioServicesPlaySystemSound(1519) // Gentle selection sound
        case "rngDing":
            playFile(named: "rng_ding")
        case "success":
            AudioServicesPlaySystemSound(1025) // PhotoShutter - success sound
        case "yesChord":
            playFile(named: "c-chord-83638")
        case "noTrombone":
            playFile(named: "wah-wah-sad-trombone-6347")
        case "eagle":
            playFile(named: "eagle-sound-by-torma-368637")
        case "crown":
            playFile(named: "success-fanfare-trumpets-6185")
        case "thud":
            playFile(named: "thud-82914")
        case "slick":
            playFile(named: "steel-blade-slice-4-188216")
        case "paper":
            playFile(named: "crumping-paper-109585")
        case "mystical":
            playFile(named: "mystical-355968")
        case "error":
            AudioServicesPlaySystemSound(1053) // Error sound
        default:
            break
        }
    }

    private func playFile(named resource: String) {
        guard let url = Bundle.main.url(forResource: resource, withExtension: "mp3") else { return }
        audioPlayer = try? AVAudioPlayer(contentsOf: url)
        audioPlayer?.play()
    }

    // MARK: - Accessibility

    private func announceForVoiceOver(_ message: String) {
        #if canImport(UIKit)
        UIAccessibility.post(notification: .announcement, argument: message)
        #endif
    }
}

// MARK: - Idle Breathing

extension View {
    /// A slow, continuous breathe used to keep hero elements alive at rest.
    @ViewBuilder
    func idleBreathing(_ isActive: Bool, scale: CGFloat = 1.03, duration: Double = 2.6) -> some View {
        if isActive {
            phaseAnimator([false, true]) { content, lifted in
                content.scaleEffect(lifted ? scale : 1)
            } animation: { _ in
                .easeInOut(duration: duration)
            }
        } else {
            self
        }
    }
}

// MARK: - Credits View

struct CreditsView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                TipJarSectionView()

                Section(header: Text("Sound Effects")) {
                    Text("All sound effects in this app were sourced from creators on Pixabay.")
                        .foregroundStyle(.secondary)
                        .padding(.vertical, 4)
                        .accessibilityLabel("All sound effects in this app were sourced from creators on Pixabay.")
                }

                Section(header: Text("Accessibility")) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("This app supports:")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        VStack(alignment: .leading, spacing: 6) {
                            Label("VoiceOver with detailed labels", systemImage: "speaker.wave.3")
                            Label("Reduce Motion support", systemImage: "figure.walk")
                            Label("High Contrast mode", systemImage: "circle.lefthalf.filled")
                            Label("Dynamic Type", systemImage: "textformat.size")
                            Label("Haptic feedback", systemImage: "hand.tap")
                        }
                        .font(.subheadline)
                    }
                    .padding(.vertical, 4)
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("Accessibility features: VoiceOver with detailed labels, Reduce Motion support, High Contrast mode, Dynamic Type, and Haptic feedback")
                }

                AboutSectionView(currentAppName: "Yes? No? Go!")
            }
            .navigationTitle("Credits")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .accessibilityLabel("Close credits")
                    .accessibilityHint("Dismiss the credits screen")
                }
            }
        }
    }
}
