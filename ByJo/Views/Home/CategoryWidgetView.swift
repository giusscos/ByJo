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

    @Query(sort: \CategoryOperation.name, order: .reverse) var categories: [CategoryOperation]
    
    private var mostRelevantCategory: CategoryWithAmount? {
        if categories.isEmpty { return nil }
        
        let calendar = Calendar.current
        let now = Date()
        let currentMonth = calendar.component(.month, from: now)
        let currentYear = calendar.component(.year, from: now)
        
        return categories
            .filter { category in
                if let assetOperations = category.assetOperations, !assetOperations.isEmpty {
                    return assetOperations.contains { operation in
                        let date = operation.date
                        
                        return calendar.component(.month, from: date) == currentMonth &&
                        calendar.component(.year, from: date) == currentYear
                    }
                }
                return false
            }
            .map { category in
                guard let assetOperations = category.assetOperations else {
                    return CategoryWithAmount(category: CategoryOperation(name: "No category"), amount: 0.0)
                }
                
                let total = assetOperations
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
                            
                            Text(topCategory.amount, format: .currency(code: currencyCode.rawValue))
                                .font(.title)
                                .fontWeight(.semibold)
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
