//
//  HomeView.swift
//  ByJo
//
//  Created by Giuseppe Cosenza on 04/11/24.
//

import SwiftUI
import SwiftData
import Charts

struct HomeView: View {
    @Environment(\.modelContext) var modelContext
    
    @Namespace private var namespace
    
    @Query var assets: [Asset]
    @Query(sort: \AssetOperation.date, order: .reverse) var operations: [AssetOperation]
    @Query var goals: [Goal]
    
    @Query(sort: \CategoryOperation.name, order: .reverse) var categories: [CategoryOperation]
    
    @State private var dateRange: DateRangeOption = .month
    
    @State private var selectedGoal: Goal?
    
    var filteredData: [AssetOperation] {
        filterData(for: dateRange, data: operations)
    }
    
    var totalBalance: Decimal {
        assets.reduce(0) { $0 + $1.calculateCurrentBalance() }
    }
    
    var categoryWithHighestBalance: (CategoryOperation, Decimal) { findCategoryWithHighestBalance(categories: categories)
    }
    
    var categoryWithLowestBalance: (CategoryOperation, Decimal) { findCategoryWithLowestBalance(categories: categories)
    }

    var totalIncome: Decimal {
        filteredData.filter { $0.amount > 0 }.reduce(0) { $0 + $1.amount }
    }
    
    var totalExpenses: Decimal {
        filteredData.filter { $0.amount < 0 }.reduce(0) { $0 + $1.amount }
    }
    
    var incomeData: [AssetOperation] {
        filterData(for: dateRange, data: operations.filter { $0.amount > 0.0 })
    }
    
    var outcomeData: [AssetOperation] {
        filterData(for: dateRange, data: operations.filter { $0.amount < 0.0 })
    }
    
    var operationsData: [OperationDataType] {
        [OperationDataType(type: "Outcome", data: outcomeData),
         OperationDataType(type: "Income", data: incomeData)]
    }
    
