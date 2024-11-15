//
//  CategoryChartDetailView.swift
//  ByJo
//
//  Created by Giuseppe Cosenza on 15/11/24.
//

import SwiftUI
import SwiftData
import Charts

struct CategoryChartDetailView: View {
    @State private var dateRange: DateRangeOption = .month
    
    @Query(sort: \AssetOperation.date, order: .reverse) var operations: [AssetOperation]
    
    @Query(sort: \CategoryOperation.name, order: .reverse) var categories: [CategoryOperation]

    var filteredData: [AssetOperation] {
        AssetOperation().filterData(for: dateRange, data: operations)
    }
    
    var categoryWithHighestBalance: (CategoryOperation, Decimal) { findCategoryWithHighestBalance(categories: categories)
    }
    
    var categoryWithLowestBalance: (CategoryOperation, Decimal) { findCategoryWithLowestBalance(categories: categories)
    }
    
    var body: some View {
        ScrollView {
            Text("Operations")
                .font(.largeTitle)
                .bold()
                .frame(maxWidth: .infinity, alignment: .topLeading)
            
            VStack (alignment: .leading, spacing: 0) {
                if let operation = operations.first(where: { $0.category == categoryWithHighestBalance.0 }) {
                    Text("Top category: ")
                    + Text(categoryWithHighestBalance.0.name)
                        .bold()
                    + Text(" with ")
                    + Text(categoryWithHighestBalance.1, format: .currency(code: operation.currency.rawValue))
                        .bold()
                }
                if let operation = operations.first(where: { $0.category == categoryWithLowestBalance.0 }) {
                    Text("Worse asset: ")
                    + Text(categoryWithLowestBalance.0.name)
                        .bold()
                    + Text(" with ")
                    + Text(categoryWithLowestBalance.1, format: .currency(code: operation.currency.rawValue))
                        .bold()
                }
            }
            .frame(maxWidth: .infinity, alignment: .topLeading)
            .font(.subheadline)
            .foregroundStyle(.secondary)
            
            Picker("Date Range", selection: $dateRange.animation()) {
                ForEach(DateRangeOption.allCases) { range in
                    Text(range.rawValue).tag(range)
                }
            }
            .pickerStyle(.segmented)
            
            Chart(filteredData) { value in
                if let category = value.category {
                    BarMark(
                        x: .value("Amount", value.amount),
                        y: .value("Category", category.name)
                    )
                    .foregroundStyle(by: .value("Category", category.name))
                    .cornerRadius(4)
                }
            }
            .aspectRatio(1, contentMode: .fit)
        }.padding()
    }
    
    func calculateCategoryBalance(category: CategoryOperation) -> Decimal {
        let operationsForCategory = filteredData.filter { $0.category?.id == category.id }
        
        let totalBalance = operationsForCategory.reduce(Decimal(0)) { $0 + $1.amount }
        
        return totalBalance
    }
    
    func findCategoryWithHighestBalance(categories: [CategoryOperation]) -> (CategoryOperation, Decimal) {
        let categoryBalances = categories.map { category in
            let balance = calculateCategoryBalance(category: category)
            return (category, balance)
        }
        
        let maxCategory = categoryBalances.max { $0.1 < $1.1 }
        
        return maxCategory ?? (CategoryOperation(name: ""), Decimal(0))
    }
    
    func findCategoryWithLowestBalance(categories: [CategoryOperation]) -> (CategoryOperation, Decimal) {
        let categoryBalances = categories.map { category in
            let balance = calculateCategoryBalance(category: category)
            return (category, balance)
        }
        
        let minCategory = categoryBalances.min { $0.1 < $1.1 }
        
        return minCategory ?? (CategoryOperation(name: ""), Decimal(0))
    }
}

#Preview {
    CategoryChartDetailView()
}
