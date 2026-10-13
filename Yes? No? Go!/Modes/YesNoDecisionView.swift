//
//  YesNoDecisionView.swift
//  Yes? No? Go!
//

import SwiftUI

/// The yes-or-no decision: a thinking face while the answer is chosen, then the
/// answer itself.
struct YesNoDecisionView: View {
    let session: DecisionSession

    @ScaledMetric(relativeTo: .largeTitle) private var heroGlyphSize: CGFloat = 58

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(spacing: 28) {
            Text("🤔")
                .font(.system(size: heroGlyphSize * 1.9))
                .opacity(session.isAnimating ? 0.6 : 1)
                .scaleEffect(session.isAnimating && !reduceMotion ? 1.12 : 1)
                .animation(reduceMotion ? nil : .easeInOut(duration: 0.7), value: session.isAnimating)
                .accessibilityLabel(session.isAnimating ? "Thinking and deciding" : "Thinking emoji, ready to decide")
                .accessibilityHint(
                    session.isAnimating
                        ? "Wait while a yes or no decision is being made"
                        : "Tap the button below to get a yes or no answer"
                )

            if session.showResult {
                VStack(spacing: 6) {
                    Text(session.result)
                        .font(.system(size: heroGlyphSize, weight: .bold))
                        .foregroundStyle(session.yesNoWasYes ? Palette.success : Palette.danger)

                    Image(systemName: session.yesNoWasYes ? "checkmark.seal.fill" : "xmark.seal.fill")
                        .font(.title2)
                        .foregroundStyle(session.yesNoWasYes ? Palette.success : Palette.danger)
                        .symbolEffect(.bounce, value: session.revealTrigger)
                }
                .transition(.opacity.combined(with: .scale(scale: 0.9)))
                .accessibilityLabel(L10n.format("a11y.decision.result_format", fallback: "Decision result: %@", session.result))
                .accessibilityHint("The answer to your yes or no question is \(session.result)")
            }

            PrimaryActionButton(
                title: session.isAnimating ? "Deciding..." : "Yes or No?",
                theme: session.mode.theme,
                isBusy: session.isAnimating,
                action: { session.generateYesNo(reduceMotion: reduceMotion) }
            )
            .accessibilityLabel(session.isAnimating ? "Making decision" : "Get yes or no answer")
            .accessibilityHint(
                session.isAnimating
                    ? "Please wait while a decision is being made"
                    : "Tap to get a random yes or no answer to your question"
            )
        }
    }
}
