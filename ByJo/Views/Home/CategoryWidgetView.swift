//
//  CategoryWidgetView.swift
//  ByJo
//
//  Created by Giuseppe Cosenza on 10/08/25.
//

import SwiftData
import SwiftUI

struct CategoryWithAmount {
    var category: CategoryOperation
    var amount: Decimal
}

private struct Accumulator {
    var maxProfit: CategoryWithAmount?
    var maxExpense: CategoryWithAmount?
}

struct CategoryWidgetView: View {
    @AppStorage("currencyCode") var currencyCode: CurrencyCode = .usd
    @AppStorage("compactNumber") var compactNumber: Bool = true
    
    @Query(sort: \CategoryOperation.name, order: .reverse) var categories: [CategoryOperation]
    
    private var mostRelevantCategory: CategoryWithAmount? {
        if categories.isEmpty { return nil }
        
        let calendar = Calendar.current
        let now = Date()
        let currentMonth = calendar.component(.month, from: now)
        let currentYear = calendar.component(.year, from: now)
        
        return categories
            .filter { category in
                let ops = category.assetOperations ?? []
                return !ops.isEmpty && ops.contains { operation in
                    let date = operation.date
                    return calendar.component(.month, from: date) == currentMonth &&
                           calendar.component(.year, from: date) == currentYear
                }
            }
            .map { category in
                let total = (category.assetOperations ?? [])
                    .filter { operation in
                        let date = operation.date
                        
                        return calendar.component(.month, from: date) == currentMonth &&
                        calendar.component(.year, from: date) == currentYear
                    }
                    .reduce(Decimal(0)) { $0 + $1.amount }
                
                return CategoryWithAmount(category: category, amount: total)
            }
            .max(by: { abs($0.amount) < abs($1.amount) })
    }

    private var topCategoryMonthlyExpenses: Decimal {
        guard let topCategory = mostRelevantCategory else { return 0 }
        let calendar = Calendar.current
        let now = Date()
        let currentMonth = calendar.component(.month, from: now)
        let currentYear = calendar.component(.year, from: now)
        return (topCategory.category.assetOperations ?? [])
            .filter { op in
                let d = op.date
                return calendar.component(.month, from: d) == currentMonth &&
                       calendar.component(.year, from: d) == currentYear &&
                       op.amount < 0
            }
            .reduce(Decimal(0)) { $0 + abs($1.amount) }
    }

    private var topCategoryBudget: Decimal {
        mostRelevantCategory?.category.monthlyBudget ?? 0
    }

    private var topCategoryBudgetRatio: Double {
        guard topCategoryBudget > 0 else { return 0 }
        return min(NSDecimalNumber(decimal: topCategoryMonthlyExpenses / topCategoryBudget).doubleValue, 1.0)
    }

    var body: some View {
        Section {
            if let topCategory = mostRelevantCategory {
                VStack(alignment: .leading, spacing: 24) {
                    NavigationLink {
                        OperationsGroupedByCategoryListView()
                    } label: {
                        Text("Category")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                    }
                    
                    VStack (alignment: .leading) {
                        Text(topCategory.category.name)
                            .font(.title3)
                            .fontWeight(.semibold)
                            .lineLimit(1)
                        
                        HStack(spacing: 4) {
                            Group {
                                if topCategory.amount > 0 {
                                    Image(systemName: "arrow.up.circle.fill")
                                        .foregroundStyle(.green)
                                } else if topCategory.amount == 0 {
                                    Image(systemName: "equal.circle.fill")
                                        .foregroundStyle(.gray)
                                } else {
                                    Image(systemName: "arrow.down.circle.fill")
                                        .foregroundStyle(.red)
                                }
                            }
                            .imageScale(.large)
                            .fontWeight(.semibold)

                            Text(topCategory.amount, format: compactNumber ? .currency(code: currencyCode.rawValue).notation(.compactName) : .currency(code: currencyCode.rawValue))
                                .font(.title)
                                .fontWeight(.semibold)
                                .contentTransition(.numericText(value: compactNumber ? 0 : 1))
                        }
                    }

                    if topCategory.category.monthlyBudget > 0 {
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text("Budget")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Spacer()
                                HStack(spacing: 2) {
                                    Text(topCategoryMonthlyExpenses, format: compactNumber ? .currency(code: currencyCode.rawValue).notation(.compactName) : .currency(code: currencyCode.rawValue))
                                        .font(.caption.weight(.semibold))
                                        .foregroundStyle(topCategoryMonthlyExpenses > topCategoryBudget ? Color.red : Color.primary)
                                        .contentTransition(.numericText(value: compactNumber ? 0 : 1))
                                    Text("/")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    Text(topCategoryBudget, format: compactNumber ? .currency(code: currencyCode.rawValue).notation(.compactName) : .currency(code: currencyCode.rawValue))
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                        .contentTransition(.numericText(value: compactNumber ? 0 : 1))
                                }
                            }

                            GeometryReader { geo in
                                ZStack(alignment: .leading) {
                                    Capsule().fill(Color.secondary.opacity(0.2))
                                    Capsule()
                                        .fill(topCategoryMonthlyExpenses > topCategoryBudget ? Color.red : Color.accentColor)
                                        .frame(width: geo.size.width * topCategoryBudgetRatio)
                                }
                            }
                            .frame(height: 4)
                            .animation(.spring(duration: 0.6), value: topCategoryBudgetRatio)
                        }
                    }
                }
            }
        }
    }
}

#Preview {
    CategoryWidgetView()
}
