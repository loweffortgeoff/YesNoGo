//
//  TipJarView.swift
//  Yes? No? Go!
//
//  Tip jar UI for supporting the developer.
//

import SwiftUI
import StoreKit

struct TipJarView: View {
    @State private var tipJarManager = TipJarManager.shared
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    private var gradientColors: [Color] {
        colorScheme == .dark ?
            [.purple, .pink, .orange] :
            [.purple, .indigo, .pink]
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    headerSection

                    // Tip options
                    if tipJarManager.products.isEmpty {
                        loadingView
                    } else {
                        tipOptionsSection
                    }

                    // Footer message
                    footerSection
                }
                .padding()
            }
            .background(
                LinearGradient(
                    colors: gradientColors,
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
            )
            .navigationTitle("Support Development")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .alert("Thank You!", isPresented: Bindable(tipJarManager).showThankYou) {
                Button("You're Welcome!") {
                    tipJarManager.resetState()
                }
            } message: {
                Text("Your support means the world! Thank you for helping keep Yes? No? Go! running.")
            }
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: 16) {
            Image("yesnogo")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 80, height: 80)
                .clipShape(RoundedRectangle(cornerRadius: 18))
                .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)

            Text("Support Yes? No? Go!")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)

            Text("Yes? No? Go! is free with no ads or subscriptions. If you find it useful, consider leaving a tip to support future development.")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.8))
                .multilineTextAlignment(.center)
        }
        .padding(.top, 20)
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
                .tint(.white)

            Text("Loading tip options...")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.8))
        }
        .frame(height: 200)
    }

    // MARK: - Tip Options

    private var tipOptionsSection: some View {
        VStack(spacing: 16) {
            ForEach(tipJarManager.products, id: \.id) { product in
                TipButton(
                    product: product,
                    isLoading: tipJarManager.purchaseState == .purchasing
                ) {
                    Task {
                        await tipJarManager.purchase(product)
                    }
                }
            }
        }
    }

    // MARK: - Footer

    private var footerSection: some View {
        VStack(spacing: 8) {
            Text("Tips are one-time purchases and do not unlock any features.")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.7))
                .multilineTextAlignment(.center)

            if case .failed(let message) = tipJarManager.purchaseState {
                Text(message)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .padding(.top, 8)
            }
        }
        .padding(.top, 16)
    }
}

// MARK: - Tip Button

struct TipButton: View {
    let product: Product
    let isLoading: Bool
    let action: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    private var emoji: String {
        switch product.id {
        case TipJarManager.smallTipID:
            return "☕️"
        case TipJarManager.mediumTipID:
            return "🍕"
        case TipJarManager.largeTipID:
            return "🎉"
        default:
            return "💝"
        }
    }

    private var tipName: String {
        switch product.id {
        case TipJarManager.smallTipID:
            return "Small Tip"
        case TipJarManager.mediumTipID:
            return "Medium Tip"
        case TipJarManager.largeTipID:
            return "Large Tip"
        default:
            return product.displayName
        }
    }

    private var subtitle: String {
        switch product.id {
        case TipJarManager.smallTipID:
            return "Buy me a coffee"
        case TipJarManager.mediumTipID:
            return "Buy me lunch"
        case TipJarManager.largeTipID:
            return "You're amazing!"
        default:
            return ""
        }
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Text(emoji)
                    .font(.system(size: 32))

                VStack(alignment: .leading, spacing: 4) {
                    Text(tipName)
                        .font(.headline)
                        .foregroundStyle(.primary)

                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                if isLoading {
                    ProgressView()
                } else {
                    Text(product.displayPrice)
                        .font(.headline)
                        .foregroundStyle(.purple)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(uiColor: .secondarySystemBackground))
            )
        }
        .disabled(isLoading)
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview {
    TipJarView()
}
