//
//  OperationView.swift
//  ByJo
//
//  Created by Giuseppe Cosenza on 04/11/24.
//

import SwiftUI
import SwiftData

struct OperationListView: View {
    enum ActiveSheet: Identifiable {
        case create
        case edit(AssetOperation)
        case createAsset
        case viewCategories
        
        var id: String {
            switch self {
                case .create:
                    return "create"
                case .edit(let operation):
                    return "edit-\(operation.id)"
                case .createAsset:
                    return "createAsset"
                case .viewCategories:
                    return "viewCategories"
            }
        }
    }
    
    @Environment(\.modelContext) var modelContext
    
    @Query(sort: \AssetOperation.date, order: .reverse) var operations: [AssetOperation]
    
    @Query var assets: [Asset]
    
    @Query var categories: [CategoryOperation]
    
    @State private var activeSheet: ActiveSheet?
    @State private var operationToDelete: AssetOperation?
    @State private var showingDeleteAlert = false
    @State private var showingBulkDeleteAlert = false
    
    @State private var selectedAsset: Asset?
    @State private var isEditMode: EditMode = .inactive
    @State private var filterCategory: CategoryOperation?
    @State private var selectedOperations = Set<AssetOperation>()
    
    var filteredAndSortedOperations: [OperationByDate] {
        var filteredOperations = operations
        
        if let asset = selectedAsset {
            filteredOperations = filteredOperations.filter { $0.asset == asset }
        }
        
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
    
    var dateBasedOperations: [OperationByDate] {
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
                    .frame(maxWidth: .infinity)
                } else if filteredAndSortedOperations.isEmpty {
                    VStack {
                        let text = categories.isEmpty ? "categories" : "operations"
                        Text("No \(text) found 😕")
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        Text("Start adding \(text)")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                        
                        Button {
                            activeSheet = categories.isEmpty ? .viewCategories : .create
                        } label: {
                            Text("Add \(text)")
                                .font(.headline)
                        }
                        .tint(.accent)
                        .buttonBorderShape(.capsule)
                        .buttonStyle(.bordered)
                    }
                    .frame(maxWidth: .infinity)
                } else {
                    ForEach(filteredAndSortedOperations) { item in
                        Section {
                            ForEach(item.operations) { operation in
                                if let asset = operation.asset {
                                    NavigationLink {
                                        OperationDetailView(operation: operation, asset: asset)
                                    } label: {
                                        OperationRow(operation: operation, asset: asset)
                                    }
                                    .tag(operation)
                                    .swipeActions(edge: .trailing) {
                                        Button(role: .destructive) {
                                            deleteOperation(operation: operation)
                                        } label: {
                                            Label("Delete", systemImage: "trash")
                                        }
                                        
                                        Button {
                                            activeSheet = .edit(operation)
                                        } label: {
                                            Label("Edit", systemImage: "pencil")
                                        }
                                        .tint(.blue)
                                    }
                                }
                            }
                        } header: {
                            Text(item.date.formatted(.dateTime.day().month().year()))
                                .headerProminence(.increased)
                        }
                    }
                }
            }
            .navigationTitle("Operations")
            .toolbar {
                if !operations.isEmpty {
                    ToolbarItem(placement: .topBarLeading) {
                        EditButton()
                    }
                }
                
                if let _ = assets.first {
                    if isEditMode == .inactive, !categories.isEmpty {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button {
                                activeSheet = .create
                            } label: {
                                Label("Add", systemImage: "plus.circle.fill")
                            }
                        }
                    }
                    
                    ToolbarItem(placement: .topBarTrailing) {
                        if isEditMode == .active {
                            Button(role: .destructive) {
                                showingBulkDeleteAlert = true
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                            .tint(.red)
                            .disabled(selectedOperations.isEmpty)
                        } else {
                            Menu {
                                Button {
                                    activeSheet = .viewCategories
                                } label: {
                                    Label("Categories", systemImage: "list.bullet")
                                }
                                
                                if !operations.isEmpty {
                                    Section {
                                        Menu("By Asset") {
                                            ForEach(assets, id: \.id) { asset in
                                                Button(asset.name) {
                                                    selectedAsset = asset
                                                }
                                            }
                                            Button("Clear Filter") {
                                                selectedAsset = nil
                                            }
                                        }
                                        
                                        Menu("By Category") {
                                            ForEach(categories) { category in
                                                Button(category.name) {
                                                    filterCategory = category
                                                }
                                            }
                                            
                                            Button("Clear Filter") {
                                                filterCategory = nil
                                            }
                                        }
                                    } header: {
                                        Text("Filters")
                                    }
                                }
                            } label: {
                                Label("Menu", systemImage: "ellipsis.circle")
                            }
                        }
                    }
                }
            }
            .environment(\.editMode, $isEditMode)
            .sheet(item: $activeSheet) { sheet in
                switch sheet {
                    case .create:
                        if let asset = assets.first, let category = categories.first {
                            EditAssetOperationView(asset: asset, category: category)
                        }
                    case .edit(let operation):
                        if let asset = assets.first, let category = categories.first {
                            EditAssetOperationView(operation: operation, asset: asset, category: category)
                        }
                    case .createAsset:
                        EditAssetView()
                    case .viewCategories:
                        CategoryOperationView()
                }
            }
            .confirmationDialog("Delete Operations", isPresented: $showingBulkDeleteAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    deleteSelectedOperations()
                }
            }
        }
    }
    
    private func deleteOperation(operation: AssetOperation) {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [operation.id.uuidString])
        
        modelContext.delete(operation)
    }
    
    private func deleteSelectedOperations() {
        for operation in selectedOperations {
            modelContext.delete(operation)
        }
        
        selectedOperations.removeAll()
        
        isEditMode = .inactive
    }
}

struct OperationByDate: Identifiable {
    var date: Date
    var operations: [AssetOperation]
    
    var id: Date { date }
}

#Preview {
    OperationListView()
}

