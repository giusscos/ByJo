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
                        NavigationLink {
                            AssetChartDetailView()
                                .navigationTransition(.zoom(sourceID: 0, in: namespace))
                        } label: {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Assets Overview")
                                    .font(.title2)
                                    .bold()
                                
                                if let assetsCurrency = assets.first {
                                    Text("The sum of your assets hits ") + Text(totalBalance, format: .currency(code: assetsCurrency.currency.rawValue))
                                        .bold()
                                        .foregroundStyle(Color.accentColor)
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
                    
                    if !categories.isEmpty {
                        Section {
                            NavigationLink {
                                CategoryChartDetailView()
                                    .navigationTransition(.zoom(sourceID: 1, in: namespace))
                            } label: {
                                VStack(alignment: .leading, spacing: 12) {
                                    Text("Categories Overview")
                                        .font(.title2)
                                        .bold()
                                    
                                    if !filteredData.isEmpty {
                                        if let operation = operations.first(where: { $0.category == categoryWithHighestBalance.0 }) {
                                            if let asset = operation.asset {
                                                Text(categoryWithHighestBalance.0.name)
                                                    .bold()
                                                    .foregroundStyle(Color.accentColor)
                                                + Text(" this period hits ")
                                                + Text(categoryWithHighestBalance.1, format: .currency(code: asset.currency.rawValue))
                                                    .bold()
                                                    .foregroundStyle(Color.green)
                                            }
                                        }
                                        
                                        if let operation = operations.first(where: { $0.category == categoryWithLowestBalance.0 }) {
                                            if let asset = operation.asset {
                                                Text(categoryWithLowestBalance.0.name)
                                                    .bold()
                                                    .foregroundStyle(Color.accentColor)
                                                + Text(" this period hits ")
                                                + Text(categoryWithLowestBalance.1, format: .currency(code: asset.currency.rawValue))
                                                    .bold()
                                                    .foregroundStyle(Color.red)
                                            }
                                        }
                                        
                                        let groupedData = Dictionary(grouping: filteredData, by: { $0.category?.name ?? "" })
                                            .map { (key, values) in
                                                (
                                                    category: key,
                                                    total: values.reduce(0) { $0 + $1.amount }
                                                )
                                            }
                                            .filter { !$0.category.isEmpty }
                                            .sorted { abs($0.total) > abs($1.total) }
                                        
                                        Chart(groupedData, id: \.category) { item in
                                            BarMark(
                                                x: .value("Amount", item.total),
                                                y: .value("Category", item.category)
                                            )
                                            .foregroundStyle(by: .value("Category", item.category))
                                            .cornerRadius(8)
                                        }
                                        .chartLegend(showingChartLabels ? .visible : .hidden)
                                        .chartYAxis(.hidden)
                                        .chartXAxis(.hidden)
                                        .frame(height: 200)
                                        .padding(.vertical, 8)
                                    } else {
                                        ContentUnavailableView(
                                            "No Data for Selected Range",
                                            systemImage: "exclamationmark",
                                            description: Text("Try selecting a different date range or add new operations")
                                        )
                                    }
                                }
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
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Operations Overview")
                                    .font(.title2)
                                    .bold()
                                
                                if !filteredData.isEmpty {
                                    if let assetsCurrency = assets.first {
                                        if totalIncome > 0 {
                                            Text("Your incomes this period hits ") + Text(totalIncome, format: .currency(code: assetsCurrency.currency.rawValue))
                                                .bold()
                                                .foregroundStyle(Color.green)
                                        }
                                        
                                        if totalExpenses < 0 {
                                            Text("Your outcomes this period hits ") + Text(totalExpenses, format: .currency(code: assetsCurrency.currency.rawValue))
                                                .bold()
                                                .foregroundStyle(Color.red)
                                        }
                                    }
                                    
                                    Chart(operationsData) { operation in
                                        ForEach(operation.data) { value in
                                            LineMark(
                                                x: .value("Date", value.date, unit: .day),
                                                y: .value("Amount", value.amount)
                                            )
                                            .foregroundStyle(by: .value("Type", operation.type))
                                            
                                            PointMark(
                                                x: .value("Date", value.date, unit: .day),
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
                                        systemImage: "exclamationmark",
                                        description: Text("Try selecting a different date range or add new operations")
                                    )
                                }
                            }
                            
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
