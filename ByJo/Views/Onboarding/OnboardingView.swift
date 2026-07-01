//
//  OnboardingView.swift
//  ByJo
//
//  Created by Giuseppe Cosenza on 30/06/26.
//

import SwiftUI
import SwiftData
import UserNotifications

// MARK: - Navigation Step

private enum OnboardingStep: Hashable {
    case whySave
    case whyInvest
    case currency
    case createAsset
    case addTransaction
    case addRecurring
}

// MARK: - Root Container

struct OnboardingView: View {
    @Environment(\.modelContext) var modelContext
    @AppStorage("currencyCode") var currencyCode: CurrencyCode = .usd
    var onComplete: () -> Void

    @State private var path: [OnboardingStep] = []
    @State private var assetName = ""
    @State private var assetType: AssetType = .bankAccount
    @State private var assetBalance: Decimal? = nil
    @State private var assetStatusBalance: StatusBalance = .positive
    @State private var savedAsset: Asset? = nil
    @State private var savedCategory: CategoryOperation? = nil
    @State private var operationName = ""
    @State private var operationAmount: Decimal? = nil
    @State private var operationType: OperationType = .income
    @State private var recurringName = ""
    @State private var recurringAmount: Decimal? = nil
    @State private var recurringOperationType: OperationType = .income
    @State private var recurringFrequency: RecurrenceFrequency = .monthly

    var body: some View {
        NavigationStack(path: $path) {
            OnboardingWelcomeStep { path.append(.whySave) }
                .toolbar(.hidden, for: .navigationBar)
                .navigationDestination(for: OnboardingStep.self) { step in
                    destinationView(for: step)
                }
        }
    }

    @ViewBuilder
    private func destinationView(for step: OnboardingStep) -> some View {
        switch step {
        case .whySave:
            OnboardingWhySaveStep { path.append(.whyInvest) }
        case .whyInvest:
            OnboardingWhyInvestStep { path.append(.currency) }
        case .currency:
            OnboardingCurrencyStep(currencyCode: $currencyCode) { path.append(.createAsset) }
        case .createAsset:
            OnboardingAssetStep(
                name: $assetName,
                type: $assetType,
                balance: $assetBalance,
                statusBalance: $assetStatusBalance,
                currencyCode: currencyCode
            ) {
                saveAsset()
                path.append(.addTransaction)
            }
        case .addTransaction:
            OnboardingTransactionStep(
                name: $operationName,
                amount: $operationAmount,
                operationType: $operationType,
                assetName: assetName,
                currencyCode: currencyCode,
                onContinue: {
                    if !operationName.isEmpty, operationAmount != nil { saveOperation() }
                    path.append(.addRecurring)
                },
                onSkip: { path.append(.addRecurring) }
            )
        case .addRecurring:
            OnboardingRecurringStep(
                name: $recurringName,
                amount: $recurringAmount,
                operationType: $recurringOperationType,
                frequency: $recurringFrequency,
                assetName: assetName,
                currencyCode: currencyCode,
                onContinue: {
                    if !recurringName.isEmpty, recurringAmount != nil { saveRecurringOperation() }
                    onComplete()
                },
                onSkip: { onComplete() }
            )
        }
    }

    // MARK: - Persistence

    private func saveAsset() {
        guard savedAsset == nil else { return }
        var balance = assetBalance ?? 0
        if assetStatusBalance == .negative, balance > 0 { balance *= -1 }
        let asset = Asset(name: assetName, type: assetType, initialBalance: balance)
        modelContext.insert(asset)
        savedAsset = asset
        let category = CategoryOperation(name: "General")
        modelContext.insert(category)
        savedCategory = category
    }

    private func saveOperation() {
        guard let asset = savedAsset, let category = savedCategory else { return }
        var amount = operationAmount ?? 0
        if operationType == .expense, amount > 0 { amount *= -1 }
        modelContext.insert(AssetOperation(
            name: operationName, date: .now, amount: amount, asset: asset, category: category
        ))
    }

    private func saveRecurringOperation() {
        guard let asset = savedAsset, let category = savedCategory,
              !recurringName.isEmpty, let rawAmount = recurringAmount else { return }
        var amount = rawAmount
        if recurringOperationType == .expense, amount > 0 { amount *= -1 }
        let uuid = UUID()
        modelContext.insert(AssetOperation(
            id: uuid, name: recurringName, date: .now, amount: amount,
            asset: asset, category: category, frequency: recurringFrequency
        ))
        scheduleRecurringNotification(uuid: uuid, amount: amount)
    }

    private func scheduleRecurringNotification(uuid: UUID, amount: Decimal) {
        guard recurringFrequency != .single,
              let nextDate = recurringFrequency.nextPaymentDate(from: .now) else { return }
        let content = UNMutableNotificationContent()
        content.title = "Recurring operation"
        content.subtitle = "\(recurringName) \(amount.formatted(.currency(code: currencyCode.rawValue)))"
        content.badge = 1
        let triggerDate = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: nextDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: false)
        UNUserNotificationCenter.current().add(
            UNNotificationRequest(identifier: uuid.uuidString, content: content, trigger: trigger)
        )
    }
}

#Preview {
    OnboardingView(onComplete: {})
        .modelContainer(for: Asset.self, inMemory: true)
}
