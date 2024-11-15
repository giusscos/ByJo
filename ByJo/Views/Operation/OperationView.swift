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
    case editCategory(CategoryOperation)
    
    var id: String {
        switch self {
        case .editOperation(let operation):
            return "editOperation-\(operation.id)"
        case .viewCategories:
            return "viewCategories"
        case .editCategory(let category):
            return "editCategory-\(category.id)"
        }
    }
}

struct OperationView: View {
    @Environment(\.modelContext) var modelContext
    
    @Query(filter: #Predicate<AssetOperation> { value in
        value.name != ""
    }, sort: \AssetOperation.date, order: .reverse) var operations: [AssetOperation]
    
    @Query var assets: [Asset]
    
    @State private var activeSheet: ActiveSheet?
    
    var body: some View {
        List {
            if operations.isEmpty {
                ContentUnavailableView(
                    "No Operations Found",
                    systemImage: "exclamationmark",
                    description: Text("You need to add an operation by clicking the plus button on the top right corner")
                )
            } else {
                ForEach(operations) { value in
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
                        Label("View categories", systemImage: "list.bullet")
                    }
                    
                    Button {
                        addCategoryOperation()
                    } label: {
                        Label("Add category", systemImage: "plus")
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
            case .editCategory(let category):
                EditCategoryOperation(category: category)
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
    
    func addCategoryOperation() {
        let categoryOperation = CategoryOperation(name: "")
        modelContext.insert(categoryOperation)
        activeSheet = .editCategory(categoryOperation)
    }
}

#Preview {
    OperationView()
}

