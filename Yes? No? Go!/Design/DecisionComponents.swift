//
//  DecisionComponents.swift
//  Yes? No? Go!
//
//  Shared chrome: background canvas, decision card, mode selector, and button.
//

import SwiftUI

// MARK: - Brand Canvas

/// The app background. A soft accent wash over a neutral canvas replaces the
/// old full-bleed gradient, so text keeps its contrast.
struct BrandCanvas: View {
    let theme: ModeTheme

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ZStack {
            Palette.canvas

            LinearGradient(
                colors: [
                    theme.accent.opacity(theme.washStrength(dark: colorScheme == .dark)),
                    theme.accent.opacity(0.05),
                    .clear
                ],
                startPoint: .top,
                endPoint: .center
            )

            // A single soft glow adds depth without muddying the surface.
            Circle()
                .fill(theme.accent.opacity(colorScheme == .dark ? 0.28 : 0.20))
                .frame(width: 320, height: 320)
                .blur(radius: 90)
                .offset(y: 90)
        }
        .ignoresSafeArea()
    }
}

// MARK: - Decision Card

/// The surface every mode renders into.
struct DecisionCard<Content: View>: View {
    let theme: ModeTheme
    @ViewBuilder var content: Content

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.colorSchemeContrast) private var contrast

    private var isHighContrast: Bool { contrast == .increased }

    var body: some View {
        content
            .frame(maxWidth: .infinity, minHeight: 360, alignment: .center)
            .padding(28)
            .background {
                ZStack {
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .fill(.regularMaterial)

                    // Lift the surface off the canvas, which matters most in dark mode.
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .fill(Palette.surface.opacity(colorScheme == .dark ? 0.55 : 0.4))

                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .fill(theme.accent.opacity(0.05))
                }
            }
            .overlay {
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .strokeBorder(
                        theme.accent.opacity(isHighContrast ? 0.5 : 0.22),
                        lineWidth: isHighContrast ? 2 : 1
                    )
            }
            .shadow(color: theme.accent.opacity(0.16), radius: 16, y: 8)
    }
}

// MARK: - Mode Selector Bar

/// Equal-width mode segments with a sliding accent indicator.
/// Equal widths keep all six modes on screen, so nothing is clipped.
struct ModeSelectorBar: View {
    let selection: DecisionMode
    let showsLabels: Bool
    let onSelect: (DecisionMode) -> Void

    @Namespace private var indicator

    @Environment(\.colorSchemeContrast) private var contrast

    private var isHighContrast: Bool { contrast == .increased }

    var body: some View {
        HStack(spacing: 4) {
            ForEach(DecisionMode.allCases) { mode in
                segment(for: mode)
            }
        }
        .padding(6)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 26, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .strokeBorder(
                    selection.theme.accent.opacity(isHighContrast ? 0.5 : 0.18),
                    lineWidth: isHighContrast ? 2 : 1
                )
        }
        .accessibilityElement(children: .contain)
    }

    private func segment(for mode: DecisionMode) -> some View {
        let isSelected = mode == selection

        return Button {
            onSelect(mode)
        } label: {
            VStack(spacing: 3) {
                Image(systemName: mode.icon)
                    .font(.title3.weight(.semibold))
                    .symbolVariant(isSelected ? .fill : .none)

                if showsLabels {
                    Text(mode.label)
                        .font(.caption2)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .foregroundStyle(isSelected ? mode.theme.onAccent : Color.secondary)
            .background {
                if isSelected {
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(mode.theme.accent)
                        .matchedGeometryEffect(id: "modeIndicator", in: indicator)
                }
            }
            .contentShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(mode.label)
        .accessibilityHint(L10n.format("a11y.mode.switch_hint_format", fallback: "Switch to %@ mode", mode.label))
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }
}

// MARK: - Primary Action Button

/// The single call-to-action button, shared by every mode.
struct PrimaryActionButton: View {
    let title: String
    let theme: ModeTheme
    var isBusy: Bool = false
    let action: () -> Void

    @Environment(\.colorSchemeContrast) private var contrast

    private var isHighContrast: Bool { contrast == .increased }

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.title3.weight(.semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(theme.accent, in: Capsule())
                .overlay {
                    Capsule()
                        .strokeBorder(
                            isHighContrast ? Color.primary : .clear,
                            lineWidth: isHighContrast ? 2 : 0
                        )
                }
                .foregroundStyle(theme.onAccent)
        }
        .buttonStyle(PressableButtonStyle())
        .disabled(isBusy)
        .opacity(isBusy ? 0.6 : 1)
    }
}

/// A gentle press-in that replaces the old hard-coded scale effect.
struct PressableButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.spring(response: 0.28, dampingFraction: 0.72), value: configuration.isPressed)
    }
}

// MARK: - Themed Field

/// A rounded, theme-aware container for a text field.
struct ThemedField<Content: View>: View {
    let accent: Color
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Palette.field)
            }
            .overlay {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(accent.opacity(0.22), lineWidth: 1)
            }
    }
}
