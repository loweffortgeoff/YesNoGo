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
        case .rng: RandomNumberView(session: session)
        }
    }
}
