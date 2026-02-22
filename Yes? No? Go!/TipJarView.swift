//
//  TipJarView.swift
//  Yes? No? Go!
//
//  Tip jar UI for supporting the developer.
//

import SwiftUI
import StoreKit
#if canImport(UIKit)
import UIKit
#endif

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

                    // Rate/review CTA
                    rateAndReviewSection

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
            .navigationTitle(L10n.string("tipjar.nav.title", fallback: "Support Development"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L10n.string("common.done", fallback: "Done")) {
                        dismiss()
                    }
                }
            }
            .alert(L10n.string("tipjar.alert.thank_you.title", fallback: "Thank You!"), isPresented: Bindable(tipJarManager).showThankYou) {
                Button(L10n.string("tipjar.alert.thank_you.dismiss", fallback: "You're Welcome!")) {
                    tipJarManager.resetState()
                }
            } message: {
                Text(L10n.string("tipjar.alert.thank_you.message", fallback: "Your support means the world! Thank you for helping keep Yes? No? Go! running."))
            }
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: 16) {
            Image("yesnogoclear")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 80, height: 80)
                .clipShape(RoundedRectangle(cornerRadius: 18))
                .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)

            Text(L10n.string("tipjar.header.title", fallback: "Support Yes? No? Go!"))
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)

            Text(L10n.string("tipjar.header.subtitle", fallback: "Yes? No? Go! is free with no ads or subscriptions. If you find it useful, consider leaving a tip to support future development."))
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

            Text(L10n.string("tipjar.loading", fallback: "Loading tip options..."))
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

    private var rateAndReviewSection: some View {
        Button(action: requestAppReview) {
            HStack(spacing: 12) {
                Image(systemName: "star.bubble.fill")
                    .font(.title3)
                    .foregroundStyle(.yellow)

                VStack(alignment: .leading, spacing: 4) {
                    Text(L10n.string("tipjar.rate.title", fallback: "Rate & Review"))
                        .font(.headline)
                        .foregroundStyle(.primary)
                    Text(L10n.string("tipjar.rate.subtitle", fallback: "Enjoying the app? A quick App Store rating helps a lot."))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(uiColor: .secondarySystemBackground))
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(L10n.string("tipjar.rate.a11y.label", fallback: "Rate and review the app"))
        .accessibilityHint(L10n.string("tipjar.rate.a11y.hint", fallback: "Opens Apple's in-app App Store review prompt"))
    }

    private var footerSection: some View {
        VStack(spacing: 8) {
            Text(L10n.string("tipjar.footer.disclaimer", fallback: "Tips are one-time purchases and do not unlock any features."))
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

    private func requestAppReview() {
        #if canImport(UIKit)
        let activeScene = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first(where: { $0.activationState == .foregroundActive })

        if let activeScene {
            AppStore.requestReview(in: activeScene)
        } else if let anyScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            AppStore.requestReview(in: anyScene)
        }
        #endif
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
        case TipJarManager.heroTipID:
            return "🦸"
        default:
            return "💝"
        }
    }

    private var tipName: String {
        switch product.id {
        case TipJarManager.smallTipID:
            return L10n.string("tipjar.tip.small.name", fallback: "Small Tip")
        case TipJarManager.mediumTipID:
            return L10n.string("tipjar.tip.medium.name", fallback: "Medium Tip")
        case TipJarManager.largeTipID:
            return L10n.string("tipjar.tip.large.name", fallback: "Large Tip")
        case TipJarManager.heroTipID:
            return L10n.string("tipjar.tip.hero.name", fallback: "Hero Tip")
        default:
            return product.displayName
        }
    }

    private var subtitle: String {
        switch product.id {
        case TipJarManager.smallTipID:
            return L10n.string("tipjar.tip.small.subtitle", fallback: "Buy me a coffee")
        case TipJarManager.mediumTipID:
            return L10n.string("tipjar.tip.medium.subtitle", fallback: "Buy me lunch")
        case TipJarManager.largeTipID:
            return L10n.string("tipjar.tip.large.subtitle", fallback: "You're amazing!")
        case TipJarManager.heroTipID:
            return L10n.string("tipjar.tip.hero.subtitle", fallback: "You're a superhero!")
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
