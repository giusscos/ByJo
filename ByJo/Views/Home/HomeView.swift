//
//  HomeView.swift
//  ByJo
//
//  Created by Giuseppe Cosenza on 04/11/24.
//

import SwiftData
import SwiftUI

struct NetWorthComparison {
    var amount: Decimal
    var percentage: Decimal
}

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
    
    @Namespace private var namespace
    
    @Query var assets: [Asset]
    
    @Query var goals: [Goal]
    
    @Query(sort: \AssetOperation.date, order: .reverse) var operations: [AssetOperation]
    
    @Query(sort: \CategoryOperation.name, order: .reverse) var categories: [CategoryOperation]
    
    @State var activeSheet: ActiveSheet?
    
    @State var compactNumber: Bool = true
    
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
    
    var netWorthPreviousPeriod: NetWorthComparison {
        var balancePreviousPeriod: Decimal = 0.0
        var balanceCurrentPeriod: Decimal = 0.0
        
        let period: DateRangeOption = .month

        for asset in assets {
            balancePreviousPeriod += asset.calculatePreviousBalanceForDateRangeWithoutInitialBalance(period)
            balanceCurrentPeriod += asset.calculateBalanceForDateRangeWithoutInitialBalance(period)
        }
        
        let amount = balancePreviousPeriod + balanceCurrentPeriod
        
        return NetWorthComparison(amount: amount, percentage: amount == 0 ? 0 : (amount / (netWorth - amount)) * 100)
    }
    
    var body: some View {
        NavigationStack {
            List {
                GoalListStackView()
            
                Section {
                    VStack (alignment: .leading, spacing: 24) {
                        HStack (spacing: 4) {
                            Text("VS last month")
                        }
                        .font(.headline)
                        .foregroundStyle(.secondary)
                        
                        HStack (spacing: 4) {
                            Group {
                                if netWorthPreviousPeriod.amount > 0 {
                                    Image(systemName: "arrow.up.circle.fill")
                                        .foregroundStyle(.green)
                                } else if netWorthPreviousPeriod.amount == 0 {
                                    Image(systemName: "equal.circle.fill")
                                        .foregroundStyle(.gray)
                                } else {
                                    Image(systemName: "arrow.down.circle.fill")
                                        .foregroundStyle(.red)

                                }
                                
                            }
                            .imageScale(.large)
                            .fontWeight(.semibold)
                            
                            HStack {
                                Text(netWorthPreviousPeriod.amount, format: .currency(code: "EUR").notation(.compactName))
                                    .font(.title)
                                    .fontWeight(.semibold)
                                
                                Group {
                                    Text("(")
                                    +
                                    Text(netWorthPreviousPeriod.percentage, format: .number.precision(.fractionLength(2)))
                                    +
                                    Text("%)")
                                }
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
                
                Section {
                    VStack (alignment: .leading, spacing: 24) {
                        NavigationLink {
                            RecurringOperationListView()
                        } label: {
                            Text("Recurring operation")
                                .font(.headline)
                                .foregroundStyle(.secondary)
                        }
                        
                        HStack (alignment: .lastTextBaseline, spacing: 6) {
                            VStack (alignment: .leading) {
                                Text("📡 Internet provider")
                                    .font(.title3)
                                    .fontWeight(.semibold)
                                
                                Text("16,99 EUR/mo")
                                    .font(.title)
                                    .fontWeight(.semibold)
                            }
                            Spacer()
                            
                            Text("Aug 10, 25")
                                .font(.headline)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                
                Section {
                    VStack (alignment: .leading, spacing: 24) {
                        NavigationLink {
                            
                        } label: {
                            Text("Scheduled expense")
                                .font(.headline)
                                .foregroundStyle(.secondary)
                        }
                        
                        HStack (alignment: .lastTextBaseline, spacing: 8) {
                            VStack (alignment: .leading) {
                                Text("🧾Tax payments")
                                    .font(.title3)
                                    .fontWeight(.semibold)
                                
                                Text("1.714,50 EUR")
                                    .font(.title)
                                    .fontWeight(.semibold)
                            }
                            
                            Spacer()
                            
                            Text("Aug 15, 25")
                                .font(.headline)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                
                Section {
                    VStack (alignment: .leading, spacing: 24) {
                        HStack (alignment: .center, spacing: 4) {
                            Text("Category")
                            
                            Image(systemName: "chevron.right")
                        }
                        .font(.headline)
                        .foregroundStyle(.secondary)
                        
                        VStack (alignment: .leading) {
                            Text("🚗 Transport")
                                .font(.title3)
                                .fontWeight(.semibold)
                            
                            HStack (spacing: 4) {
                                Group {
                                    if false {
                                        Image(systemName: "arrow.up.circle.fill")
                                            .foregroundStyle(.green)
                                    } else {
                                        Image(systemName: "arrow.down.circle.fill")
                                            .foregroundStyle(.red)
                                    }
                                }
                                .imageScale(.large)
                                .fontWeight(.semibold)
                                
                                Text("150 EUR")
                                    .font(.title)
                                    .fontWeight(.semibold)
                            }
                        }
                    }
                }
            }
            .navigationTitle(Text(netWorth, format: compactNumber ? .currency(code: currencyCode).notation(.compactName ) : .currency(code: currencyCode)))
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        activeSheet = .createOperation
                    } label: {
                        Label("Add operation", systemImage: "plus.circle.fill")
                    }
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
                let recurringOperations = operations.filter { operation in
                    operation.frequency != RecurrenceFrequency.single
                }
                
                for recurringOperation in recurringOperations {
                    // TODO: Make a new AssetOperation + schedule new notification
                }
            }
        }
    }
}

#Preview {
    HomeView()
}
