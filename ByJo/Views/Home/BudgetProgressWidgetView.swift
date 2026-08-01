//
//  BudgetProgressWidgetView.swift
//  ByJo
//

import SwiftData
import SwiftUI

struct BudgetProgressWidgetView: View {
    @AppStorage("currencyCode") var currencyCode: CurrencyCode = .usd
    @AppStorage("compactNumber") var compactNumber: Bool = true

    @Query var categories: [CategoryOperation]

    private var budgetRows: [(category: CategoryOperation, spent: Decimal, budget: Decimal)] {
        let (start, end) = DateRangeOption.month.dateRange
        return categories
            .compactMap { cat -> (CategoryOperation, Decimal, Decimal)? in
                guard cat.monthlyBudget > 0 else { return nil }
                let spent = (cat.assetOperations ?? [])
                    .filter { $0.date >= start && $0.date <= end && $0.amount < 0 }
                    .reduce(Decimal(0)) { $0 + (-$1.amount) }
                return (cat, spent, cat.monthlyBudget)
            }
            .sorted { lhs, rhs in
                let l = NSDecimalNumber(decimal: lhs.1).doubleValue / NSDecimalNumber(decimal: lhs.2).doubleValue
                let r = NSDecimalNumber(decimal: rhs.1).doubleValue / NSDecimalNumber(decimal: rhs.2).doubleValue
                return l > r
            }
    }

    var body: some View {
        if !budgetRows.isEmpty {
            Section {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Budget Progress")
                        .font(.headline)
                        .foregroundStyle(.secondary)

                    ForEach(budgetRows, id: \.category.id) { row in
                        let ratio = min(
                            NSDecimalNumber(decimal: row.spent).doubleValue /
                            NSDecimalNumber(decimal: row.budget).doubleValue,
                            1.0
                        )
                        let isOver = row.spent >= row.budget
                        let barColor: Color = isOver ? .red : (ratio > 0.8 ? .orange : .accentColor)

                        VStack(alignment: .leading, spacing: 6) {
                            HStack(alignment: .firstTextBaseline) {
                                Text(row.category.name)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                Spacer()
                                VStack(alignment: .trailing, spacing: 1) {
                                    Text(row.spent, format: compactNumber
                                         ? .currency(code: currencyCode.rawValue).notation(.compactName)
                                         : .currency(code: currencyCode.rawValue))
                                        .font(.caption)
                                        .fontWeight(.semibold)
                                        .foregroundStyle(isOver ? .red : .primary)
                                    Text("of \(row.budget, format: compactNumber ? .currency(code: currencyCode.rawValue).notation(.compactName) : .currency(code: currencyCode.rawValue))")
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }
                            }

                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.secondary.opacity(0.12))
                                .frame(height: 7)
                                .overlay(alignment: .leading) {
                                    GeometryReader { geo in
                                        RoundedRectangle(cornerRadius: 4)
                                            .fill(barColor)
                                            .frame(width: geo.size.width * ratio)
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
    BudgetProgressWidgetView()
}
