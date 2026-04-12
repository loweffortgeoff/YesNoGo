import SwiftUI

// MARK: - Tip Jar Section View
//
// Drop-in Section for any settings screen. Manages its own state and sheet.
// No external dependencies — just place TipJarSectionView() in a Form or List.
// Requires a TipJarView to be defined in the project.

struct TipJarSectionView: View {
    @State private var isPresented = false

    var body: some View {
        Section {
            Button {
                isPresented = true
            } label: {
                HStack {
                    Image(systemName: "heart.fill")
                        .foregroundStyle(.pink)
                    Text("Support Development")
                        .foregroundStyle(.primary)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .sheet(isPresented: $isPresented) {
                TipJarView()
            }
        }
    }
}
