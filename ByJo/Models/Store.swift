//
//  Store.swift
//  ByJo
//
//  Created by Giuseppe Cosenza on 31/10/24.
//

import Foundation
import StoreKit
import UserNotifications
import WidgetKit

typealias RenewalInfo = StoreKit.Product.SubscriptionInfo.RenewalInfo
typealias RenewalState = StoreKit.Product.SubscriptionInfo.RenewalState

@Observable
final class Store {
    /// The free plan covers this many assets. Pro removes the cap, and adds goals,
    /// recurring operations, Home Screen widgets and import/export.
    static let freeAssetLimit = 3

    private var subscriptions: [Product] = []
    var purchasedSubscriptions: [Product] = []
    var isLoading: Bool = true
    /// Days of the yearly plan's free trial the user can still redeem, or nil.
    private(set) var yearlyTrialDays: Int?

    let productIds: [String] = ["bjpro_999_1m_fa", "bjpro_9999_1y_fa", "bjpro_399_1m", "bjpro_3999_1y", "byjo_399_1w"]
    let groupId: String = "21584181"
    /// Plans offered on the paywall. `productIds` stays broader so subscribers on
    /// retired plans (monthly, family) keep their entitlement.
    /// The yearly plan carries the free trial and is pre-selected.
    let yearlyProductId: String = "bjpro_3999_1y"
    let weeklyProductId: String = "byjo_399_1w"
    let productLifetimeIds: [String] = ["com.giusscos.byjoFamilyLifetime", "com.giusscos.byjoLifetime"]
    /// Lifetime purchase offered on the paywall. Family lifetime is retired but stays in
    /// `productLifetimeIds` so existing owners keep their entitlement.
    let lifetimeProductId: String = "com.giusscos.byjoLifetime"

    private var storeProducts: [Product] = []
    var purchasedProducts: [Product] = []

    var updateListenerTask: Task<Void, Error>? = nil

    /// Lets screenshot runs launched outside Xcode (no StoreKit config) show Pro screens.
    private let bypassPaywall: Bool = {
        #if DEBUG
        return ProcessInfo.processInfo.arguments.contains("-bypassPaywall")
        #else
        return false
        #endif
    }()

    var isPro: Bool {
        bypassPaywall || !purchasedSubscriptions.isEmpty || !purchasedProducts.isEmpty
    }

    /// Whether Pro features open. True while StoreKit is still loading, so subscribers
    /// never hit a lock in the first moments after launch.
    var unlocksPro: Bool { isPro || isLoading }

    var yearlyProduct: Product? { subscriptions.first { $0.id == yearlyProductId } }
    var weeklyProduct: Product? { subscriptions.first { $0.id == weeklyProductId } }
    var lifetimeProduct: Product? { storeProducts.first { $0.id == lifetimeProductId } }

    init() {
        updateListenerTask = listenForTransactions()

        Task { @MainActor in
            await requestProducts()
            await updateCustomerProductStatus()
            await refreshTrialEligibility()
            isLoading = false
        }
        // If StoreKit never answers (no network, or a Simulator run without a StoreKit
        // configuration), stop treating the app as loading so the free plan's limits apply.
        // Entitlements that arrive later still unlock Pro.
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(6))
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
        guard transaction.revocationDate == nil else { return }
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
        saveProAccess()
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
                scheduleTrialEndingReminder(for: tx)
                print("[Store] updateSubscriptionStatus — matched: \(tx.productID)")
            }
        }

        if !matched.isEmpty {
            purchasedSubscriptions = matched
            saveProAccess()
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

    /// Length in days of the yearly plan's free trial when the user can still redeem it,
    /// or nil when the plan has no trial or the user already used one in the group.
    func eligibleTrialDays() async -> Int? {
        if subscriptions.isEmpty { await requestProducts() }
        guard let offer = subscriptions.first(where: { $0.id == yearlyProductId })?
            .subscription?.introductoryOffer,
              offer.paymentMode == .freeTrial else { return nil }
        guard await Product.SubscriptionInfo.isEligibleForIntroOffer(for: groupId) else { return nil }

        let unitDays: Int
        switch offer.period.unit {
        case .day: unitDays = 1
        case .week: unitDays = 7
        case .month: unitDays = 30
        case .year: unitDays = 365
        @unknown default: unitDays = 1
        }
        return offer.period.value * unitDays
    }

    @MainActor
    func refreshTrialEligibility() async {
        yearlyTrialDays = await eligibleTrialDays()
    }

    /// Notifies the user one day before a free trial converts to a paid plan.
    /// Uses a fixed identifier so repeated status updates replace the same request.
    private func scheduleTrialEndingReminder(for transaction: Transaction) {
        let identifier = "trial-ending-reminder"
        let center = UNUserNotificationCenter.current()

        guard transaction.offer?.type == .introductory,
              let expiration = transaction.expirationDate,
              let fireDate = Calendar.current.date(byAdding: .day, value: -1, to: expiration),
              fireDate > .now else {
            center.removePendingNotificationRequests(withIdentifiers: [identifier])
            return
        }

        let content = UNMutableNotificationContent()
        content.title = String(localized: "Your ByJo trial ends tomorrow")
        content.body = String(localized: "Keep your net worth in view, or cancel anytime in Settings before it renews.")
        content.sound = .default

        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: fireDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

        // Ask for full permission, not provisional: the paywall promised this reminder,
        // and a provisional grant would only deliver it quietly to Notification Center.
        // The system shows the prompt once, right after the trial starts; users who
        // already answered (e.g. when scheduling a recurring operation) aren't asked again.
        center.requestAuthorization(options: [.alert, .sound]) { _, _ in
            center.add(request)
        }
    }

    /// Buys a product. Pass `@Environment(\.purchase)` as `perform` so StoreKit can
    /// present its sheet in the right scene.
    @MainActor
    func purchase(
        _ product: Product,
        perform: (Product) async throws -> Product.PurchaseResult
    ) async throws {
        let result = try await perform(product)
        switch result {
        case .success(let verification):
            let transaction = try checkVerified(verification)
            handleVerifiedTransaction(transaction)
            await transaction.finish()
            await refreshTrialEligibility()
        case .pending, .userCancelled:
            // Ask to Buy and similar: the entitlement arrives later through Transaction.updates.
            break
        @unknown default:
            break
        }
    }

    @MainActor
    func restorePurchases() async {
        try? await AppStore.sync()
        await updateCustomerProductStatus()
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
        saveProAccess()
    }

    /// Shares the Pro state with the widgets and Siri intents, and redraws the widgets
    /// when it changes so they lock or unlock right away.
    @MainActor
    private func saveProAccess() {
        if ProAccess.save(isPro) {
            WidgetCenter.shared.reloadAllTimelines()
        }
    }
}

public enum StoreError: Error {
    case failedVerification
}
