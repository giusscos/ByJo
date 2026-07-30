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
        case budget
    }

    @FocusState private var focusedField: FocusField?

    @AppStorage("currencyCode") var currencyCode: CurrencyCode = .usd

    @Environment(\.modelContext) var modelContext
    @Environment(\.dismiss) var dismiss
    
    @Query(sort: \CategoryOperation.name) var categories: [CategoryOperation]
    
    @State var newCategoryName: String = ""
    @State var newCategoryBudget: String = ""
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
                            VStack(spacing: 8) {
                                TextField("Name", text: $newCategoryName)
                                    .autocorrectionDisabled()
                                    .submitLabel(.next)
                                    .focused($focusedField, equals: .name)
                                    .onSubmit {
                                        focusedField = .budget
                                    }
                                    .onAppear {
                                        focusedField = .name
                                    }

                                HStack {
                                    Text("Budget / month")
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                    Spacer()
                                    TextField("0", text: $newCategoryBudget)
                                        .keyboardType(.decimalPad)
                                        .multilineTextAlignment(.trailing)
                                        .focused($focusedField, equals: .budget)
                                        .submitLabel(.done)
                                        .onSubmit {
                                            focusedField = .none
                                            saveEditedCategory(category: editCategory)
                                        }
                                        .frame(maxWidth: 120)
                                }
                            }
                        } else {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(category.name)
                                if category.monthlyBudget > 0 {
                                    Text("\(category.monthlyBudget, format: .currency(code: currencyCode.rawValue)) / month")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
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
                            if #available(iOS 26, *) {
                                Button (role: .confirm) {
                                    if let editCategory = isEditCategory {
                                        saveEditedCategory(category: editCategory)
                                    } else {
                                        addCategory()
                                    }
                                } label: {
                                    Label("Save", systemImage: "checkmark")
                                }
                                .disabled(newCategoryName.isEmpty || newCategoryComparison)
                            } else {
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
            newCategoryBudget = ""

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
            newCategoryBudget = category.monthlyBudget == 0 ? "" : NSDecimalNumber(decimal: category.monthlyBudget).stringValue
        }
    }

    func saveEditedCategory(category: CategoryOperation) {
        withAnimation {
            category.name = newCategoryName
            let normalized = newCategoryBudget.replacingOccurrences(of: ",", with: ".")
            category.monthlyBudget = Decimal(string: normalized) ?? 0

            newCategoryName = ""
            newCategoryBudget = ""

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
