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
    
    @Query(filter: #Predicate<CategoryOperation> { value in
        value.name != ""
    }, sort: \CategoryOperation.name) var categories: [CategoryOperation]
    
    @State var categoryOperation: CategoryOperation = CategoryOperation(name: "")
    @State var showInsert: Bool = false
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    if showInsert {
                        HStack {
                            TextField("Category Name", text: $categoryOperation.name)
                                .autocorrectionDisabled()
                                .onSubmit {
                                    withAnimation {
                                        addCategory()
                                    }
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            Button {
                                withAnimation {
                                    addCategory()
                                }
                            } label: {
                                Label("Done", systemImage: "checkmark")
                                    .labelStyle(.iconOnly)
                            }
                            .buttonStyle(.plain)
                            .foregroundStyle(Color.blue)
                            .padding(.leading)
                            .disabled(categoryOperation.name.isEmpty)
                        }
                    }
                    
                    if !showInsert {
                        Button {
                            withAnimation {
                                showInsert.toggle()
                            }
                        } label: {
                            Label("Add Category", systemImage: "plus")
                        }
                    }
                }
                
                if categories.isEmpty {
                    ContentUnavailableView(
                        "No Categories Found",
                        systemImage: "exclamationmark",
                        description: Text("You need to add a category by clicking the plus button on the top right corner")
                    )
                } else {
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
                                        categoryOperation = value
                                        showInsert.toggle()
                                    } label: {
                                        Label("Edit", systemImage: "pencil")
                                            .tint(.blue)
                                    }
                                }
                        }
                    } header: {
                        Text("Categories")
                    }
                }
            }
        }
    }
    
    func addCategory() {
        if !categoryOperation.name.isEmpty {
            modelContext.insert(categoryOperation)
            categoryOperation = CategoryOperation(name: "")
            showInsert.toggle()
        }
    }
}

#Preview {
    CategoryOperationView()
}
