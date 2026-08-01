//
//  DebtPayoffWidgetView.swift
//  ByJo
//

import SwiftData
import SwiftUI

private let debtAssetTypes: Set<AssetType> = [
    .mortgage, .creditCardDebt, .personalLoan, .studentLoan, .autoLoan
]

private struct DebtInfo: Identifiable {
    let id: UUID
    let name: String
    let currentBalance: Decimal
    let originalDebt: Decimal
    let monthlyPayment: Decimal
    let payoffDate: Date?
}

struct DebtPayoffWidgetView: View {
    @AppStorage("currencyCode") var currencyCode: CurrencyCode = .usd
    @AppStorage("compactNumber") var compactNumber: Bool = true

    @Query var assets: [Asset]

    private var debts: [DebtInfo] {
        assets
            .filter { debtAssetTypes.contains($0.type) }
            .compactMap { asset -> DebtInfo? in
                let balance = asset.calculateCurrentBalance()
                guard balance < 0 else { return nil }

                let ops = asset.operations ?? []
                let monthlyPayment = ops
                    .filter { $0.frequency != .single && $0.amount > 0 }
                    .reduce(Decimal(0)) { sum, op in
                        let monthly: Decimal
                        switch op.frequency {
                        case .single:  monthly = 0
                        case .daily:   monthly = op.amount * 30
                        case .weekly:  monthly = op.amount * 4
                        case .monthly: monthly = op.amount
                        case .yearly:  monthly = op.amount / 12
                        }
                        return sum + monthly
                    }

                let originalDebt = asset.initialBalance < 0 ? -asset.initialBalance : -balance

                let payoffDate: Date?
                if monthlyPayment > 0 {
                    let absBalance = -balance
                    let months = NSDecimalNumber(decimal: absBalance / monthlyPayment).intValue
                    payoffDate = Calendar.current.date(byAdding: .month, value: max(months, 0), to: Date())
                } else {
                    payoffDate = nil
                }

                return DebtInfo(
                    id: asset.id,
                    name: asset.name,
                    currentBalance: balance,
                    originalDebt: originalDebt,
                    monthlyPayment: monthlyPayment,
                    payoffDate: payoffDate
                )
            }
            .sorted { abs($0.currentBalance) > abs($1.currentBalance) }
    }

    var body: some View {
        if !debts.isEmpty {
            Section {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Debt Payoff")
                        .font(.headline)
                        .foregroundStyle(.secondary)

                    ForEach(debts) { debt in
                        let absBalance = -debt.currentBalance
                        let paidRatio: Double = {
                            let orig = NSDecimalNumber(decimal: debt.originalDebt).doubleValue
                            guard orig > 0 else { return 0 }
                            let paid = orig - NSDecimalNumber(decimal: absBalance).doubleValue
                            return max(0, min(paid / orig, 1.0))
                        }()

                        VStack(alignment: .leading, spacing: 6) {
                            HStack(alignment: .firstTextBaseline) {
                                Text(debt.name)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                Spacer()
                                Text(debt.currentBalance, format: compactNumber
                                     ? .currency(code: currencyCode.rawValue).notation(.compactName)
                                     : .currency(code: currencyCode.rawValue))
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(.red)
                            }

                            if debt.originalDebt > 0 {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color.secondary.opacity(0.12))
                                    .frame(height: 7)
                                    .overlay(alignment: .leading) {
                                        GeometryReader { geo in
                                            RoundedRectangle(cornerRadius: 4)
                                                .fill(Color.accentColor)
                                                .frame(width: geo.size.width * paidRatio)
                                        }
                                    }
                            }

                            HStack {
                                if debt.monthlyPayment > 0 {
                                    Label(
                                        debt.monthlyPayment.formatted(
                                            .currency(code: currencyCode.rawValue)
                                        ) + " / mo",
                                        systemImage: "calendar"
                                    )
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                }
                                Spacer()
                                if let date = debt.payoffDate {
                                    Text("Paid off \(date, format: .dateTime.month(.abbreviated).year())")
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                } else {
                                    Text("No recurring payments")
                                        .font(.caption2)
                                        .foregroundStyle(.tertiary)
                                }
                            }
                        }
                    }
                }
                .padding(.vertical, 8)
            }
        }
    }
}

#Preview {
    DebtPayoffWidgetView()
}
