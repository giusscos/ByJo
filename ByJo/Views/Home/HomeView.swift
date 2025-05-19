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
    
    @State private var dateRange: DateRangeOption = .all
    @State private var selectedGoal: Goal?
    @State private var selectedAsset: Asset?
    
    @AppStorage("showingChartLabels") private var showingChartLabels = true
    
    var availableDateRanges: [DateRangeOption] {
        DateRangeOption.availableRanges(for: operations)
    }
    
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
    
    var assetComparisonData: [(Asset, Decimal, Decimal)] {
        let currentRange = dateRange
        let previousRange = currentRange
        
        return assets.map { asset in
            let currentValue = asset.calculateBalanceForDateRange(currentRange)
            let previousValue = asset.calculatePreviousBalanceForDateRange(previousRange)
            return (asset, currentValue, previousValue)
        }
    }
    
    var body: some View {
        NavigationStack {
            List {
                if !goals.isEmpty {
                    Section {
                        ForEach(goals) { goal in
                            GoalRow(goal: goal)
                                .onTapGesture {
                                    selectedGoal = goal
                                }
                        }
                    } header: {
                        Text("Pinned Goals")
                    }
                }
                
                if assets.isEmpty {
                    Section {
                        ContentUnavailableView(
                            "No Assets Found",
                            systemImage: "exclamationmark",
                            description: Text("You need to add an asset by selecting the Assets tab and tapping the plus button on the top right corner"),
                        )
                    }
                } else {
                    Section {
                        Picker("Date Range", selection: $dateRange.animation().animation(.spring())) {
                            ForEach(availableDateRanges) { range in
                                Text(range.label)
                                    .tag(range)
                            }
                        }
                        .pickerStyle(.segmented)
                    }
                    .listRowInsets(.init(top: 0, leading: 0, bottom: 0, trailing: 0))
                    .listRowBackground(Color.clear)
                    
                    Section {
                        NavigationLink {
                            AssetChartDetailView()
                                .navigationTransition(.zoom(sourceID: 0, in: namespace))
                        } label: {
                            AssetsOverviewChart(assets: assets, operations: operations, showingChartLabels: showingChartLabels, dateRange: dateRange)
                        }
                        .tint(.primary)
                        .matchedTransitionSource(id: 0, in: namespace)
                    }
                }
                
                if operations.isEmpty {
                    Section {
                        ContentUnavailableView(
                            "No Operations Found",
                            systemImage: "exclamationmark",
                            description: Text("You need to add an operation by selecting the Operations tab and tapping the plus button on the top right corner")
                        )
                    }
                } else {
                    if !assets.isEmpty {
                        Section {
                            NavigationLink {
                                AssetComparisonDetailView()
                                    .navigationTransition(.zoom(sourceID: 3, in: namespace))
                            } label: {
                                AssetsComparisonChart(assets: assets, assetComparisonData: assetComparisonData, showingChartLabels: showingChartLabels)
                            }
                            .tint(.primary)
                            .matchedTransitionSource(id: 3, in: namespace)
                        }
                    }
                    
                    if !categories.isEmpty {
                        Section {
                            NavigationLink {
                                CategoryChartDetailView()
                                    .navigationTransition(.zoom(sourceID: 1, in: namespace))
                            } label: {
                                CategoriesOverviewChart(categories: categories, filteredData: filteredData, operations: operations, showingChartLabels: showingChartLabels)
                            }
                            .tint(.primary)
                            .matchedTransitionSource(id: 1, in: namespace)
                        }
                    }
                    
                    Section {
                        NavigationLink {
                            OperationChartDetailView()
                                .navigationTransition(.zoom(sourceID: 2, in: namespace))
                        } label: {
                            OperationsOverviewChart(assets: assets, filteredData: filteredData, operationsData: operationsData, showingChartLabels: showingChartLabels)
                        }
                        .tint(.primary)
                        .matchedTransitionSource(id: 2, in: namespace)
                    }
                }
            }
            .navigationTitle("Stats")
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
