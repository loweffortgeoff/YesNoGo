//
//  ContentView.swift
//  Yes? No? Go!
//
//  Created by Geoffrey Silva on 11/1/25.
//

import SwiftUI

// MARK: - Content View

/// The app chrome around the current decision mode: the mode selector, the
/// decision card, the toolbar, and the history and credits sheets. The decision
/// state and the six flows live in `DecisionSession`.
struct ContentView: View {
    @State private var session = DecisionSession()
    @State private var showCredits = false
    @State private var showHistory = false

    @ScaledMetric(relativeTo: .largeTitle) private var heroGlyphSize: CGFloat = 58
    @ScaledMetric(relativeTo: .largeTitle) private var orbSize: CGFloat = 148
    @ScaledMetric(relativeTo: .largeTitle) private var rngNumberSize: CGFloat = 56
    @ScaledMetric(relativeTo: .body) private var wheelRadius: CGFloat = 88

    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ZStack {
                BrandCanvas(theme: session.mode.theme)

                ScrollView {
                    VStack(spacing: 18) {
                        ModeSelectorBar(
                            selection: session.mode,
                            showsLabels: horizontalSizeClass == .regular,
                            onSelect: session.switchMode
                        )

                        DecisionCard(theme: session.mode.theme) {
                            modeContent
                                .id(session.mode)
                                .transition(.opacity.combined(with: .scale(scale: 0.97)))
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 4)
                    .padding(.bottom, 24)
                }
                .scrollBounceBehavior(.basedOnSize)
            }
            .navigationTitle(session.mode.label)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .tint(session.mode.theme.tint)
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
                isPresented: $session.showAlert
            ) {
                Button(L10n.string("common.ok", fallback: "OK")) { }
            }
            .sheet(isPresented: $showHistory) {
                HistoryView(mode: session.mode)
            }
            .sheet(isPresented: $showCredits) {
                CreditsView()
            }
            .sensoryFeedback(.selection, trigger: session.mode)
            .sensoryFeedback(.impact(weight: .medium), trigger: session.tapTrigger)
            .sensoryFeedback(.success, trigger: session.revealTrigger)
            .sensoryFeedback(.error, trigger: session.errorTrigger)
            .onAppear {
                session.handlePendingRequest(reduceMotion: reduceMotion)
            }
            .onChange(of: QuickActionManager.shared.requestedMode) { _, _ in
                // Covers the cold launch case, where the quick action or URL
                // arrives before this view is on screen.
                session.handlePendingRequest(reduceMotion: reduceMotion)
            }
            .onChange(of: scenePhase) { _, newPhase in
                if newPhase == .active {
                    session.handlePendingRequest(reduceMotion: reduceMotion)
                }
            }
            .onDisappear {
                session.cancelCurrentFlow()
            }
        }
    }

    // MARK: - Mode Content

    @ViewBuilder
    private var modeContent: some View {
        switch session.mode {
        case .coin: CoinFlipView(session: session)
        case .yesno: YesNoDecisionView(session: session)
        case .custom: customChoiceView
        case .rps: rpsView
        case .orb: orbView
        case .rng: rngView
        }
    }

    // MARK: - Custom Picker

    private var customChoiceView: some View {
        VStack(spacing: 20) {
            Text("Enter Your Options")
                .font(.title3.weight(.bold))
                .foregroundStyle(.primary)

            VStack(spacing: 12) {
                ForEach(session.customOptions) { option in
                    HStack(spacing: 10) {
                        ThemedField(accent: session.mode.theme.accent) {
                            TextField(
                                L10n.format(
                                    "custom.option.placeholder_format",
                                    fallback: "Option %d...",
                                    session.optionNumber(option.id)
                                ),
                                text: session.binding(for: option.id)
                            )
                            .foregroundStyle(.primary)
                            .disabled(session.isAnimating)
                        }
                        .accessibilityLabel(
                            L10n.format("custom.option.label_format", fallback: "Option %d", session.optionNumber(option.id))
                        )
                        .accessibilityHint("Enter a choice for random selection")

                        if session.customOptions.count > 2 {
                            Button {
                                session.removeChoice(id: option.id)
                            } label: {
                                Image(systemName: "xmark")
                                    .font(.footnote.weight(.semibold))
                                    .foregroundStyle(Palette.danger)
                                    .frame(width: 36, height: 36)
                                    .background(Palette.danger.opacity(0.14), in: Circle())
                            }
                            .disabled(session.isAnimating)
                            .accessibilityLabel(
                                L10n.format(
                                    "custom.option.remove_label_format",
                                    fallback: "Remove option %d",
                                    session.optionNumber(option.id)
                                )
                            )
                            .accessibilityHint("Remove this option from the list")
                        }
                    }
                }
            }

            Button {
                session.addChoice()
            } label: {
                Label("Add Option", systemImage: "plus")
                    .font(.subheadline.weight(.semibold))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 9)
            }
            .buttonStyle(.bordered)
            .disabled(session.customOptions.count >= 6 || session.isAnimating)
            .accessibilityLabel("Add option")
            .accessibilityHint(
                session.customOptions.count >= 6
                    ? "Maximum of 6 options reached"
                    : "Add another option to choose from"
            )

            if session.showWheel || session.showResult {
                pickerStage
                    .frame(minHeight: wheelStageHeight)
            }

            PrimaryActionButton(
                title: session.isAnimating ? "Choosing..." : "Pick for Me!",
                theme: session.mode.theme,
                isBusy: session.isAnimating,
                action: { session.chooseCustom(reduceMotion: reduceMotion) }
            )
            .accessibilityLabel(session.isAnimating ? "Making selection" : "Pick random option")
            .accessibilityHint(
                session.isAnimating
                    ? "Please wait while a random choice is being selected"
                    : "Tap to randomly select one of your custom options"
            )
        }
    }

    private var wheelStageHeight: CGFloat { wheelRadius * 2 + 60 }

    @ViewBuilder
    private var pickerStage: some View {
        if session.showResult {
            VStack(spacing: 8) {
                Text("The winner is...")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)

                Text(session.result)
                    .font(.title2.weight(.bold))
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.center)

                Text("🎉")
                    .font(.largeTitle)
            }
            .transition(.opacity.combined(with: .scale(scale: 0.9)))
            .accessibilityLabel(L10n.format("a11y.selection.result_format", fallback: "Selection result: %@", session.result))
            .accessibilityHint("The randomly chosen option from your custom choices is \(session.result)")
        } else if session.showWheel {
            wheel
                .transition(.opacity)
        }
    }

    private var wheel: some View {
        let choices = session.wheelChoices
        let step = 360.0 / Double(max(choices.count, 1))

        return ZStack {
            Circle()
                .strokeBorder(session.mode.theme.accent.opacity(0.25), lineWidth: 1)
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
                    .background(session.mode.theme.accent.opacity(0.16), in: Capsule())
                    .overlay(
                        Capsule().strokeBorder(session.mode.theme.accent.opacity(0.4), lineWidth: 1)
                    )
                    // Counter-rotate so each option stays upright while the wheel turns.
                    .rotationEffect(.degrees(-session.wheelAngle))
                    .offset(x: sin(angle) * wheelRadius, y: -cos(angle) * wheelRadius)
            }
        }
        .rotationEffect(.degrees(session.wheelAngle))
        .frame(width: wheelRadius * 2 + 60, height: wheelRadius * 2 + 60)
        .overlay(alignment: .top) {
            Image(systemName: "arrowtriangle.down.fill")
                .font(.footnote)
                .foregroundStyle(session.mode.theme.tint)
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
                        .opacity(session.isAnimating ? 0.55 : 1)
                        .scaleEffect(session.isAnimating && !reduceMotion ? 1.14 : 1)
                        .animation(
                            reduceMotion
                                ? nil
                                : session.isAnimating
                                    ? .easeInOut(duration: 0.42)
                                        .repeatForever(autoreverses: true)
                                        .delay(Double(index) * 0.12)
                                    : .easeInOut(duration: 0.25),
                            value: session.isAnimating
                        )
                }
            }
            .accessibilityElement()
            .accessibilityLabel(session.isAnimating ? "Choosing rock, paper, or scissors" : "Hand emojis, ready to play")
            .accessibilityHint(
                session.isAnimating
                    ? "Wait while a choice is being made"
                    : "Tap the button below to see what the opponent chose"
            )

            Text("Think of your choice...")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            if session.showResult {
                VStack(spacing: 10) {
                    Text("Opponent chose:")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)

                    Text(session.rpsChoice.emoji)
                        .font(.system(size: heroGlyphSize * 1.5))

                    Text(session.rpsChoice.label)
                        .font(.title.weight(.bold))
                        .foregroundStyle(.primary)
                }
                .transition(.opacity.combined(with: .scale(scale: 0.9)))
                .accessibilityLabel("Opponent chose \(session.rpsChoice.label)")
                .accessibilityHint("Compare this to your mental choice to see if you won")
            }

            PrimaryActionButton(
                title: session.isAnimating ? "Choosing..." : "Shoot!",
                theme: session.mode.theme,
                isBusy: session.isAnimating,
                action: { session.playRPS(reduceMotion: reduceMotion) }
            )
            .accessibilityLabel(session.isAnimating ? "Making choice" : "Reveal opponent's choice")
            .accessibilityHint(
                session.isAnimating
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
                    session.isAnimating
                        ? L10n.string("orb.a11y.label.contemplating", fallback: "The orb is contemplating")
                        : L10n.string("orb.a11y.label.ready", fallback: "Crystal orb, ready to reveal your fate")
                )
                .accessibilityHint(
                    session.isAnimating
                        ? L10n.string("orb.a11y.hint.wait", fallback: "Wait while the orb reveals its wisdom")
                        : L10n.string("orb.a11y.hint.ask", fallback: "Tap the button below to ask the orb")
                )

            if session.showResult {
                VStack(spacing: 8) {
                    Text("The orb speaks:")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Text(session.result)
                        .font(.title3.weight(.bold))
                        .foregroundStyle(.primary)
                        .multilineTextAlignment(.center)
                }
                .transition(.opacity.combined(with: .scale(scale: 0.94)))
                .accessibilityLabel(L10n.format("orb.a11y.says_format", fallback: "The orb says: %@", session.result))
            } else {
                Text("Ask your question...")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            PrimaryActionButton(
                title: session.isAnimating
                    ? L10n.string("orb.button.consulting", fallback: "Consulting...")
                    : L10n.string("orb.button.ask", fallback: "Ask the Orb"),
                theme: session.mode.theme,
                isBusy: session.isAnimating,
                action: { session.askOrb(reduceMotion: reduceMotion) }
            )
            .accessibilityLabel(
                session.isAnimating
                    ? L10n.string("orb.button.a11y.label.consulting", fallback: "Consulting the orb")
                    : L10n.string("orb.button.a11y.label.ask", fallback: "Ask the orb")
            )
            .accessibilityHint(
                session.isAnimating
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
                            session.mode.theme.accent.opacity(0.55),
                            session.mode.theme.accent.opacity(0.16),
                            .clear
                        ],
                        center: .center,
                        startRadius: 8,
                        endRadius: orbSize * 0.72
                    )
                )
                .frame(width: orbSize * 1.3, height: orbSize * 1.3)
                .blur(radius: session.isAnimating ? 8 : 3)

            Text("🔮")
                .font(.system(size: heroGlyphSize * 1.9))
                .opacity(session.isAnimating ? 0.75 : 1)
                .scaleEffect(session.isAnimating && !reduceMotion ? 1.06 : 1)
                .animation(reduceMotion ? nil : .easeInOut(duration: 1.1), value: session.isAnimating)
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
                    text: $session.rngMinText
                )

                rngField(
                    title: "Maximum Number",
                    placeholder: "100",
                    text: $session.rngMaxText
                )
            }

            Toggle(isOn: $session.rngNoImmediateRepeat) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("No Immediate Repeat")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                    Text("Prevents the next generated number from matching the previous one.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .disabled(session.isAnimating)
            .onChange(of: session.rngNoImmediateRepeat) { _, _ in
                session.clearRandomNumberError()
            }

            if let rngErrorMessage = session.rngErrorMessage {
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

                if session.showResult {
                    Text(session.result)
                        .font(.system(size: rngNumberSize, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)
                        .contentTransition(.numericText())
                        .transition(.opacity.combined(with: .scale(scale: 0.96)))
                        .accessibilityLabel(
                            L10n.format("a11y.rng.result_format", fallback: "Generated number: %@", session.result)
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
            .animation(.snappy(duration: 0.3), value: session.result)

            PrimaryActionButton(
                title: session.isAnimating ? "Generating..." : "Generate Number",
                theme: session.mode.theme,
                isBusy: session.isAnimating,
                action: { session.generateRandomNumber(reduceMotion: reduceMotion) }
            )
            .accessibilityLabel(session.isAnimating ? "Generating..." : "Generate Number")
            .accessibilityHint(
                session.isAnimating
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

            ThemedField(accent: session.mode.theme.accent) {
                TextField(placeholder, text: text)
                    .keyboardType(.numbersAndPunctuation)
                    .foregroundStyle(.primary)
                    .disabled(session.isAnimating)
            }
        }
        .onChange(of: text.wrappedValue) { _, _ in
            session.clearRandomNumberError()
        }
    }
}
