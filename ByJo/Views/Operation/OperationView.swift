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
    
    @State var viewCategory: Bool = false
    
    @State var selectedOperation: AssetOperation?
    @State var selectedCategoryOperation: CategoryOperation?
    
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
                    .swipeActions (edge: .trailing) {
                        Button (role: .destructive) {
                            modelContext.delete(value)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                        
                        Button {
                            selectedOperation = value
                        } label: {
                            Label("Edit", systemImage: "pencil")
                        }
                        .tint(.blue)
                    }
                    .sheet(item: $selectedOperation) { value in
                        EditAssetOperation(operation: value)
                    }
                }
                .sheet(isPresented: $viewCategory) {
                    CategoryOperationView()
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
                        viewCategory.toggle()
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
        .sheet(item: $selectedCategoryOperation) { value in
            EditCategoryOperation(category: value)
        }
    }
    
    func addOperation() {
        if(!assets.isEmpty && assets.first != nil) {
            let operation = AssetOperation()
            selectedOperation = operation
            modelContext.insert(operation)
        }
    }
        
    func addCategoryOperation() {
        let categoryOperation = CategoryOperation(name: "")
        selectedCategoryOperation = categoryOperation
        modelContext.insert(categoryOperation)
    }
}

#Preview {
    OperationView()
}
