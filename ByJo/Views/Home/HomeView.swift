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
        case swapAssetOperation
        
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
                case .swapAssetOperation:
                    return "assetAmountSwap"
            }
        }
    }
    
    @Environment(\.requestReview) var requestReview
    
    @AppStorage("currencyCode") var currencyCode: CurrencyCode = .usd
    @AppStorage("compactNumber") var compactNumber: Bool = true
    
    @Query var assets: [Asset]
    
    @Query var goals: [Goal]
    
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
                        VersionedLabel(title: "Add operation", newSystemImage: "plus", oldSystemImage: "plus.circle.fill")
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
                                Label(compactNumber ? "Long amount" : "Short amount", systemImage: compactNumber ? "arrow.up.left.and.arrow.down.right" : "arrow.down.right.and.arrow.up.left")
                            }
                        }
                        
                        Section {
                            Button {
                                activeSheet = .createAsset
                            } label: {
                                Label("Add asset", systemImage: "plus")
                            }
                            
                            Button {
                                activeSheet = .swapAssetOperation
                            } label: {
                                Label("Swap", systemImage: "arrow.up.arrow.down")
                            }
                        }
                        
                        Section {
                            Button {
                                activeSheet = .createGoal
                            } label: {
                                Label("Add goal", systemImage: "plus")
                            }
                            .disabled(assets.isEmpty)
                            
                            Button {
                                activeSheet = .viewGoal
                            } label: {
                                Label("Goals", systemImage: "list.bullet")
                            }
                            .disabled(goals.isEmpty)
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
                        VersionedLabel(title: "Menu", newSystemImage: "ellipsis", oldSystemImage: "ellipsis.circle")
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
                    case .swapAssetOperation:
                        if assets.count > 1, let assetFrom = assets.first, let assetTo = assets.last {
                            AssetAmountSwapView(assetFrom: assetFrom, assetTo: assetTo)
                        }
                }
            }
            .onAppear() {
                if assets.count > 0 && operations.count > 5 {
                    requestReview()
                }
            }
        }
    }
}

#Preview {
    HomeView()
}
