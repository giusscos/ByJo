//
//  CategoryOperationView.swift
//  ByJo
//
//  Created by Giuseppe Cosenza on 14/11/24.
//

import SwiftUI
import SwiftData

struct CategoryOperationView: View {
    @Environment(\.modelContext) var modelContext
    @Environment(\.dismiss) var dismiss
    
    @Query(sort: \CategoryOperation.name) var categories: [CategoryOperation]
    
    @State var selectedCategoryOperation: CategoryOperation?
    
    var body: some View {
        VStack {
            HStack {
                Button {
                    dismiss()
                } label: {
                    Label("Back", systemImage: "chevron.left")
                }.frame(maxWidth: .infinity, alignment: .leading)
                
                Button {
                    addCategoryOperation()
                } label: {
                    Label("Add", systemImage: "plus")
                        .labelStyle(.titleOnly)
                }.frame(maxWidth: .infinity, alignment: .trailing)
            }.padding()
            
            List {
                Section {
                    ForEach(categories) { value in
                        Text(value.name)
                            .swipeActions {
                                Button (role: .destructive) {
                                    modelContext.delete(value)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                                
                                Button {
                                    selectedCategoryOperation = value
                                } label: {
                                    Label("Edit", systemImage: "pencil")
                                        .tint(.blue)
                                }
                            }
                    }
                } header: {
                    Text("Categories")
                }
            }.listStyle(.plain)
        }.sheet(item: $selectedCategoryOperation) { value in
            EditCategoryOperation(category: value)
        }
    }
    
    func addCategoryOperation() {
        let categoryOperation = CategoryOperation(name: "")
        selectedCategoryOperation = categoryOperation
        modelContext.insert(categoryOperation)
    }
}

#Preview {
    CategoryOperationView()
}