//
//  OperationView.swift
//  ByJo
//
//  Created by Giuseppe Cosenza on 04/11/24.
//

import SwiftUI
import SwiftData

struct OperationView: View {
    @Environment(\.modelContext) var modelContext
    
    @Query(sort: \AssetOperation.date, order: .reverse) var operations: [AssetOperation]
    
    @Query var assets: [Asset]
    
    @State var activeSheet: SheetTypes?
    @State var selectedOperation: AssetOperation?
    @State var selectedCategoryOperation: CategoryOperation?
    
    var body: some View {
        List {
            if operations.isEmpty {
                ContentUnavailableView(
                    "No Operations Found",
                    systemImage: "exclamationmark",
                    description: Text("You need to add a transaction by clicking the plus button on the top right corner")
                )
            } else {
                ForEach(operations) { value in
                    NavigationLink(destination: OperationDetailView(operation: value)) {
                        OperationRow(operation: value)
                    }
                    .swipeActions (edge: .trailing) {
                        Button (role: .destructive) {
                            modelContext.delete(value)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                        
                        Button {
                            print("Edit")
                        } label: {
                            Label("Edit", systemImage: "pencil")
                        }.tint(.blue)
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
                        Label("Add asset", systemImage: "plus")
                    }
                    
                    Button {
                        addCategoryOperation()
                    } label: {
                        Label("Add category", systemImage: "plus")
                    }
                } label: {
                    Label("Add", systemImage: "plus")
                }
            }
            
//            TODO: Edit button implementation
//            if (!assets.isEmpty) {
//                ToolbarItem(placement: .topBarTrailing) {
//                    EditButton()
//                }
//            }
        }
        .sheet(item: $activeSheet) { item in
            switch item {
            case .operation:
                if let operation = selectedOperation {
                    EditAssetOperation(operation: operation)
                }
                
            case .category:
                if let categoryOperation = selectedCategoryOperation {
                    EditCategoryOperation(category: categoryOperation)
                }
            }
        }
    }
    
    func addOperation() {
        if(!assets.isEmpty && assets.first != nil){
            activeSheet = .operation
            let operation = AssetOperation(date: .now, type: .transaction, amount: 0.0)
            selectedOperation = operation
            modelContext.insert(operation)
        }
    }
    
    func addCategoryOperation() {
        activeSheet = .category
        let categoryOperation = CategoryOperation(name: "")
        selectedCategoryOperation = categoryOperation
        modelContext.insert(categoryOperation)
    }
}

enum SheetTypes: Identifiable {
    case operation, category
    
    var id: Int { hashValue }
}

#Preview {
    OperationView()
}
