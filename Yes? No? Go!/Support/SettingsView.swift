//
//  SettingsView.swift
//  Yes? No? Go!
//
//  The info sheet. Laid out like Offshoots Settings: a form on the brand
//  canvas, with each row on the card surface.
//

import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                SoundCreditSection()
                AccessibilitySection()
                AboutSectionView(currentAppName: "Yes? No? Go!")
            }
            .scrollContentBackground(.hidden)
            .background(Palette.canvas)
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                    .accessibilityLabel("Close settings")
                }
            }
        }
    }
}

// MARK: - Sound

private struct SoundCreditSection: View {
    var body: some View {
        Section {
            Text("All sound effects come from creators on Pixabay.")
                .foregroundStyle(.secondary)
        } header: {
            Text("Sound Effects")
        }
        .listRowBackground(Palette.surface)
    }
}

// MARK: - Accessibility

private struct AccessibilitySection: View {
    var body: some View {
        Section {
            AccessibilityFeatureRow(title: "VoiceOver", symbol: "speaker.wave.3")
            AccessibilityFeatureRow(title: "Reduce Motion", symbol: "figure.walk")
            AccessibilityFeatureRow(title: "Increase Contrast", symbol: "circle.lefthalf.filled")
            AccessibilityFeatureRow(title: "Dynamic Type", symbol: "textformat.size")
            AccessibilityFeatureRow(title: "Haptic Feedback", symbol: "hand.tap")
        } header: {
            Text("Accessibility")
        } footer: {
            Text("These follow the settings on this iPhone.")
        }
        .listRowBackground(Palette.surface)
    }
}

private struct AccessibilityFeatureRow: View {
    let title: String
    let symbol: String

    var body: some View {
        Label {
            Text(title)
        } icon: {
            Image(systemName: symbol)
                .foregroundStyle(.secondary)
        }
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    SettingsView()
}
