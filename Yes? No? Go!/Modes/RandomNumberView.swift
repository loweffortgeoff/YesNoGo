//
//  RandomNumberView.swift
//  Yes? No? Go!
//

import SwiftUI

/// The random number generator: a range, an optional no-repeat rule, and the
/// generated number.
struct RandomNumberView: View {
    @Bindable var session: DecisionSession

    @ScaledMetric(relativeTo: .largeTitle) private var rngNumberSize: CGFloat = 56

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
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
