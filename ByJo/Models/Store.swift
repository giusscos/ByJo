//
//  Store.swift
//  TomaTask
//
//  Created by Giuseppe Cosenza on 31/10/24.
//

import Foundation
import StoreKit

//alias
typealias RenewalInfo = StoreKit.Product.SubscriptionInfo.RenewalInfo // The Product.SubscriptionInfo.RenewalInfo provides information about the next subscription renewal period.
typealias RenewalState = StoreKit.Product.SubscriptionInfo.RenewalState // the renewal states of auto-renewable subscriptions.

@Observable
final class Store {
    private var subscriptions: [Product] = []
    var purchasedSubscriptions: [Product] = []
    private var subscriptionGroupStatus: RenewalState?
    var isLoading: Bool = true
    
//    let productIds: [String] = ["bj_499_1m_3d", "bj_4999_1y_1w", "bj_1499_1m_3d_fa", "bj_9999_1y_1w_fa"] // test
//    let groupId: String = "0C83600A" // test
//    
//    let productLifetimeIds: [String] = ["com.giusscos.byjoFamilyLifetime", "com.giusscos.byjoLifetime"] // test
    
        let productIds: [String] = ["bjpro_999_1m_fa", "bjpro_9999_1y_fa", "bjpro_399_1m", "bjpro_3999_1y"]
        let groupId: String = "21742027"
    
        let productLifetimeIds: [String] = ["com.giusscos.byjoFamilyLifetime", "com.giusscos.byjoLifetime"]
    
    // if there are multiple product types - create multiple variable for each .consumable, .nonconsumable, .autoRenewable, .nonRenewable.
    private var storeProducts: [Product] = []
    var purchasedProducts: [Product] = []
    
    var updateListenerTask : Task<Void, Error>? = nil
    
    init() {
        // start a transaction listern as close to app launch as possible so you don't miss a transaction
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
            // Iterate through any transactions that don't come from a direct call to `purchase()`.
            for await result in Transaction.updates {
                do {
                    let transaction = try self.checkVerified(result)
                    // deliver products to the user
                    await self.updateCustomerProductStatus()
                    
                    await transaction.finish()
                } catch {
                    print("transaction failed verification")
                }
            }
        }
    }
    
    // Request the products
    @MainActor
    func requestProducts() async {
        do {
            storeProducts = try await Product.products(for: productLifetimeIds)
            
            // request from the app store using the product ids (hardcoded)
            subscriptions = try await Product.products(for: productIds)
        } catch {
            print("Failed product request from app store server: \(error)")
        }
    }
    
    // purchase the product
    func purchase(_ product: Product) async throws -> Transaction? {
        let result = try await product.purchase()
        
        switch result {
            case .success(let verification):
                // Check whether the transaction is verified. If it isn't,
                // this function rethrows the verification error.
                let transaction = try checkVerified(verification)
                
                // The transaction is verified. Deliver content to the user.
                await updateCustomerProductStatus()
                
                // Always finish a transaction.
                await transaction.finish()
                
                return transaction
            case .userCancelled, .pending:
                return nil
            default:
                return nil
        }
    }
    
    //check if product has already been purchased
    func isPurchased(_ product: Product) async throws -> Bool {
        // as we only have one product type grouping .nonconsumable - we check if it belongs to the purchasedCourses which ran init()
        return purchasedProducts.contains(product)
    }
    
    func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        // Check whether the JWS passes StoreKit verification.
        switch result {
            case .unverified:
                // StoreKit parses the JWS, but it fails verification.
                throw StoreError.failedVerification
            case .verified(let safe):
                // The result is verified. Return the unwrapped value.
                return safe
        }
    }
    
    @MainActor
    func updateCustomerProductStatus() async {
        for await result in Transaction.currentEntitlements {
            do {
                // Check whether the transaction is verified. If it isn't, catch `failedVerification` error.
                let transaction = try checkVerified(result)
                
                switch transaction.productType {
                    case .autoRenewable:
                        if let subscription = subscriptions.first(where: {$0.id == transaction.productID}) {
                            purchasedSubscriptions.append(subscription)
                        }
                    case .nonConsumable:
                        if let storeProduct = storeProducts.first(where: {$0.id == transaction.productID}) {
                            purchasedProducts.append(storeProduct)
                        }
                    default:
                        break
                }
                
                // Always finish a transaction.
                await transaction.finish()
            } catch {
                print("failed updating products")
            }
        }
    }
}

public enum StoreError: Error {
    case failedVerification
}
