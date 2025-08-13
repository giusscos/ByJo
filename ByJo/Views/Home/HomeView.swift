//
//  HomeView.swift
//  ByJo
//
//  Created by Giuseppe Cosenza on 04/11/24.
//

import SwiftData
import SwiftUI

struct HomeView: View {
    enum ActiveSheet: Identifiable {
        case createOperation
        case createAsset
        case createGoal
        case viewGoal
        case viewCategories
        
        var id: String {
            switch self {
                case .createOperation:
                    return "createOperation"
                case .createAsset:
                    return "createAsset"
                case .createGoal:
                    return "createGoal"
                case .viewGoal:
                    return "viewGoal"
                case .viewCategories:
                    return "viewCategories"
            }
        }
    }
    
    @Environment(\.modelContext) var modelContext
    
    @AppStorage("currencyCode") var currencyCode: CurrencyCode = .usd

    @Query var assets: [Asset]
    
    @Query(sort: \AssetOperation.date, order: .reverse) var operations: [AssetOperation]
    
    @Query(sort: \CategoryOperation.name, order: .reverse) var categories: [CategoryOperation]
    
    @State var activeSheet: ActiveSheet?
    
    @State var compactNumber: Bool = true
    
    @State private var pendingOperations: [AssetOperation] = []
    @State private var showRecurringAlert = false
    
    var netWorth: Decimal {
        var netWorth: Decimal = 0.0
        
        for asset in assets {
                netWorth += asset.calculateCurrentBalance()
        }
        
        return netWorth
    }
    
    var body: some View {
        NavigationStack {
            List {
                Group {
                    if assets.isEmpty {
                        VStack {
                            Text("No assets found 😕")
                                .font(.title2)
                                .fontWeight(.semibold)
                            
                            Text("Start adding assets")
                                .font(.headline)
                                .foregroundStyle(.secondary)
                            
                            Button {
                                activeSheet = .createAsset
                            } label: {
                                Text("Add asset")
                                    .font(.headline)
                            }
                            .tint(.accent)
                            .buttonBorderShape(.capsule)
                            .buttonStyle(.bordered)
                        }
                    } else if categories.isEmpty || operations.isEmpty {
                        VStack {
                            let text = categories.isEmpty ? "categories" : "operations"
                            
                            Text("No \(text) found 😕")
                                .font(.title2)
                                .fontWeight(.semibold)
                            
                            Text("Start adding \(text)")
                                .font(.headline)
                                .foregroundStyle(.secondary)
                            
                            Button {
                                activeSheet = categories.isEmpty ? .viewCategories : .createOperation
                            } label: {
                                Text("Add \(text)")
                                    .font(.headline)
                            }
                            .tint(.accent)
                            .buttonBorderShape(.capsule)
                            .buttonStyle(.bordered)
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                
                GoalListStackView()
            
                PeriodComparisonWidgetView()
                
                RecurringOperationWidgetView()
                
                CategoryWidgetView()
            }
            .navigationTitle(Text(netWorth, format: compactNumber ? .currency(code: currencyCode.rawValue).notation(.compactName) : .currency(code: currencyCode.rawValue)))
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        activeSheet = .createOperation
                    } label: {
                        Label("Add operation", systemImage: "plus.circle.fill")
                    }
                    .disabled(assets.count == 0 || categories.count == 0)
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Section {
                            Button {
                                withAnimation {
                                    compactNumber.toggle()
                                }
                            } label: {
                                Label(compactNumber ? "Long amount" : "Short amount", systemImage: compactNumber ? "eye" : "eye.slash")
                            }
                        }
                        
                        Section {
                            Button {
                                activeSheet = .createAsset
                            } label: {
                                Label("Create asset", systemImage: "plus")
                            }
                        }
                        
                        Section {
                            Button {
                                activeSheet = .createGoal
                            } label: {
                                Label("Create goal", systemImage: "plus")
                            }
                            
                            Button {
                                activeSheet = .viewGoal
                            } label: {
                                Label("Goal list", systemImage: "list.bullet")
                            }
                        }
                        
                        Section {
                            Button {
                                activeSheet = .viewCategories
                            } label: {
                                Label("Category list", systemImage: "list.bullet")
                            }
                        }
                        
                    } label: {
                        Label("Menu", systemImage: "ellipsis.circle")
                    }
                }
            }
            .sheet(item: $activeSheet) { sheet in
                switch sheet {
                    case .createOperation:
                        if let asset = assets.first, let category = categories.first {
                            EditAssetOperationView(asset: asset, category: category)
                        }
                    case .createAsset:
                        EditAssetView()
                    case .createGoal:
                        if let asset = assets.first {
                            EditGoalView(asset: asset)
                        }
                    case .viewGoal:
                        GoalListView()
                    case .viewCategories:
                        CategoryOperationView()
                }
            }
            .onAppear() {
                processRecurringOperations()
            }
            .alert("New recurring \(pendingOperations.count == 1 ? "operation" : "operations")", isPresented: $showRecurringAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Add") {
                    addPendingOperations()
                }
            } message: {
                Text("\(pendingOperations.count) new \(pendingOperations.count == 1 ? "operation" : "operations") will be added to your operations list.")
            }
        }
    }
    
    private func addPendingOperations() {
        for operation in pendingOperations {
            modelContext.insert(operation)
        }
        
        pendingOperations.removeAll()
    }
    
    func processRecurringOperations() {
        let recurringOperations = operations.filter { operation in
            operation.frequency != RecurrenceFrequency.single
        }
        
        var toAdd: [AssetOperation] = []
        
        for operation in recurringOperations {
            var nextDate = operation.frequency.nextPaymentDate(from: operation.date)
            
            if let category = operation.category {
                while let dueDate = nextDate, dueDate <= Date() {
                    if operations.filter({ $0.name == operation.name && $0.date == dueDate }).count == 0 {
                        let newOperation = AssetOperation(
                            id: UUID(),
                            name: operation.name,
//                            currency: asset.currency,
                            date: dueDate,
                            amount: operation.amount,
                            asset: operation.asset,
                            category: category,
                            note: operation.note,
                            frequency: operation.frequency
                        )
                        
                        toAdd.append(newOperation)
                    }
                    
                    nextDate = operation.frequency.nextPaymentDate(from: dueDate)
                }
            }
        }
        
        if !toAdd.isEmpty {
            pendingOperations = toAdd
//            showRecurringAlert = true
        }
    }
}

#Preview {
    HomeView()
}
