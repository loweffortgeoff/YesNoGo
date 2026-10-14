//
//  MagicOrbView.swift
//  Yes? No? Go!
//

import SwiftUI

/// Ask the Orb: a breathing crystal ball that reveals a fortune when asked.
struct MagicOrbView: View {
    let session: DecisionSession

    @ScaledMetric(relativeTo: .largeTitle) private var heroGlyphSize: CGFloat = 58
    @ScaledMetric(relativeTo: .largeTitle) private var orbSize: CGFloat = 148

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
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
}
