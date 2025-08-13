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
    
    @Query(sort: \CategoryOperation.name) var categories: [CategoryOperation]
    
    @State var newCategoryName: String = ""
    @State var showInsert: Bool = false
    @State var showingBulkDeleteAlert: Bool = false
    
    @State private var selectedCategories = Set<CategoryOperation>()
    @State private var isEditMode: EditMode = .inactive
    @State private var isEditCategory: CategoryOperation?
    
    var newCategoryComparison: Bool {
        categories.first(where: { $0.name.trimmingCharacters(in: .whitespaces) == newCategoryName.trimmingCharacters(in: .whitespaces) }) != nil
    }
    
    var body: some View {
        NavigationStack {
            List(selection: $selectedCategories) {
                Section {
                    ForEach(categories) { category in
                        if let editCategory = isEditCategory, editCategory === category {
                            TextField("Name", text: $newCategoryName)
                                .autocorrectionDisabled()
                                .submitLabel(.done)
                                .focused($focusedField, equals: .name)
                                .onSubmit {
                                    focusedField = .none
                                    
                                    if let editCategory = isEditCategory {
                                        saveEditedCategory(category: editCategory)
                                    }
                                }
                                .onAppear() {
                                    focusedField = .name
                                }
                        } else {
                            Text(category.name)
                                .tag(category)
                                .onTapGesture(perform: {
                                    handleEditing(category: category)
                                })
                                .swipeActions {
                                    Button (role: .destructive) {
                                        modelContext.delete(category)
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                    
                                    Button {
                                        handleEditing(category: category)
                                    } label: {
                                        Label("Edit", systemImage: "pencil")
                                    }
                                    .tint(.blue)
                                    .disabled(showInsert)
                                }
                        }
                    }
                }
                .sectionActions {
                    if showInsert {
                        TextField("Name", text: $newCategoryName)
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
                    
                    if !showInsert && isEditCategory == nil && isEditMode != .active {
                        Button {
                            handleInsert()
                        } label: {
                            Label("Add", systemImage: "plus")
                        }
                        .disabled(isEditMode == .active || showInsert)
                    }
                }
            }
            .navigationTitle("Categories")
            .toolbar {
                if (!showInsert && isEditCategory == nil) && !categories.isEmpty {
                    ToolbarItem(placement: .topBarLeading) {
                        EditButton()
                    }
                }
                
                if showInsert || isEditCategory != nil {
                    ToolbarItem(placement: .topBarLeading) {
                        Button {
                            handleInsert(reset: true)
                        } label: {
                            Label("Cancel", systemImage: "xmark")
                        }
                    }
                    
                    if isEditMode == .inactive {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button {
                                if let editCategory = isEditCategory {
                                    saveEditedCategory(category: editCategory)
                                } else {
                                    addCategory()
                                }
                            } label: {
                                Label("Save", systemImage: "checkmark")
                            }
                            .disabled(newCategoryName.isEmpty || newCategoryComparison)
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
                
                ToolbarItem(placement: .keyboard) {
                    Button {
                        focusedField = .none
                    } label: {
                        Label("Hide keyboard", systemImage: "keyboard.chevron.compact.down")
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
    
    func handleInsert(reset: Bool = false) {
        withAnimation {
            newCategoryName = ""
            
            showInsert = !reset
            
            if let _ = isEditCategory, reset {
                isEditCategory = nil
            }
        }
    }
    
    func handleEditing(category: CategoryOperation) {
        if isEditMode == .active { return }
        
        withAnimation {
            isEditCategory = category
            
            newCategoryName = category.name
        }
    }
    
    func saveEditedCategory(category: CategoryOperation) {
        withAnimation {
            category.name = newCategoryName
            
            newCategoryName = ""
            
            isEditCategory = nil
        }
    }
    
    func addCategory() {
        if !newCategoryName.isEmpty {
            if newCategoryComparison { return }
                
            withAnimation {
                modelContext.insert(CategoryOperation(name: newCategoryName))
            
                handleInsert(reset: true)
            }
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
