//
//  OperationView.swift
//  ByJo
//
//  Created by Giuseppe Cosenza on 04/11/24.
//

import SwiftUI
import SwiftData

enum OperationListViewSheet: Identifiable {
    case create
    case edit(AssetOperation)
    case createAsset
    case viewCategories
    case swapAssetOperation
    
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
            case .swapAssetOperation:
                return "swapAssetOperation"
        }
    }
}

struct OperationListView: View {
    
    enum OperationSortOrder: String, CaseIterable, Codable {
        case date
        case name
        case amount
    
        var displayName: String {
            switch self {
                case .date: return "Date"
                case .name: return "Name"
                case .amount: return "Amount"
            }
        }
    }
    
    @Environment(\.modelContext) var modelContext
    
    @AppStorage("compactNumber") var compactNumber: Bool = true
    
    @Query(sort: \AssetOperation.date, order: .reverse) var operations: [AssetOperation]
    
    @Query var assets: [Asset]
    
    @Query var categories: [CategoryOperation]
    
    @State private var activeSheet: OperationListViewSheet?
    @State private var operationToDelete: AssetOperation?
    @State private var showingBulkDeleteAlert = false
    
    @State private var selectedAsset: Asset?
    @State private var isEditMode: EditMode = .inactive
    @State private var filterCategory: CategoryOperation?
    @State private var selectedOperations = Set<AssetOperation>()
    
    @State private var sortOrder: OperationSortOrder = .date
    @State private var isAscending: Bool = false
    
    var filteredAndSortedOperations: [OperationByDate] {
        var filteredOperations = operations
        
        if let asset = selectedAsset {
            filteredOperations = filteredOperations.filter { $0.asset == asset }
        }
        
        if let category = filterCategory {
            filteredOperations = filteredOperations.filter { $0.category == category }
        }
        
        switch sortOrder {
        case .date:
            filteredOperations = filteredOperations.sorted { isAscending ? $0.date < $1.date : $0.date > $1.date }
        case .name:
            filteredOperations = filteredOperations.sorted {
                isAscending ? $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending : $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedDescending
            }
        case .amount:
            filteredOperations = filteredOperations.sorted { isAscending ? $0.amount < $1.amount : $0.amount > $1.amount }
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
                    OperationByDateSectionView(filteredAndSortedOperations: filteredAndSortedOperations, activeSheet: $activeSheet)
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
                                VersionedLabel(title: "Add operation", newSystemImage: "plus", oldSystemImage: "plus.circle.fill")
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
                                        activeSheet = .swapAssetOperation
                                    } label: {
                                        Label("Swap", systemImage: "arrow.up.arrow.down")
                                    }
                                }
                                
                                Section {
                                    Button {
                                        activeSheet = .viewCategories
                                    } label: {
                                        Label("Categories", systemImage: "list.bullet")
                                    }
                                }
                                
                                if !operations.isEmpty {
                                    Section {
                                        Menu("By Asset") {
                                            ForEach(assets, id: \.id) { asset in
                                                Button {
                                                    if selectedAsset == asset {
                                                        withAnimation {
                                                            selectedAsset = nil
                                                        }
                                                    } else {
                                                        withAnimation {
                                                            selectedAsset = asset
                                                        }
                                                    }
                                                } label: {
                                                    HStack {
                                                        Text(asset.name)
                                                        
                                                        if selectedAsset == asset {
                                                            Image(systemName: "checkmark")
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                        
                                        Menu("By Category") {
                                            ForEach(categories) { category in
                                                Button {
                                                    if filterCategory == category {
                                                        withAnimation {
                                                            filterCategory = nil
                                                        }
                                                    } else {
                                                        withAnimation {
                                                            filterCategory = category
                                                        }
                                                    }
                                                } label: {
                                                    HStack {
                                                        Text(category.name)
                                                        
                                                        if filterCategory == category {
                                                            Image(systemName: "checkmark")
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    } header: {
                                        Text("Filters")
                                    }
                                }
                                
                                Section("Sorters") {
                                    Menu("Sort By") {
                                        ForEach(OperationSortOrder.allCases, id: \.self) { sort in
                                            Button {
                                                if sortOrder == sort {
                                                    isAscending.toggle()
                                                } else {
                                                    sortOrder = sort
                                                    isAscending = false
                                                }
                                            } label: {
                                                HStack {
                                                    Text(sort.displayName)
                                                    
                                                    if sortOrder == sort {
                                                        Image(systemName: isAscending ? "arrow.up" : "arrow.down")
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
                        if let asset = operation.asset, let category = operation.category {
                            EditAssetOperationView(operation: operation, asset: asset, category: category)
                        }
                    case .createAsset:
                        EditAssetView()
                    case .viewCategories:
                        CategoryOperationView()
                    case .swapAssetOperation:
                        if assets.count > 1, let assetFrom = assets.first, let assetTo = assets.last {
                            AssetAmountSwapView(assetFrom: assetFrom, assetTo: assetTo)
                        }
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
    
    private func deleteSelectedOperations() {
        for operation in selectedOperations {
            modelContext.delete(operation)
        }
        
        selectedOperations.removeAll()
        
        isEditMode = .inactive
    }
}

#Preview {
    OperationListView()
}
