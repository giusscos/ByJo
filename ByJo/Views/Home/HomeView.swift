//
//  HomeView.swift
//  ByJo
//
//  Created by Giuseppe Cosenza on 04/11/24.
//

import SwiftUI
import SwiftData
import Charts

enum ActiveHomeSheet: Identifiable {
    case assetChart
    case categoryChart
    case operationChart
    
    var id: String {
        switch self {
        case .assetChart: return "assetChart"
        case .categoryChart: return "categoryChart"
        case .operationChart: return "operationChart"
        }
    }
}

struct HomeView: View {
    @Query var assets: [Asset]
    @Query(sort: \AssetOperation.date, order: .reverse) var operations: [AssetOperation]
    
    @Query(sort: \CategoryOperation.name, order: .reverse) var categories: [CategoryOperation]
    
    @State private var activeSheet: ActiveHomeSheet?
    
    @State private var dateRange: DateRangeOption = .month
    
    var filteredData: [AssetOperation] {
        AssetOperation().filterData(for: dateRange, data: operations)
    }
    
    var totalBalance: Decimal {
        assets.reduce(0) { $0 + $1.calculateCurrentBalance() }
    }
    
    var categoryWithHighestBalance: (CategoryOperation, Decimal) { findCategoryWithHighestBalance(categories: categories)
    }
    
    var categoryWithLowestBalance: (CategoryOperation, Decimal) { findCategoryWithLowestBalance(categories: categories)
    }

    var totalExpenses: Decimal {
        filteredData.filter { $0.amount < 0 }.reduce(0) { $0 + $1.amount }
    }
    
    var body: some View {
        List {
            if assets.isEmpty {
                ContentUnavailableView(
                    "No Assets Found",
                    systemImage: "exclamationmark",
                    description: Text("You need to add an asset by selecting the Assets tab and tapping the plus button on the top right corner")
                )
            } else {
                Section {
                    Button {
                        activeSheet = .assetChart
                    } label: {
                        VStack(alignment: .leading) {
                            Text("Your Assets")
                                .font(.title)
                                .bold()
                                
                            if let assetsCurrency = assets.first {
                                Text("Your total wallet balance hits ")
                                + Text(totalBalance, format: .currency(code: assetsCurrency.currency.rawValue))
                                    .bold()
                                    .foregroundStyle(Color.accentColor)
                            }
                            
                            Chart(assets) { value in
                                BarMark(
                                    x: .value("Asset", value.name),
                                    y: .value("Amount", value.calculateCurrentBalance())
                                )
                                .foregroundStyle(by: .value("Asset", value.name))
                                .cornerRadius(4)
                            }
                            .formatChart()
                        }
                    }.tint(.primary)
                }
            }
            
            if operations.isEmpty {
                ContentUnavailableView(
                    "No Operations Found",
                    systemImage: "exclamationmark",
                    description: Text("You need to add an operation by selecting the Operations tab and tapping the plus button on the top right corner")
                )
            } else {
                Section {
                    Button {
                        activeSheet = .categoryChart
                    } label: {
                        VStack(alignment: .leading) {
                            Text("Your Cateogries")
                                .font(.title)
                                .bold()
                            
                            if let operation = operations.first(where: { $0.category == categoryWithHighestBalance.0 }) {
                                Text(categoryWithHighestBalance.0.name)
                                    .bold()
                                    .foregroundStyle(Color.accentColor)
                                + Text(" hits ")
                                + Text(categoryWithHighestBalance.1, format: .currency(code: operation.currency.rawValue))
                                    .bold()
                                    .foregroundStyle(Color.accentColor)
                            }
                            
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
                            .formatChart()
                        }
                    }.tint(.primary)
                }
                
                Section {
                    Button {
                        activeSheet = .operationChart
                    } label: {
                        VStack(alignment: .leading) {
                            Text("Your Operations")
                                .font(.title)
                                .bold()
                            
                            if let assetsCurrency = assets.first {
                                Text("Your expenses this month hits ")
                                + Text(totalExpenses, format: .currency(code: assetsCurrency.currency.rawValue))
                                    .bold()
                                    .foregroundStyle(Color.red)
                            }
                            Chart (filteredData) { value in
                                LineMark(
                                    x: .value("Date", value.date),
                                    y: .value("Amount", value.amount)
                                )
                                .foregroundStyle(Color.accentColor)
                            }
                            .formatChart()
                        }
                    }.tint(.primary)
                }
            }
        }
        .navigationTitle("Home")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $activeSheet) { sheet in
            switch sheet {
            case .assetChart:
                AssetChartDetailView()
                    .presentationDragIndicator(.visible)
            case .categoryChart:
                CategoryChartDetailView()
                    .presentationDragIndicator(.visible)
            case .operationChart:
                OperationChartDetailView()
                    .presentationDragIndicator(.visible)
            }
        }
    }
    
    func calculateCategoryBalance(category: CategoryOperation) -> Decimal {
        let operationsForCategory = operations.filter { $0.category?.id == category.id }
        
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

struct ChartFrame: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding()
            .chartXAxis(.hidden)
            .chartYAxis(.hidden)
            .chartLegend(.hidden)
            .frame(height: 100)
    }
}

extension View {
    func formatChart() -> some View {
        self.modifier(ChartFrame())
    }
}

#Preview {
    HomeView()
}
