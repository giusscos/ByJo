//
//  ContentView.swift
//  ByJo
//
//  Created by Giuseppe Cosenza on 04/11/24.
//

import SwiftUI
import SwiftData
import StoreKit
import UserNotifications

struct ContentView: View {
    enum ActiveSheet: Identifiable {
        case onboarding
        case paywall

        var id: String {
            switch self {
            case .onboarding: return "onboarding"
            case .paywall: return "paywall"
            }
        }
    }

    @Environment(\.modelContext) var modelContext
    @AppStorage("hasCompletedOnboarding") var hasCompletedOnboarding: Bool = false
    @AppStorage("currencyCode") var currencyCode: CurrencyCode = .usd

    @State var activeSheet: ActiveSheet?
    @State var store = Store()

    var hasPaid: Bool {
        !store.purchasedSubscriptions.isEmpty || !store.purchasedProducts.isEmpty
    }

    var body: some View {
        if store.isLoading {
            ProgressView()
        } else {
            TabView {
                Tab("Home", systemImage: "house.fill") {
                    HomeView()
                }

                Tab("Assets", systemImage: "briefcase.fill") {
                    AssetListView()
                }

                Tab("Operations", systemImage: "book.pages") {
                    OperationListView()
                }
            }
            .fullScreenCover(item: $activeSheet, content: { sheet in
                switch sheet {
                case .onboarding:
                    OnboardingView {
                        hasCompletedOnboarding = true
                        activeSheet = .paywall
                    }
                case .paywall:
                    PaywallView(store: store)
                }
            })
            .onChange(of: hasPaid) { _, paid in
                if paid { migrateOnboardingDataIfNeeded() }
                activeSheet = .none
            }
            .onAppear {
                UITextField.appearance().clearButtonMode = .whileEditing

                if hasPaid {
                    migrateOnboardingDataIfNeeded()
                    return
                }

                activeSheet = hasCompletedOnboarding ? .paywall : .onboarding
            }
        }
    }

    // MARK: - Onboarding Data Migration

    private func migrateOnboardingDataIfNeeded() {
        guard let pending = PendingOnboardingData.load(), !pending.assetName.isEmpty else { return }

        var balance = Decimal(string: pending.assetBalance) ?? 0
        if pending.assetNegativeBalance, balance > 0 { balance *= -1 }

        let assetType = AssetType(rawValue: pending.assetType) ?? .bankAccount
        let asset = Asset(name: pending.assetName, type: assetType, initialBalance: balance)
        modelContext.insert(asset)

        let category = CategoryOperation(name: pending.categoryName)
        modelContext.insert(category)

        if !pending.operationName.isEmpty, let opAmount = Decimal(string: pending.operationAmount) {
            var amount = opAmount
            if pending.operationIsExpense, amount > 0 { amount *= -1 }
            modelContext.insert(AssetOperation(
                name: pending.operationName, date: .now, amount: amount, asset: asset, category: category
            ))
        }

        if !pending.recurringName.isEmpty, let recAmount = Decimal(string: pending.recurringAmount) {
            let frequency = RecurrenceFrequency(rawValue: pending.recurringFrequency) ?? .monthly
            var amount = recAmount
            if pending.recurringIsExpense, amount > 0 { amount *= -1 }
            let uuid = UUID()
            modelContext.insert(AssetOperation(
                id: uuid, name: pending.recurringName, date: .now, amount: amount,
                asset: asset, category: category, frequency: frequency
            ))
            scheduleNotification(id: uuid, name: pending.recurringName, amount: amount, frequency: frequency)
        }

        PendingOnboardingData.clear()
    }

    private func scheduleNotification(id: UUID, name: String, amount: Decimal, frequency: RecurrenceFrequency) {
        guard frequency != .single, let nextDate = frequency.nextPaymentDate(from: .now) else { return }
        let content = UNMutableNotificationContent()
        content.title = "Recurring operation"
        content.subtitle = "\(name) \(amount.formatted(.currency(code: currencyCode.rawValue)))"
        content.badge = 1
        let triggerDate = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: nextDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: false)
        UNUserNotificationCenter.current().add(
            UNNotificationRequest(identifier: id.uuidString, content: content, trigger: trigger)
        )
    }
}

#Preview {
    ContentView()
}
