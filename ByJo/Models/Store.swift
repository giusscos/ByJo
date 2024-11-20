//
//  Store.swift
//  TomaTask
//
//  Created by Giuseppe Cosenza on 31/10/24.
//

//import Foundation
//import StoreKit
//import SwiftUI
//
//@Observable
//class Store {
//    let productIdentifiers: [String] = ["bj_4999_1y_v1", "bj_499_1m"]
//    let groupId: String = "21584181"
//    var products: [Product] = []
//    var transactionId: UInt64 = 0
//    var unlockAccess: Bool = false
//    
//    init() {
//        Task {
//            await observeTransactions()
//        }
//    }
//    
//    private func observeTransactions() async {
//        for await result in Transaction.updates {
//            await handle(transactionResult: result)
//        }
//    }
//    
//    private func handle(transactionResult: VerificationResult<StoreKit.Transaction>) async {
//            do {
//                let transaction = try checkVerified(transactionResult)
//                
//                await processTransaction(transaction)
//                
//                
//                await transaction.finish()
//            } catch {
//                
//                print("Errore nella verifica della transazione: \(error)")
//        }
//    }
//    
//    private func checkVerified(_ result: VerificationResult<StoreKit.Transaction>) throws -> StoreKit.Transaction {
//        
//        switch result {
//            case .unverified:
//                throw StoreKitError.notEntitled
//            case .verified(let transaction):
//                return transaction
//        }
//    }
//    
//    private func processTransaction(_ transaction: StoreKit.Transaction) async {
//        print("Transazione completata con successo: \(transaction)")
//    }
//        
//    func fetchAvailableProducts() async throws {
//        let productsResult = try await Product.products(for: productIdentifiers)
//        
//        products = productsResult
//        
//        for product in products {
//            await isPurchased(product: product)
//        }
//    }
//    
//    func isPurchased(product: Product?) async {
//        guard let product = product else {
////            print("Error product")
//            return
//        }
//        guard let verificationResult = await product.currentEntitlement else {
////            print("No entitlement found for product: \(product)")
//            return
//        }
//        
//        switch verificationResult {
////        case .verified(let transaction):
//        case .verified(let transaction):
//            // Check the transaction and give the user access to purchased
//            // content as appropriate.
//            self.unlockAccess = true
//            self.transactionId = transaction.id
//            break
////        case .unverified(let transaction, let verificationError):
//        case .unverified(_, _):
//            // Handle unverified transactions based
//            // on your business model.
//            self.unlockAccess = false
//            break
//        }
//    }
//    
//    func handlePurchase(purchase: PurchaseAction, product: Product) {
//        Task {
//            let result = try? await purchase(product)
//            
//            switch result {
//            case .success(let verificationResult):
//                switch verificationResult {
//                case .verified(let transaction):
//                    // Give the user access to purchased content.
//                    // Complete the transaction after providing
//                    // the user access to the content.
//                    await transaction.finish()
//                    self.unlockAccess = true
//                    break
//                case .unverified(_, _):
//                    // Handle unverified transactions based
//                    // on your business model.
//                    break
//                }
//            case .pending:
//                // The purchase requires action from the customer.
//                // If the transaction completes,
//                // it's available through Transaction.updates.
//                break
//            case .userCancelled:
//                // The user canceled the purchase.
//                break
//            case .none:
//                break
//            @unknown default:
//                break
//            }
//        }
//    }
//}

import Foundation
import StoreKit

//alias
typealias RenewalInfo = StoreKit.Product.SubscriptionInfo.RenewalInfo //The Product.SubscriptionInfo.RenewalInfo provides information about the next subscription renewal period.
typealias RenewalState = StoreKit.Product.SubscriptionInfo.RenewalState // the renewal states of auto-renewable subscriptions.

@Observable
class Store {
    private var subscriptions: [Product] = []
    var purchasedSubscriptions: [Product] = []
    private var subscriptionGroupStatus: RenewalState?
    
    private let productIds: [String] = ["bj_4999_1y_v1", "bj_499_1m"]
//    private let productIds: [String] = ["bj_499_1m"] // test
    let groupId: String = "21584181"
//    let groupId: String = "0C83600A" // test
    
    var updateListenerTask : Task<Void, Error>? = nil
    
    init() {
        //start a transaction listern as close to app launch as possible so you don't miss a transaction
        updateListenerTask = listenForTransactions()
        
        Task {
            await requestProducts()
            
            await updateCustomerProductStatus()
        }
    }
    
    deinit {
        updateListenerTask?.cancel()
    }
    
    func listenForTransactions() -> Task<Void, Error> {
        return Task.detached {
            //Iterate through any transactions that don't come from a direct call to `purchase()`.
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
            // request from the app store using the product ids (hardcoded)
            subscriptions = try await Product.products(for: productIds)
            print(subscriptions)
        } catch {
            print("Failed product request from app store server: \(error)")
        }
    }
    
    // purchase the product
    func purchase(_ product: Product) async throws -> Transaction? {
        let result = try await product.purchase()
        
        switch result {
        case .success(let verification):
            //Check whether the transaction is verified. If it isn't,
            //this function rethrows the verification error.
            let transaction = try checkVerified(verification)
            
            //The transaction is verified. Deliver content to the user.
            await updateCustomerProductStatus()
            
            //Always finish a transaction.
            await transaction.finish()
            
            return transaction
        case .userCancelled, .pending:
            return nil
        default:
            return nil
        }
    }
    
    func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        //Check whether the JWS passes StoreKit verification.
        switch result {
        case .unverified:
            //StoreKit parses the JWS, but it fails verification.
            throw StoreError.failedVerification
        case .verified(let safe):
            //The result is verified. Return the unwrapped value.
            return safe
        }
    }
    
    @MainActor
    func updateCustomerProductStatus() async {
        for await result in Transaction.currentEntitlements {
            do {
                //Check whether the transaction is verified. If it isn’t, catch `failedVerification` error.
                let transaction = try checkVerified(result)
                
                switch transaction.productType {
                case .autoRenewable:
                    if let subscription = subscriptions.first(where: {$0.id == transaction.productID}) {
                        purchasedSubscriptions.append(subscription)
                    }
                default:
                    break
                }
                //Always finish a transaction.
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
