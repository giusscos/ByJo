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
        case updateValue
        case createOperation
        case editOperation(AssetOperation)
        case createGoal
        case editGoal(Goal)
        case viewGoal
        case viewCategories
        case swapAssetOperation
        
        var id: String {
            switch self {
                case .editAsset:
                    return "editAsset"
                case .updateValue:
                    return "updateValue"
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
                case .swapAssetOperation:
                    return "swapAssetOperation"
            }
        }
    }
    
    @Environment(\.modelContext) var modelContext

    @AppStorage("showAssetBalanceChart") private var showAssetBalanceChart: Bool = true
    
    var asset: Asset

    @Query var categories: [CategoryOperation]
    @Query var assets: [Asset]
    @Query var allOperations: [AssetOperation]
    
    @State private var activeSheet: ActiveSheet?
    @State private var filterCategory: CategoryOperation?
    @State private var isEditMode: EditMode = .inactive
    @State private var selectedOperations = Set<AssetOperation>()
    @State private var showingBulkDeleteAlert = false
    @State private var showingBulkCategorySheet = false
    @State private var showingBulkAssetSheet = false

    
    var filteredAndSortedOperations: [OperationByDate] {
        var filteredOperations = asset.operations ?? []
        
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
            List(selection: $selectedOperations) {
                if showAssetBalanceChart {
                    AssetBalanceHistorySection(asset: asset)
                }

                if !filteredAndSortedOperations.isEmpty {
                    ForEach(filteredAndSortedOperations) { item in
                        Section {
                            ForEach(item.operations) { operation in
                                NavigationLink {
                                    OperationDetailView(operation: operation)
                                } label: {
                                    AssetOperationRow(operation: operation)
                                }
                                .tag(operation)
                                .swipeActions (edge: .trailing) {
                                    Button (role: .destructive) {
                                        deleteOperation(operation)
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
            .environment(\.editMode, $isEditMode)
            .toolbar {
                if !(asset.operations ?? []).isEmpty {
                    ToolbarItem(placement: .topBarLeading) {
                        EditButton()
                    }
                }

                if isEditMode == .active {
                    ToolbarItem(placement: .topBarTrailing) {
                        Menu {
                            Button {
                                showingBulkCategorySheet = true
                            } label: {
                                Label("Change Category", systemImage: "tag")
                            }
                            .disabled(categories.isEmpty)

                            Button {
                                showingBulkAssetSheet = true
                            } label: {
                                Label("Change Asset", systemImage: "building.columns")
                            }
                            .disabled(assets.count < 2)
                        } label: {
                            Label("Reassign", systemImage: "arrow.left.arrow.right")
                        }
                        .disabled(selectedOperations.isEmpty)
                    }

                    ToolbarItem(placement: .topBarTrailing) {
                        Button(role: .destructive) {
                            showingBulkDeleteAlert = true
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                        .tint(.red)
                        .disabled(selectedOperations.isEmpty)
                    }
                } else {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            activeSheet = categories.isEmpty ? .viewCategories : .createOperation
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
                                    Label("Edit", systemImage: "pencil")
                                }

                                Button {
                                    activeSheet = .updateValue
                                } label: {
                                    Label("Update value", systemImage: "arrow.triangle.2.circlepath")
                                }
                                
                                Button {
                                    activeSheet = .swapAssetOperation
                                } label: {
                                    Label("Swap", systemImage: "arrow.up.arrow.down")
                                }
                                .disabled(assets.count < 2)
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

                            Section {
                                Button {
                                    withAnimation {
                                        showAssetBalanceChart.toggle()
                                    }
                                } label: {
                                    Label(
                                        showAssetBalanceChart ? "Hide chart" : "Show chart",
                                        systemImage: showAssetBalanceChart ? "chart.xyaxis.line" : "chart.line.uptrend.xyaxis"
                                    )
                                }
                            }
                            
                            if !(asset.operations ?? []).isEmpty {
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
            }
            .sheet(item: $activeSheet) { sheet in
                switch sheet {
                    case .editAsset:
                        EditAssetView(asset: asset)
                    case .updateValue:
                        UpdateAssetValueView(asset: asset)
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
                    case .swapAssetOperation:
                        if assets.count > 1, let assetTo = assets.filter({ asset in
                            asset != self.asset
                        }).first {
                            AssetAmountSwapView(assetFrom: asset, assetTo: assetTo)
                        }
                }
            }
            .sheet(isPresented: $showingBulkCategorySheet) {
                NavigationStack {
                    List(categories) { category in
                        Button {
                            reassignCategory(category)
                        } label: {
                            Label(category.name, systemImage: "tag")
                                .foregroundStyle(.primary)
                        }
                    }
                    .navigationTitle("Change Category")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Cancel") { showingBulkCategorySheet = false }
                        }
                    }
                }
                .presentationDetents([.medium, .large])
            }
            .sheet(isPresented: $showingBulkAssetSheet) {
                NavigationStack {
                    List(assets.filter { $0 != asset }) { target in
                        Button {
                            reassignAsset(target)
                        } label: {
                            Label(target.name, systemImage: "building.columns")
                                .foregroundStyle(.primary)
                        }
                    }
                    .navigationTitle("Change Asset")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Cancel") { showingBulkAssetSheet = false }
                        }
                    }
                }
                .presentationDetents([.medium, .large])
            }
            .confirmationDialog("Delete Operations", isPresented: $showingBulkDeleteAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    deleteSelectedOperations()
                }
            }
        }
    }
    
    private func deleteOperation(_ operation: AssetOperation) {
        if let swapId = operation.swapId,
           let linked = allOperations.first(where: { $0.id != operation.id && $0.swapId == swapId }) {
            modelContext.delete(linked)
        }
        modelContext.delete(operation)
    }

    private func reassignCategory(_ category: CategoryOperation) {
        for operation in selectedOperations {
            operation.category = category
        }
        selectedOperations.removeAll()
        isEditMode = .inactive
        showingBulkCategorySheet = false
    }

    private func reassignAsset(_ target: Asset) {
        for operation in selectedOperations {
            operation.asset = target
        }
        selectedOperations.removeAll()
        isEditMode = .inactive
        showingBulkAssetSheet = false
    }

    private func deleteSelectedOperations() {
        for operation in selectedOperations {
            withAnimation {
                deleteOperation(operation)
            }
        }
        selectedOperations.removeAll()
        isEditMode = .inactive
    }
}

#Preview {
    AssetDetailView(asset: Asset(name: "Cash", initialBalance: 0))
}
