//
//  TipJarManager.swift
//  Yes? No? Go!
//
//  StoreKit manager for tip jar consumable purchases.
//

import StoreKit
import SwiftUI

@MainActor
@Observable
final class TipJarManager {
    static let shared = TipJarManager()

    // Product IDs from App Store Connect
    static let smallTipID = "com.loweffortapps.yesnogo.tip.small"
    static let mediumTipID = "com.loweffortapps.yesnogo.tip.medium"
    static let largeTipID = "com.loweffortapps.yesnogo.tip.large"

    private(set) var products: [Product] = []
    private(set) var purchaseState: PurchaseState = .idle
    var showThankYou = false

    enum PurchaseState: Equatable {
        case idle
        case loading
        case purchasing
        case purchased
        case failed(String)
    }

    private var updateListenerTask: Task<Void, Error>?

    private init() {
        updateListenerTask = listenForTransactions()
        Task {
            await loadProducts()
        }
    }

    // MARK: - Load Products

    func loadProducts() async {
        purchaseState = .loading

        do {
            let productIDs = [
                Self.smallTipID,
                Self.mediumTipID,
                Self.largeTipID
            ]

            let storeProducts = try await Product.products(for: productIDs)

            // Sort by price
            products = storeProducts.sorted { $0.price < $1.price }
            purchaseState = .idle

            #if DEBUG
            print("[TipJar] Loaded \(products.count) products")
            for product in products {
                print("[TipJar] - \(product.id): \(product.displayPrice)")
            }
            #endif
        } catch {
            purchaseState = .failed("Failed to load products")
            #if DEBUG
            print("[TipJar] Failed to load products: \(error)")
            #endif
        }
    }

    // MARK: - Purchase

    func purchase(_ product: Product) async {
        purchaseState = .purchasing

        do {
            let result = try await product.purchase()

            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)

                // Consumable - finish the transaction immediately
                await transaction.finish()

                purchaseState = .purchased
                showThankYou = true

                #if DEBUG
                print("[TipJar] Purchase successful: \(product.id)")
                #endif

            case .userCancelled:
                purchaseState = .idle
                #if DEBUG
                print("[TipJar] User cancelled purchase")
                #endif

            case .pending:
                purchaseState = .idle
                #if DEBUG
                print("[TipJar] Purchase pending")
                #endif

            @unknown default:
                purchaseState = .idle
            }
        } catch {
            purchaseState = .failed("Purchase failed")
            #if DEBUG
            print("[TipJar] Purchase error: \(error)")
            #endif
        }
    }

    // MARK: - Transaction Listener

    private func listenForTransactions() -> Task<Void, Error> {
        Task.detached {
            for await result in Transaction.updates {
                do {
                    let transaction = try await self.checkVerified(result)

                    // Finish any pending transactions
                    await transaction.finish()

                    await MainActor.run {
                        #if DEBUG
                        print("[TipJar] Transaction update: \(transaction.productID)")
                        #endif
                    }
                } catch {
                    #if DEBUG
                    print("[TipJar] Transaction verification failed: \(error)")
                    #endif
                }
            }
        }
    }

    // MARK: - Verification

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw StoreError.failedVerification
        case .verified(let safe):
            return safe
        }
    }

    // MARK: - Helpers

    func product(for id: String) -> Product? {
        products.first { $0.id == id }
    }

    var smallTip: Product? { product(for: Self.smallTipID) }
    var mediumTip: Product? { product(for: Self.mediumTipID) }
    var largeTip: Product? { product(for: Self.largeTipID) }

    func resetState() {
        if case .failed = purchaseState {
            purchaseState = .idle
        }
        if purchaseState == .purchased {
            purchaseState = .idle
        }
    }
}

// MARK: - Store Error

enum StoreError: Error {
    case failedVerification
}
