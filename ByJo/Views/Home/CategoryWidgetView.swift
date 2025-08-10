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
    @Query(sort: \CategoryOperation.name, order: .reverse) var categories: [CategoryOperation]
    
    private var mostRelevantCategory: CategoryWithAmount? {
        categories
            .map { category in
                let total = category.assetOperations?.reduce(Decimal(0)) { $0 + $1.amount } ?? 0
                return CategoryWithAmount(category: category, amount: total)
            }
            .max(by: { abs($0.amount) < abs($1.amount) })
    }
    
    var body: some View {
        Section {
            if let topCategory = mostRelevantCategory {
                VStack(alignment: .leading, spacing: 24) {
                    NavigationLink {
                        
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
                                    Image(systemName: "arrow.up.circle.fill").foregroundStyle(.green)
                                } else if topCategory.amount == 0 {
                                    Image(systemName: "equal.circle.fill").foregroundStyle(.gray)
                                } else {
                                    Image(systemName: "arrow.down.circle.fill").foregroundStyle(.red)
                                }
                            }
                            .imageScale(.large)
                            .fontWeight(.semibold)
                            
                            Text(topCategory.amount, format: .currency(code: CurrencyCode.usd.rawValue))
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
