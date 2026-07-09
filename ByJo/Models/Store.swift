//
//  Store.swift
//  ByJo
//
//  Created by Giuseppe Cosenza on 31/10/24.
//

import Foundation
import StoreKit

typealias RenewalInfo = StoreKit.Product.SubscriptionInfo.RenewalInfo
typealias RenewalState = StoreKit.Product.SubscriptionInfo.RenewalState

@Observable
final class Store {
    private var subscriptions: [Product] = []
    var purchasedSubscriptions: [Product] = []
    private var subscriptionGroupStatus: RenewalState?
    var isLoading: Bool = true

    let productIds: [String] = ["bjpro_999_1m_fa", "bjpro_9999_1y_fa", "bjpro_399_1m", "bjpro_3999_1y", "byjo_399_1w"]
    let groupId: String = "21584181"
    let productLifetimeIds: [String] = ["com.giusscos.byjoFamilyLifetime", "com.giusscos.byjoLifetime"]

    private var storeProducts: [Product] = []
    var purchasedProducts: [Product] = []

    var updateListenerTask: Task<Void, Error>? = nil

    init() {
        updateListenerTask = listenForTransactions()

        Task {
            await requestProducts()
            await updateCustomerProductStatus()
            isLoading = false
        }
    }

    deinit {
        updateListenerTask?.cancel()
    }

    func listenForTransactions() -> Task<Void, Error> {
        return Task.detached {
            for await result in Transaction.updates {
                do {
                    let transaction = try self.checkVerified(result)
                    // Directly update purchased state from the verified transaction —
                    // avoids the currentEntitlements timing gap right after purchase.
                    await self.handleVerifiedTransaction(transaction)
                    await transaction.finish()
                } catch {
                    print("[Store] transaction failed verification: \(error)")
                }
            }
        }
    }

    @MainActor
    func handleVerifiedTransaction(_ transaction: Transaction) {
        switch transaction.productType {
        case .autoRenewable:
            if let sub = subscriptions.first(where: { $0.id == transaction.productID }),
               !purchasedSubscriptions.contains(where: { $0.id == sub.id }) {
                purchasedSubscriptions.append(sub)
                print("[Store] handleVerifiedTransaction — subscription: \(sub.id)")
            }
        case .nonConsumable:
            if let product = storeProducts.first(where: { $0.id == transaction.productID }),
               !purchasedProducts.contains(where: { $0.id == product.id }) {
                purchasedProducts.append(product)
                print("[Store] handleVerifiedTransaction — lifetime: \(product.id)")
            }
        default:
            break
        }
    }

    // Called from subscriptionStatusTask — uses status objects StoreKit already has,
    // avoiding the currentEntitlements timing gap right after a purchase.
    @MainActor
    func updateSubscriptionStatus(statuses: [Product.SubscriptionInfo.Status]) async {
        let active = statuses.filter { $0.state == .subscribed || $0.state == .inGracePeriod }

        if active.isEmpty {
            await updateCustomerProductStatus()
            return
        }

        var matched: [Product] = []
        for status in active {
            if case .verified(let tx) = status.transaction,
               let sub = subscriptions.first(where: { $0.id == tx.productID }) {
                matched.append(sub)
                print("[Store] updateSubscriptionStatus — matched: \(tx.productID)")
            }
        }

        if !matched.isEmpty {
            purchasedSubscriptions = matched
        } else {
            await updateCustomerProductStatus()
        }
    }

    @MainActor
    func requestProducts() async {
        do {
            storeProducts = try await Product.products(for: productLifetimeIds)
            subscriptions = try await Product.products(for: productIds)
        } catch {
            print("[Store] product request failed: \(error)")
        }
    }

    func purchase(_ product: Product) async throws -> Transaction? {
        let result = try await product.purchase()

        switch result {
        case .success(let verification):
            let transaction = try checkVerified(verification)
            await updateCustomerProductStatus()
            await transaction.finish()
            return transaction
        case .userCancelled, .pending:
            return nil
        default:
            return nil
        }
    }

    func isPurchased(_ product: Product) async throws -> Bool {
        return purchasedProducts.contains(product)
    }

    func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw StoreError.failedVerification
        case .verified(let safe):
            return safe
        }
    }

    @MainActor
    func updateCustomerProductStatus() async {
        var newSubscriptions: [Product] = []
        var newProducts: [Product] = []

        for await result in Transaction.currentEntitlements {
            do {
                let transaction = try checkVerified(result)

                switch transaction.productType {
                case .autoRenewable:
                    if let subscription = subscriptions.first(where: { $0.id == transaction.productID }) {
                        newSubscriptions.append(subscription)
                    }
                case .nonConsumable:
                    if let storeProduct = storeProducts.first(where: { $0.id == transaction.productID }) {
                        newProducts.append(storeProduct)
                    }
                default:
                    break
                }

                await transaction.finish()
            } catch {
                print("[Store] entitlement verification failed: \(error)")
            }
        }

        purchasedSubscriptions = newSubscriptions
        purchasedProducts = newProducts
    }
}

public enum StoreError: Error {
    case failedVerification
}
