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
        filterData(for: dateRange, data: operations)
    }
    
    var categoryWithHighestBalance: (CategoryOperation, Decimal) {
        findCategoryWithHighestBalance(categories: categories)
    }
    
    var categoryWithLowestBalance: (CategoryOperation, Decimal) {
        findCategoryWithLowestBalance(categories: categories)
    }
    
    var body: some View {
        ScrollView {
            Text("Categories")
                .font(.largeTitle)
                .bold()
                .frame(maxWidth: .infinity, alignment: .topLeading)
            
            if operations.isEmpty {
                ContentUnavailableView(
                    "No Operations Found",
                    systemImage: "exclamationmark",
                    description: Text("You need to add an operation by selecting the Operations tab and tapping the plus button on the top right corner")
                )
            } else {
                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        if let operation = operations.first(where: { $0.category == categoryWithHighestBalance.0 }) {
                            if let asset = operation.asset {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Top Category")
                                        .foregroundStyle(.secondary)
                                    HStack {
                                        Text(categoryWithHighestBalance.0.name)
                                            .bold()
                                        Text(categoryWithHighestBalance.1, format: .currency(code: asset.currency.rawValue))
                                            .bold()
                                            .foregroundStyle(Color.accentColor)
                                    }
                                }
                            }
                        }
                        
                        if let operation = operations.first(where: { $0.category == categoryWithLowestBalance.0 }) {
                            if let asset = operation.asset {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Lowest Category")
                                        .foregroundStyle(.secondary)
                                    HStack {
                                        Text(categoryWithLowestBalance.0.name)
                                            .bold()
                                        Text(categoryWithLowestBalance.1, format: .currency(code: asset.currency.rawValue))
                                            .bold()
                                            .foregroundStyle(Color.red)
                                    }
                                }
                            }
                        }
                    }
                    .font(.subheadline)
                    
                    Picker("Date Range", selection: $dateRange.animation()) {
                        ForEach(DateRangeOption.allCases) { range in
                            Text(range.rawValue).tag(range)
                        }
                    }
                    .pickerStyle(.segmented)
                    
                    if !filteredData.isEmpty {
                        Chart(filteredData) { value in
                            if let category = value.category {
                                BarMark(
                                    x: .value("Amount", value.amount),
                                    y: .value("Category", category.name)
                                )
                                .foregroundStyle(by: .value("Category", category.name))
                                .cornerRadius(8)
                            }
                        }
                        .chartLegend(.visible)
                        .chartYAxis {
                            AxisMarks(position: .leading)
                        }
                        .frame(height: 300)
                        .padding(.vertical, 8)
                    } else {
                        ContentUnavailableView(
                            "No Data for Selected Range",
                            systemImage: "chart.line.downtrend.xyaxis",
                            description: Text("Try selecting a different date range or add new operations")
                        )
                        .frame(height: 300)
                    }
                }
                .padding(.top)
            }
        }
        .padding()
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
