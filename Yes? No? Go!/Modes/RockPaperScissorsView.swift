//
//  RockPaperScissorsView.swift
//  Yes? No? Go!
//

import SwiftUI

/// Rock, paper, scissors: the hand emojis bob while the opponent's choice is
/// picked, then the choice is revealed.
struct RockPaperScissorsView: View {
    let session: DecisionSession

    @ScaledMetric(relativeTo: .largeTitle) private var heroGlyphSize: CGFloat = 58

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
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
}
