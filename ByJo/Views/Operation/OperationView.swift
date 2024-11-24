//
//  OperationView.swift
//  ByJo
//
//  Created by Giuseppe Cosenza on 04/11/24.
//

import SwiftUI
import SwiftData

enum ActiveSheet: Identifiable {
    case editOperation(AssetOperation)
    case viewCategories
    
    var id: String {
        switch self {
        case .editOperation(let operation):
            return "editOperation-\(operation.id)"
        case .viewCategories:
            return "viewCategories"
        }
    }
}

struct OperationView: View {
    @Environment(\.modelContext) var modelContext
    
    @Query(sort: \AssetOperation.date, order: .reverse) var operations: [AssetOperation]
    
    @Query var assets: [Asset]
    
    @Query var categories: [CategoryOperation]
    
    @State private var activeSheet: ActiveSheet?
    
    @State private var selectedAsset: Asset?
    @State private var filterCategory: CategoryOperation?
        
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
        List {
            if filteredAndSortedOperations.isEmpty {
                ContentUnavailableView(
                    "No Operations Found",
                    systemImage: "exclamationmark",
                    description: Text("You need to add an operation by clicking the plus button on the top right corner")
                )
            } else {
                ForEach(filteredAndSortedOperations) { item in
                    Section {
                        ForEach(item.operations) { value in
                            NavigationLink(destination: OperationDetailView(operation: value)) {
                                OperationRow(operation: value)
                            }
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    modelContext.delete(value)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                                
                                Button {
                                    activeSheet = .editOperation(value)
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
            }
        }
        .navigationTitle("Operations")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button {
                        addOperation()
                    } label: {
                        Label("Add operation", systemImage: "plus")
                    }
                    
                    Button {
                        activeSheet = .viewCategories
                    } label: {
                        Label("Categories", systemImage: "list.bullet")
                    }
                    
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
                } label: {
                    Label("Menu", systemImage: "ellipsis.circle")
                }
            }
        }
        .sheet(item: $activeSheet) { sheet in
            switch sheet {
            case .editOperation(let operation):
                EditAssetOperation(operation: operation)
            case .viewCategories:
                CategoryOperationView()
                    .presentationDragIndicator(.visible)
            }
        }
    }
    
    func addOperation() {
        if let asset = assets.first {
            let operation = AssetOperation()
            operation.asset = asset
            modelContext.insert(operation)
            activeSheet = .editOperation(operation)
        }
    }
}

struct OperationByDate: Identifiable {
    var date: Date
    var operations: [AssetOperation]
    
    var id: Date { date }
}

#Preview {
    OperationView()
}

