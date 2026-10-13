//
//  CreditsView.swift
//  Yes? No? Go!
//

import SwiftUI

struct CreditsView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                TipJarSectionView()

                Section(header: Text("Sound Effects")) {
                    Text("All sound effects in this app were sourced from creators on Pixabay.")
                        .foregroundStyle(.secondary)
                        .padding(.vertical, 4)
                        .accessibilityLabel("All sound effects in this app were sourced from creators on Pixabay.")
                }

                Section(header: Text("Accessibility")) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("This app supports:")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        VStack(alignment: .leading, spacing: 6) {
                            Label("VoiceOver with detailed labels", systemImage: "speaker.wave.3")
                            Label("Reduce Motion support", systemImage: "figure.walk")
                            Label("High Contrast mode", systemImage: "circle.lefthalf.filled")
                            Label("Dynamic Type", systemImage: "textformat.size")
                            Label("Haptic feedback", systemImage: "hand.tap")
                        }
                        .font(.subheadline)
                    }
                    .padding(.vertical, 4)
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("Accessibility features: VoiceOver with detailed labels, Reduce Motion support, High Contrast mode, Dynamic Type, and Haptic feedback")
                }

                AboutSectionView(currentAppName: "Yes? No? Go!")
            }
            .navigationTitle("Credits")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .accessibilityLabel("Close credits")
                    .accessibilityHint("Dismiss the credits screen")
                }
            }
        }
    }
}
