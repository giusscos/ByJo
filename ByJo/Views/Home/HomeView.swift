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
    
    var currencyCode: String {
        if let asset = assets.first {
            return asset.currency.rawValue
        } else {
            return CurrencyCode.usd.rawValue
        }
    }
    
    var body: some View {
        NavigationStack {
            List {
                GoalListStackView()
            
                PeriodComparisonWidgetView()
                
                RecurringOperationWidgetView()
                
//                TODO: scheduled payments
//                Section {
//                    VStack (alignment: .leading, spacing: 24) {
//                        NavigationLink {
//                            
//                        } label: {
//                            Text("Scheduled expense")
//                                .font(.headline)
//                                .foregroundStyle(.secondary)
//                        }
//                        
//                        HStack (alignment: .lastTextBaseline, spacing: 8) {
//                            VStack (alignment: .leading) {
//                                Text("🧾Tax payments")
//                                    .font(.title3)
//                                    .fontWeight(.semibold)
//                                
//                                Text("1.714,50 EUR")
//                                    .font(.title)
//                                    .fontWeight(.semibold)
//                            }
//                            
//                            Spacer()
//                            
//                            Text("Aug 15, 25")
//                                .font(.headline)
//                                .foregroundStyle(.secondary)
//                        }
//                    }
//                }
                
                CategoryWidgetView()
            }
            .navigationTitle(Text(netWorth, format: compactNumber ? .currency(code: currencyCode).notation(.compactName) : .currency(code: currencyCode)))
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
            .alert("New recurring operations",
                   isPresented: $showRecurringAlert) {
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
            if let asset = operation.asset, let category = operation.category {
                while let dueDate = nextDate, dueDate <= Date() {
                    if operations.filter({ $0.name == operation.name && $0.date == dueDate }).count == 0 {
                        let newOperation = AssetOperation(
                            id: UUID(),
                            name: operation.name,
                            currency: asset.currency,
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
            showRecurringAlert = true
        }
    }
}

#Preview {
    HomeView()
}
