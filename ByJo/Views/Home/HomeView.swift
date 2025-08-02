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
    
    @Namespace private var namespace
    
    @Query var assets: [Asset]
    
    @Query var goals: [Goal]
    
    @Query(sort: \AssetOperation.date, order: .reverse) var operations: [AssetOperation]
    
    @Query(sort: \CategoryOperation.name, order: .reverse) var categories: [CategoryOperation]
    
    @State var activeSheet: ActiveSheet?
    
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
                if !goals.isEmpty {
                    GoalListStackView(goals: goals)
                }
            
                Section {
                    VStack (alignment: .leading, spacing: 24) {
                        HStack (alignment: .center, spacing: 4) {
                            Text("VS last month")
                            
                            Image(systemName: "chevron.right")
                        }
                        .font(.headline)
                        .foregroundStyle(.secondary)
                        
                        HStack (spacing: 4) {
                            Group {
                                if true {
                                    Image(systemName: "arrow.up.circle.fill")
                                        .foregroundStyle(.green)
                                } else {
                                    Image(systemName: "arrow.down.circle.fill")
                                        .foregroundStyle(.red)
                                }
                            }
                            .imageScale(.large)
                            .fontWeight(.semibold)
                            
                            HStack {
                                Text("2000 EUR")
                                    .font(.title)
                                    .fontWeight(.semibold)
                                
                                Text("(20%)")
                                    .font(.title2)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
                
                Section {
                    VStack (alignment: .leading, spacing: 24) {
                        HStack (spacing: 8) {
                            HStack (alignment: .center, spacing: 4) {
                                Text("Recurring operation")
                                
                                Image(systemName: "chevron.right")
                            }
                            .font(.headline)
                            .foregroundStyle(.secondary)
                            
                            Spacer()
                            
                            Text("Aug 10, 25")
                                .font(.headline)
                                .foregroundStyle(.secondary)
                        }
                        
                        VStack (alignment: .leading) {
                            Text("📡 Internet provider")
                                .font(.title3)
                                .fontWeight(.semibold)
                            
                            Text("16,99 EUR/mo")
                                .font(.title)
                                .fontWeight(.semibold)
                        }
                    }
                }
                
                Section {
                    VStack (alignment: .leading, spacing: 24) {
                        HStack (spacing: 8) {
                            HStack (alignment: .center, spacing: 4) {
                                Text("Scheduled expense")
                                
                                Image(systemName: "chevron.right")
                            }
                            .font(.headline)
                            .foregroundStyle(.secondary)
                            
                            Spacer()
                            
                            Text("Aug 15, 25")
                                .font(.headline)
                                .foregroundStyle(.secondary)
                        }
                        
                        VStack (alignment: .leading) {
                            Text("🧾Tax payments")
                                .font(.title3)
                                .fontWeight(.semibold)
                            
                            Text("1.714,50 EUR")
                                .font(.title)
                                .fontWeight(.semibold)
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
            .navigationTitle(Text(netWorth, format: .currency(code: "EUR").notation(.compactName)))
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
        }
    }
}

#Preview {
    HomeView()
}
