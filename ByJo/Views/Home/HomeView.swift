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
    
    @AppStorage("currencyCode") var currencyCode: CurrencyCode = .usd
    @AppStorage("compactNumber") var compactNumber: Bool = true
    
    @Query var assets: [Asset]
    
    @Query(sort: \AssetOperation.date, order: .reverse) var operations: [AssetOperation]
    
    @Query(sort: \CategoryOperation.name, order: .reverse) var categories: [CategoryOperation]
    
    @State var activeSheet: ActiveSheet?
    
    var body: some View {
        NavigationStack {
            List {
                GoalListStackView()
                
                NetWorthWidgetView()
                
                PeriodComparisonWidgetView()
                
                RecurringOperationWidgetView()
                
                CategoryWidgetView()
                
                Section {
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
                }
            }
            .navigationTitle("Home")
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
                                    withAnimation {
                                        compactNumber.toggle()
                                    }
                                }
                            } label: {
                                Label(compactNumber ? "Long amount" : "Short amount", systemImage: compactNumber ? "arrow.up.left.and.arrow.down.right" : "arrow.down.right.and.arrow.up.left")
                            }
                        }
                        
                        Section {
                            Button {
                                activeSheet = .createAsset
                            } label: {
                                Label("Add asset", systemImage: "plus")
                            }
                        }
                        
                        Section {
                            Button {
                                activeSheet = .createGoal
                            } label: {
                                Label("Add goal", systemImage: "plus")
                            }
                            
                            Button {
                                activeSheet = .viewGoal
                            } label: {
                                Label("Goals", systemImage: "list.bullet")
                            }
                        }
                        
                        Section {
                            Button {
                                activeSheet = .viewCategories
                            } label: {
                                Label("Categories", systemImage: "list.bullet")
                            }
                        }
                        Section {
                            Menu("Currency") {
                                ForEach(CurrencyCode.allCases, id: \.self) { value in
                                    Button {
                                        withAnimation {
                                            currencyCode = value
                                        }
                                    } label: {
                                        HStack {
                                            Text(value.rawValue)
                                            
                                            if value == currencyCode {
                                                Image(systemName: "checkmark")
                                            }
                                        }
                                    }
                                }
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
