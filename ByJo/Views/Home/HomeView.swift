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
    @Query(filter: #Predicate<Goal> { value in
        value.isPinned
    }, sort: \Goal.dueDate, order: .reverse) var goals: [Goal]
    
    @Query(sort: \CategoryOperation.name, order: .reverse) var categories: [CategoryOperation]
    
    @State private var dateRange: DateRangeOption = .month
    @State private var selectedGoal: Goal?
    @State private var selectedAsset: Asset?
    @AppStorage("showingChartLabels") private var showingChartLabels = true
    
    var filteredData: [AssetOperation] {
        filterData(for: dateRange, data: operations)
    }
    
    var totalBalance: Decimal {
        assets.reduce(0) { $0 + $1.calculateCurrentBalance() }
    }
    
    var categoryWithHighestBalance: (CategoryOperation, Decimal) {
        findCategoryWithHighestBalance(categories: categories)
    }
    
    var categoryWithLowestBalance: (CategoryOperation, Decimal) {
        findCategoryWithLowestBalance(categories: categories)
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
                if !goals.isEmpty {
                    Section {
                        ScrollView(.horizontal) {
                            HStack (spacing: 24) {
                                ForEach(goals) { goal in
                                    GoalRow(goal: goal)
                                        .onTapGesture {
                                            selectedGoal = goal
                                        }
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
                    } header: {
                        Text("Pinned Goals")
                            .font(.headline)
                    }
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
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Assets Overview")
                                    .font(.title2)
                                    .bold()
                                    
                                if let assetsCurrency = assets.first {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Total Balance")
                                            .foregroundStyle(.secondary)
                                        Text(totalBalance, format: .currency(code: assetsCurrency.currency.rawValue))
                                            .font(.title3)
                                            .bold()
                                            .foregroundStyle(Color.accentColor)
                                    }
                                }
                                
                                Chart(assets) { value in
                                    BarMark(
                                        x: .value("Asset", value.name),
                                        y: .value("Amount", value.calculateCurrentBalance())
                                    )
                                    .foregroundStyle(by: .value("Asset", value.name))
                                    .cornerRadius(8)
                                }
                                .chartLegend(showingChartLabels ? .visible : .hidden)
                                .chartYAxis(.hidden)
                                .chartXAxis(.hidden)
                                .frame(height: 200)
                                .padding(.vertical, 8)
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
                        VStack(alignment: .leading, spacing: 8) {
                            Picker("Date Range", selection: $dateRange.animation()) {
                                ForEach(DateRangeOption.allCases) { range in
                                    Text(range.rawValue).tag(range)
                                }
                            }
                            .pickerStyle(.segmented)
                        }
                    }
                    
                    Section {
                        NavigationLink {
                            CategoryChartDetailView()
                                .navigationTransition(.zoom(sourceID: 1, in: namespace))
                        } label: {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Categories Overview")
                                    .font(.title2)
                                    .bold()
                                
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
                                    .chartLegend(showingChartLabels ? .visible : .hidden)
                                    .chartYAxis(.hidden)
                                    .chartXAxis(.hidden)
                                    .frame(height: 200)
                                    .padding(.vertical, 8)
                                } else {
                                    ContentUnavailableView(
                                        "No Data for Selected Range",
                                        systemImage: "calendar.badge.exclamationmark",
                                        description: Text("Try selecting a different date range or add new operations")
                                    )
                                }
                            }
                        }.tint(.primary)
                            .matchedTransitionSource(id: 1, in: namespace)
                    }
                    
                    Section {
                        NavigationLink {
                            OperationChartDetailView()
                                .navigationTransition(.zoom(sourceID: 2, in: namespace))
                        } label: {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Operations Overview")
                                    .font(.title2)
                                    .bold()
                                
                                if let assetsCurrency = assets.first {
                                    VStack(alignment: .leading, spacing: 8) {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text("Income")
                                                .foregroundStyle(.secondary)
                                            Text(totalIncome, format: .currency(code: assetsCurrency.currency.rawValue))
                                                .font(.title3)
                                                .bold()
                                                .foregroundStyle(Color.green)
                                        }
                                        
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text("Expenses")
                                                .foregroundStyle(.secondary)
                                            Text(totalExpenses, format: .currency(code: assetsCurrency.currency.rawValue))
                                                .font(.title3)
                                                .bold()
                                                .foregroundStyle(Color.red)
                                        }
                                    }
                                }
                                
                                if !filteredData.isEmpty {
                                    Chart(operationsData) { operation in
                                        ForEach(operation.data) { value in
                                            LineMark(
                                                x: .value("Date", value.date),
                                                y: .value("Amount", value.amount)
                                            )
                                            .foregroundStyle(by: .value("Type", operation.type))
                                            
                                            PointMark(
                                                x: .value("Date", value.date),
                                                y: .value("Amount", value.amount)
                                            )
                                            .foregroundStyle(by: .value("Type", operation.type))
                                        }
                                    }
                                    .chartForegroundStyleScale([
                                        "Outcome": Color.red,
                                        "Income": Color.green
                                    ])
                                    .chartLegend(showingChartLabels ? .visible : .hidden)
                                    .chartYAxis(.hidden)
                                    .chartXAxis(.hidden)
                                    .frame(height: 200)
                                    .padding(.vertical, 8)
                                } else {
                                    ContentUnavailableView(
                                        "No Data for Selected Range",
                                        systemImage: "calendar.badge.exclamationmark",
                                        description: Text("Try selecting a different date range or add new operations")
                                    )
                                }
                            }
                        }.tint(.primary)
                            .matchedTransitionSource(id: 2, in: namespace)
                    }
                }
            }
            .navigationTitle("Stats")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button {
                            addGoal()
                        } label: {
                            Label("Add goal", systemImage: "plus")
                        }
                        
                        NavigationLink {
                            GoalList()
                        } label: {
                            Label("Goals", systemImage: "list.bullet")
                        }
                        
                        Button {
                            withAnimation(.spring()) {
                                showingChartLabels.toggle()
                            }

                        } label: {
                            Label(showingChartLabels ? "Hide Chart Labels" : "Show Chart Labels",
                                  systemImage: showingChartLabels ? "eye.slash" : "eye")
                        }
                    } label: {
                        Label("Menu", systemImage: "ellipsis.circle")
                    }
                }
            }
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
