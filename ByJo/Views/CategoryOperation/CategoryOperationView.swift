//
//  CategoryOperationView.swift
//  ByJo
//
//  Created by Giuseppe Cosenza on 14/11/24.
//

import SwiftData
import SwiftUI

struct CategoryOperationView: View {
    enum FocusField: Hashable {
        case name
    }
    
    @FocusState private var focusedField: FocusField?
    
    @Environment(\.modelContext) var modelContext
    @Environment(\.dismiss) var dismiss
    
    @Query(filter: #Predicate<CategoryOperation> { category in
        category.name != ""
    }, sort: \CategoryOperation.name) var categories: [CategoryOperation]
    
    @State var categoryOperationName: String = ""
    @State var showInsert: Bool = false
    @State var showingBulkDeleteAlert: Bool = false
    
    @State private var selectedCategories = Set<CategoryOperation>()
    @State private var isEditMode: EditMode = .inactive
    
    var body: some View {
        NavigationStack {
            List(selection: $selectedCategories) {
                Section {
                    if showInsert {
                        TextField("Name", text: $categoryOperationName)
                            .autocorrectionDisabled()
                            .submitLabel(.done)
                            .focused($focusedField, equals: .name)
                            .onSubmit {
                                focusedField = .none
                                
                                addCategory()
                            }
                            .onAppear() {
                                focusedField = .name
                            }
                    }
                    
                    ForEach(categories) { category in
                        Text(category.name)
                            .tag(category)
                            .swipeActions {
                                Button (role: .destructive) {
                                    modelContext.delete(category)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                                
                                Button {
                                    if showInsert { return }
                                    
                                    categoryOperationName = category.name
                                    
                                    showInsert = true
                                } label: {
                                    Label("Edit", systemImage: "pencil")
                                }
                                .tint(.blue)
                                .disabled(showInsert)
                            }
                    }
                }
                .sectionActions {
                    Button {
                        withAnimation {
                            showInsert = true
                        }
                    } label: {
                        Label("Add", systemImage: "plus")
                    }
                    .disabled(isEditMode == .active)
                }
            }
            .navigationTitle("Categories")
            .toolbar {
                if !showInsert {
                    if !categories.isEmpty {
                        ToolbarItem(placement: .topBarLeading) {
                            EditButton()
                        }
                    }
                } else {
                    ToolbarItem(placement: .topBarLeading) {
                        Button {
                            withAnimation {
                                showInsert = false
                                
                                categoryOperationName = ""
                            }
                        } label: {
                            Label("Cancel", systemImage: "xmark")
                        }
                    }
                    
                    if isEditMode == .inactive {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button {
                                addCategory()
                            } label: {
                                Label("Save", systemImage: "checkmark")
                            }
                            .disabled(categoryOperationName.isEmpty)
                        }
                    }
                }
                
                if isEditMode == .active {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button(role: .destructive) {
                            showingBulkDeleteAlert = true
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                        .tint(.red)
                        .disabled(selectedCategories.isEmpty)
                    }
                }
                
            }
            .environment(\.editMode, $isEditMode)
            .confirmationDialog("Delete Categories", isPresented: $showingBulkDeleteAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    deleteSelectedCatergories()
                }
            }
        }
    }
    
    func addCategory() {
        if !categoryOperationName.isEmpty {
            withAnimation {
                modelContext.insert(CategoryOperation(name: categoryOperationName))
            
                showInsert = false
            }
            
            categoryOperationName = ""            
        }
    }
    
    private func deleteSelectedCatergories() {
        for category in selectedCategories {
            modelContext.delete(category)
        }
        
        isEditMode = .inactive
        
        selectedCategories.removeAll()
    }
}

#Preview {
    CategoryOperationView()
}
