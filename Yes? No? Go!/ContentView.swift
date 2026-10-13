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

    @ScaledMetric(relativeTo: .largeTitle) private var rngNumberSize: CGFloat = 56

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
        case .custom: CustomPickerView(session: session)
        case .rps: RockPaperScissorsView(session: session)
        case .orb: MagicOrbView(session: session)
        case .rng: rngView
        }
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
