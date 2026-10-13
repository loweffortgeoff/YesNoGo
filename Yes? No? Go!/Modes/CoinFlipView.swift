//
//  CoinFlipView.swift
//  Yes? No? Go!
//

import SwiftUI

/// The coin flip: a spinning disc that lands on heads or tails.
struct CoinFlipView: View {
    let session: DecisionSession

    @ScaledMetric(relativeTo: .largeTitle) private var coinSize: CGFloat = 128
    @ScaledMetric(relativeTo: .largeTitle) private var heroGlyphSize: CGFloat = 58

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(spacing: 28) {
            ZStack {
                Circle()
                    .fill(session.mode.theme.accent.opacity(0.22))
                    .frame(width: coinSize * 1.3, height: coinSize * 1.3)
                    .blur(radius: 24)

                coinDisc
                    .rotation3DEffect(.degrees(session.coinAngle), axis: (x: 0, y: 1, z: 0), perspective: 0.35)
                    .offset(y: session.coinLift)
            }
            .frame(height: coinSize * 1.45)
            .accessibilityElement()
            .accessibilityLabel(session.isAnimating ? "Coin is flipping" : "Coin showing \(coinFaceIsHeads ? "heads" : "tails")")
            .accessibilityHint(session.isAnimating ? "Wait for the coin to land" : "The coin is ready to flip")

            if session.showResult {
                VStack(spacing: 6) {
                    Image(systemName: coinFaceSymbol)
                        .font(.title2)
                        .foregroundStyle(session.mode.theme.tint)
                        .symbolEffect(.bounce, value: session.revealTrigger)

                    Text(session.result)
                        .font(.largeTitle.weight(.bold))
                        .foregroundStyle(.primary)
                }
                .transition(.opacity.combined(with: .scale(scale: 0.9)))
                .accessibilityLabel(L10n.format("a11y.coin.result_format", fallback: "Coin flip result: %@", session.result))
                .accessibilityHint("The coin landed on \(session.result.lowercased())")
            }

            PrimaryActionButton(
                title: session.isAnimating ? "Flipping..." : "Flip Coin!",
                theme: session.mode.theme,
                isBusy: session.isAnimating,
                action: { session.flipCoin(reduceMotion: reduceMotion) }
            )
            .accessibilityLabel(session.isAnimating ? "Flipping coin" : "Flip coin")
            .accessibilityHint(
                session.isAnimating
                    ? "Please wait while the coin is being flipped"
                    : "Tap to flip the coin and get heads or tails"
            )
        }
    }

    private var coinFaceIsHeads: Bool {
        Int((session.coinAngle / 180).rounded()) % 2 == 0
    }

    private var coinFaceSymbol: String {
        coinFaceIsHeads ? "crown.fill" : "bird.fill"
    }

    private var coinDisc: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [session.mode.theme.accent, session.mode.theme.tint],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            Circle()
                .strokeBorder(.white.opacity(0.5), lineWidth: 3)

            Image(systemName: coinFaceSymbol)
                .font(.system(size: heroGlyphSize, weight: .semibold))
                .foregroundStyle(session.mode.theme.onAccent)
                .rotation3DEffect(
                    .degrees(coinFaceIsHeads ? 0 : 180),
                    axis: (x: 0, y: 1, z: 0)
                )
        }
        .frame(width: coinSize, height: coinSize)
        .shadow(color: session.mode.theme.accent.opacity(0.35), radius: 12, y: 8)
    }
}
