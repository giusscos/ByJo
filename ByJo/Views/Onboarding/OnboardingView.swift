//
//  OnboardingView.swift
//  ByJo
//
//  Created by Giuseppe Cosenza on 30/06/26.
//

import SwiftUI

// MARK: - Navigation Step

private enum OnboardingStep: Hashable {
    case whySave
    case whyInvest
    case currency
    case createAsset
    case createCategory
    case addTransaction
    case addRecurring
}

// MARK: - Root Container

struct OnboardingView: View {
    @AppStorage("currencyCode") var currencyCode: CurrencyCode = .usd
    var onComplete: () -> Void

    @State private var path: [OnboardingStep] = []
    @State private var assetName = ""
    @State private var assetType: AssetType = .bankAccount
    @State private var assetBalance: Decimal? = nil
    @State private var assetStatusBalance: StatusBalance = .positive
    @State private var categoryName = "General"
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
                path.append(.createCategory)
            }
        case .createCategory:
            OnboardingCategoryStep(name: $categoryName) {
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
                onContinue: {
                    savePending()
                    onComplete()
                },
                onSkip: {
                    savePending()
                    onComplete()
                }
            )
        }
    }

    // MARK: - Pending Save

    private func savePending() {
        let trimmedCategory = categoryName.trimmingCharacters(in: .whitespaces)
        PendingOnboardingData(
            assetName: assetName,
            assetType: assetType.rawValue,
            assetBalance: assetBalance.map { "\($0)" } ?? "",
            assetNegativeBalance: assetStatusBalance == .negative,
            categoryName: trimmedCategory.isEmpty ? "General" : trimmedCategory,
            operationName: operationName,
            operationAmount: operationAmount.map { "\($0)" } ?? "",
            operationIsExpense: operationType == .expense,
            recurringName: recurringName,
            recurringAmount: recurringAmount.map { "\($0)" } ?? "",
            recurringIsExpense: recurringOperationType == .expense,
            recurringFrequency: recurringFrequency.rawValue
        ).save()
    }
}

#Preview {
    OnboardingView(onComplete: {})
}
