//
//  AssetDetailView.swift
//  ByJo
//
//  Created by Giuseppe Cosenza on 04/11/24.
//

import Charts
import SwiftData
import SwiftUI

struct AssetDetailView: View {
    enum ActiveSheet: Identifiable {
        case editAsset
        case createOperation
        case editOperation(AssetOperation)
        case createGoal
        case editGoal(Goal)
        case viewGoal
        case viewCategories
        
        var id: String {
            switch self {
                case .editAsset:
                    return "editAsset"
                case .createOperation:
                    return "createOperation"
                case .editOperation(let operation):
                    return "editOperation-\(operation.id)"
                case .createGoal:
                    return "creteGoal"
                case .editGoal(let goal):
                    return "editGoal-\(goal.id)"
                case .viewGoal:
                    return "viewGoal"
                case .viewCategories:
                    return "viewCategories"
            }
        }
    }
    
    @Environment(\.modelContext) var modelContext
    
    var asset: Asset

    @Query var categories: [CategoryOperation]
    
    @State private var activeSheet: ActiveSheet?
    @State private var filterCategory: CategoryOperation?

    
    var filteredAndSortedOperations: [OperationByDate] {
        guard let assetOperations = asset.operations else { return [] }
        
        var filteredOperations = assetOperations
        
        if let category = filterCategory {
            filteredOperations = filteredOperations.filter { $0.category == category }
        }
        
        return groupOperationsByDate(filteredOperations)
    }
    
    func groupOperationsByDate(_ operations: [AssetOperation]) -> [OperationByDate] {
        let calendar = Calendar.current
        let normalizedOperations = operations.map { operation -> (Date, AssetOperation) in
            let components = calendar.dateComponents([.year, .month, .day], from: operation.date)
            let normalizedDate = calendar.date(from: components)!
            return (normalizedDate, operation)
        }
        
        let groupedDict = Dictionary(grouping: normalizedOperations) { $0.0 }
        
        return groupedDict.map { (date, operationPairs) in
            OperationByDate(date: date, operations: operationPairs.map { $0.1 })
        }.sorted { $0.date > $1.date }
    }
    
    var body: some View {
        NavigationStack {
            List {
                if !filteredAndSortedOperations.isEmpty {
                    ForEach(filteredAndSortedOperations) { item in
                        Section {
                            ForEach(item.operations) { operation in
                                NavigationLink {
                                    OperationDetailView(operation: operation, asset: asset)
                                } label: {
                                    AssetOperationRow(operation: operation, asset: asset)
                                }
                                .swipeActions (edge: .trailing) {
                                    Button (role: .destructive) {
                                        modelContext.delete(operation)
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                    
                                    Button {
                                        activeSheet = .editOperation(operation)
                                    } label: {
                                        Label("Edit", systemImage: "pencil")
                                    }
                                    .tint(.blue)
                                }
                            }
                        } header: {
                            Text(item.date.formatted(.dateTime.day().month().year()))
                                .headerProminence(.increased)
                        }
                    }
                } else {
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
                    .frame(maxWidth: .infinity)

                }
            }
            .navigationTitle(asset.name)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        activeSheet = .createOperation
                    } label: {
                        VersionedLabel(title: "Add operation", newSystemImage: "plus", oldSystemImage: "plus.circle.fill")
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Section {
                            Button {
                                activeSheet = .editAsset
                            } label: {
                                Label("Edit asset", systemImage: "pencil")
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
                                Label("Goal list", systemImage: "list.bullet")
                            }
                        }
                        
                        Section {
                            Button {
                                activeSheet = .viewCategories
                            } label: {
                                Label("Categories", systemImage: "list.bullet")
                            }
                        }
                        
                        if let operations = asset.operations, !operations.isEmpty {
                            Section {
                                Menu("By Category") {
                                    ForEach(categories) { category in
                                        Button(category.name) {
                                            withAnimation {
                                                filterCategory = category
                                            }
                                        }
                                    }
                                    
                                    Button("Clear Filter") {
                                        withAnimation {
                                            filterCategory = nil
                                        }
                                    }
                                }
                            } header: {
                                Text("Filters")
                            }
                        }
                    } label: {
                        VersionedLabel(title: "Menu", newSystemImage: "ellipsis", oldSystemImage: "ellipsis.circle")
                    }
                }
            }
            .sheet(item: $activeSheet) { sheet in
                switch sheet {
                    case .editAsset:
                        EditAssetView(asset: asset)
                    case .createGoal:
                        EditGoalView(asset: asset)
                    case .editGoal(let goal):
                        EditGoalView(goal: goal, asset: asset)
                    case .createOperation:
                        if let category = categories.first {
                            EditAssetOperationView(asset: asset, category: category)
                        }
                    case .editOperation(let operation):
                        if let category = categories.first {
                            EditAssetOperationView(operation: operation, asset: asset, category: category)
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
    AssetDetailView(asset: Asset(name: "Cash", initialBalance: 0))
}
