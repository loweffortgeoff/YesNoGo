//
//  CustomPickerView.swift
//  Yes? No? Go!
//

import SwiftUI

/// The custom picker: an editable list of options and a spinning wheel that
/// lands on the winner.
struct CustomPickerView: View {
    let session: DecisionSession

    @ScaledMetric(relativeTo: .body) private var wheelRadius: CGFloat = 88

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
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
                                    optionNumber(option.id)
                                ),
                                text: binding(for: option.id)
                            )
                            .foregroundStyle(.primary)
                            .disabled(session.isAnimating)
                        }
                        .accessibilityLabel(
                            L10n.format("custom.option.label_format", fallback: "Option %d", optionNumber(option.id))
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
                                    optionNumber(option.id)
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

    private func optionNumber(_ id: CustomOption.ID) -> Int {
        (session.customOptions.firstIndex { $0.id == id } ?? 0) + 1
    }

    private func binding(for id: CustomOption.ID) -> Binding<String> {
        Binding(
            get: { session.customOptions.first { $0.id == id }?.text ?? "" },
            set: { newValue in
                guard let index = session.customOptions.firstIndex(where: { $0.id == id }) else { return }
                session.customOptions[index].text = newValue
            }
        )
    }

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
}
