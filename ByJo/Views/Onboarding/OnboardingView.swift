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
    case success
}

// MARK: - Root Container

struct OnboardingView: View {
    @Environment(\.modelContext) private var modelContext
    @AppStorage("currencyCode") var currencyCode: CurrencyCode = .usd
    var onComplete: () -> Void

    @State private var path: [OnboardingStep] = []
    @State private var assetName = ""
    @State private var assetType: AssetType = .bankAccount
    @State private var assetBalance: Decimal? = nil
    @State private var assetStatusBalance: StatusBalance = .positive
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
                path.append(.addTransaction)
            }
        case .addTransaction:
            OnboardingTransactionStep(
                name: $operationName,
                amount: $operationAmount,
                operationType: $operationType,
                assetName: assetName,
                currencyCode: currencyCode,
                onContinue: { path.append(.addRecurring) },
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
                onContinue: { commitToSwiftData() },
                onSkip: { commitToSwiftData() }
            )
        case .success:
            OnboardingSuccessStep(onComplete: onComplete)
        }
    }

    // MARK: - SwiftData Commit

    private func commitToSwiftData() {
        let finalBalance: Decimal = {
            guard let b = assetBalance else { return 0 }
            return assetStatusBalance == .negative ? (b > 0 ? b * -1 : b) : abs(b)
        }()

        // Reuse existing asset with same name to prevent duplicates on re-entry
        let assetDescriptor = FetchDescriptor<Asset>(
            predicate: #Predicate { $0.name == assetName }
        )
        let asset: Asset
        if let existing = (try? modelContext.fetch(assetDescriptor))?.first {
            asset = existing
        } else {
            let newAsset = Asset(name: assetName, type: assetType, initialBalance: finalBalance)
            modelContext.insert(newAsset)
            asset = newAsset
        }

        // Reuse existing "General" category or create it once
        let categoryDescriptor = FetchDescriptor<CategoryOperation>(
            predicate: #Predicate { $0.name == "General" }
        )
        let category: CategoryOperation
        if let existing = (try? modelContext.fetch(categoryDescriptor))?.first {
            category = existing
        } else {
            let newCategory = CategoryOperation(name: "General")
            modelContext.insert(newCategory)
            category = newCategory
        }

        // Only add the transaction if it doesn't already exist on this asset
        if !operationName.isEmpty, let rawAmount = operationAmount {
            let opAmount: Decimal = operationType == .expense
                ? (rawAmount > 0 ? rawAmount * -1 : rawAmount)
                : abs(rawAmount)
            let alreadyExists = (asset.operations ?? []).contains {
                $0.name == operationName && $0.frequency == .single
            }
            if !alreadyExists {
                modelContext.insert(AssetOperation(
                    name: operationName, date: .now, amount: opAmount,
                    asset: asset, category: category
                ))
            }
        }

        // Only add the recurring operation if it doesn't already exist on this asset
        if !recurringName.isEmpty, let rawAmount = recurringAmount {
            let recAmount: Decimal = recurringOperationType == .expense
                ? (rawAmount > 0 ? rawAmount * -1 : rawAmount)
                : abs(rawAmount)
            let alreadyExists = (asset.operations ?? []).contains {
                $0.name == recurringName && $0.frequency != .single
            }
            if !alreadyExists {
                let uuid = UUID()
                modelContext.insert(AssetOperation(
                    id: uuid, name: recurringName, date: .now, amount: recAmount,
                    asset: asset, category: category, frequency: recurringFrequency
                ))
                scheduleRecurringNotification(id: uuid, name: recurringName, amount: recAmount)
            }
        }

        path.append(.success)
    }

    private func scheduleRecurringNotification(id: UUID, name: String, amount: Decimal) {
        guard recurringFrequency != .single,
              let nextDate = recurringFrequency.nextPaymentDate(from: .now) else { return }
        let content = UNMutableNotificationContent()
        content.title = "Recurring operation"
        content.subtitle = "\(name) \(amount.formatted(.currency(code: currencyCode.rawValue)))"
        content.badge = 1
        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: nextDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        UNUserNotificationCenter.current().add(
            UNNotificationRequest(identifier: id.uuidString, content: content, trigger: trigger)
        )
    }
}

#Preview {
    OnboardingView(onComplete: {})
}