    var body: some View {
        NavigationStack {
            List {
                Button {
                    addGoal()
                } label: {
                    Label("Add goal", systemImage: "plus")
                }
                
                if !goals.isEmpty {
                    Section {
                        ScrollView(.horizontal) {
                            HStack (spacing: 24) {
                                ForEach(goals) { goal in
                                    VStack(alignment: .leading) {
                                        if !goal.title.isEmpty {
                                            Text(goal.title)
                                                .font(.title)
                                                .bold()
                                        }
                                    
                                        if let asset = goal.asset {
                                            Text(asset.name)
                                                .font(.subheadline)
                                                .foregroundColor(.secondary)
                                            
                                            HStack {
                                                Text(asset.calculateCurrentBalance(), format: .currency(code: asset.currency.rawValue))
                                                    .font(.headline)
                                                    .frame(maxWidth: .infinity, alignment: .leading)
                                                
                                                Text(goal.targetAmount, format: .currency(code: asset.currency.rawValue))
                                                    .font(.headline)
                                                    .frame(maxWidth: .infinity, alignment: .trailing)
                                            }
                                            .padding(.top, 8)
                                            
//                                            ProgressView (value: 0.2) {
//                                                HStack {
//                                                    Text(asset.calculateCurrentBalance(), format: .currency(code: asset.currency.rawValue))
//                                                        .font(.headline)
//                                                        .frame(maxWidth: .infinity, alignment: .leading)
//
//                                                    Text(goal.targetAmount, format: .currency(code: asset.currency.rawValue))
//                                                        .font(.headline)
//                                                        .frame(maxWidth: .infinity, alignment: .trailing)
//                                                }
//                                            }
//                                            .progressViewStyle(.linear)
//                                            .padding(.top, 8)
                                        }
                                    }
                                    .onTapGesture {
                                        selectedGoal = goal
                                    }
                                    .padding()
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                                    .containerRelativeFrame(.horizontal)
                                    .scrollTransition(axis: .horizontal) { content, phase in
                                        content
                                            .blur(radius: phase.isIdentity ? 0 : 2)
                                            .offset(x: phase.value * -100)
                                            .scaleEffect(phase.isIdentity ? 1 : 0.7)
                                            .rotation3DEffect(.degrees(phase.value * 10), axis: (x: 0, y: phase.value + -4, z: 0))
                                    }
                                }
                            }.scrollTargetLayout()
                        }
                        .scrollIndicators(.hidden)
                        .scrollTargetBehavior(.viewAligned)
                    }
                    .listRowInsets(.init(top: 0, leading: 0, bottom: 0, trailing: 0))
                    .listRowBackground(Color.clear)
                }
                
                if assets.isEmpty {
                    ContentUnavailableView(
                        "No Assets Found",
                        systemImage: "exclamationmark",
                        description: Text("You need to add an asset by selecting the Assets tab and tapping the plus button on the top right corner")
                    )
                } else {
                    Section {
                        NavigationLink {
                            AssetChartDetailView()
                                .navigationTransition(.zoom(sourceID: 0, in: namespace))
                        } label: {
                            VStack(alignment: .leading) {
                                Text("Assets")
                                    .font(.title)
                                    .bold()
                                    
                                if let assetsCurrency = assets.first {
                                    Text("The sum of your assets hits ")
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
                        .matchedTransitionSource(id: 0, in: namespace)
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
                        NavigationLink {
                            CategoryChartDetailView()
                                .navigationTransition(.zoom(sourceID: 1, in: namespace))
                        } label: {
                            VStack(alignment: .leading) {
                                Text("Cateogries")
                                    .font(.title)
                                    .bold()
                                
                                if let operation = operations.first(where: { $0.category == categoryWithHighestBalance.0 }) {
                                    if let asset = operation.asset {
                                        Text(categoryWithHighestBalance.0.name)
                                            .bold()
                                            .foregroundStyle(Color.accentColor)
                                        + Text(" this month hits ")
                                        + Text(categoryWithHighestBalance.1, format: .currency(code: asset.currency.rawValue))
                                            .bold()
                                            .foregroundStyle(Color.accentColor)
                                    }
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
                            .matchedTransitionSource(id: 1, in: namespace)
                    }
                    
                    Section {
                        NavigationLink {
                            OperationChartDetailView()
                                .navigationTransition(.zoom(sourceID: 2, in: namespace))
                        } label: {
                            VStack(alignment: .leading) {
                                Text("Operations")
                                    .font(.title)
                                    .bold()
                                
                                if let assetsCurrency = assets.first {
                                    Text("Your incomes this month hits ")
                                    + Text(totalIncome, format: .currency(code: assetsCurrency.currency.rawValue))
                                        .bold()
                                        .foregroundStyle(Color.green)
                                    
                                    Text("Your outcomes this month hits ")
                                    + Text(totalExpenses, format: .currency(code: assetsCurrency.currency.rawValue))
                                        .bold()
                                        .foregroundStyle(Color.red)
                                }
                                
                                Chart (operationsData) { operation in
                                    ForEach(operation.data) { value in
                                        PointMark(
                                            x: .value("Date", value.date),
                                            y: .value("Amount", value.amount)
                                        )
                                    }
                                    .foregroundStyle(by: .value("Type", operation.type))
                                    .symbol(by: .value("Type", operation.type))
                                    .symbolSize(30)
                                }
                                .chartForegroundStyleScale([
                                    "Outcome": Color.red,
                                    "Income": Color.green
                                ])
                                .formatChart()
                            }
                        }.tint(.primary)
                            .matchedTransitionSource(id: 2, in: namespace)
                    }
                }
            }
            .navigationTitle("Stats")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(item: $selectedGoal) { item in
                EditGoal(goal: item)
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
    
    func addGoal() {
        let goal = Goal(title: "", targetAmount: 0)
        selectedGoal = goal
        modelContext.insert(goal)
    }
}
    
struct OperationDataType: Identifiable {
    let type: String
    let data: [AssetOperation]
    
    var id: String { type }
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
