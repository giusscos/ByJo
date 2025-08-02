//
//  EditAssetOperationView.swift
//  ByJo
//
//  Created by Giuseppe Cosenza on 05/11/24.
//

import SwiftUI
import SwiftData

struct EditAssetOperationView: View {
    enum FocusField: Hashable {
        case name
        case amount
        case note
    }
    
    @FocusState private var focusedField: FocusField?
    
    @Environment(\.modelContext) var modelContext
    @Environment(\.dismiss) var dismiss
    
    @Query var assets: [Asset]
    @Query var categoriesOperation: [CategoryOperation]
    
    var operation: AssetOperation?
    
    @State private var name: String = ""
    @State private var date: Date = .now
    @State private var amount: Decimal?
    @State var asset: Asset
    @State var category: CategoryOperation
    @State private var note: String = ""
    
    @State private var isExpense: Bool = false
    
    var nilAmount: Bool {
        amount == .zero || amount == nil
    }
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    TextField("Name", text: $name)
                        .autocorrectionDisabled()
                        .focused($focusedField, equals: .name)
                        .submitLabel(.next)
                        .onSubmit {
                            focusedField = .amount
                        }
                    
                    DatePicker("Date", selection: $date)
                }
                
                Section {
                    VStack(spacing: 24) {
                        Picker("Amount Type", selection: $isExpense.animation()) {
                            Text("Positive")
                                .tag(false)
                            
                            Text("Negative")
                                .tag(true)
                        }
                        .pickerStyle(.segmented)
                        .disabled(nilAmount)
                        .onChange(of: isExpense) { _, _ in
                            let calculatedAmount = amount ?? .zero
                            
                            amount = calculatedAmount * -1
                        }
                        
                        HStack (spacing: 6) {
                            Text(asset.currency.symbol)
                                .foregroundStyle(nilAmount ? .secondary : .primary)
                                .opacity(nilAmount ? 0.5 : 1)
                                
                            TextField("Amount", value: $amount, format: .number)
                                .keyboardType(.decimalPad)
                                .focused($focusedField, equals: .amount)
                                .submitLabel(.next)
                                .onSubmit {
                                    focusedField = .note
                                }
                        }
                    }
                }
                
                Section {
                    Picker("Asset", selection: $asset) {
                        ForEach(assets) { asset in
                            Text(asset.name)
                                .tag(asset)
                        }
                    }
                    .pickerStyle(.menu)
                    
                    Picker("Category", selection: $category) {
                        ForEach(categoriesOperation) { category in
                            Text(category.name)
                                .tag(category)
                        }
                    }
                    .pickerStyle(.menu)
                }
                
                Section {
                    TextEditor(text: $note)
                        .autocorrectionDisabled()
                        .overlay(alignment: .topLeading, content: {
                            if note.isEmpty {
                                Text("Insert note")
                                    .foregroundColor(.secondary.opacity(0.5))
                                    .padding(.horizontal, 2)
                                    .padding(.vertical, 8)
                            }
                        })
                        .frame(maxHeight: 256)
                }
                .listRowInsets(.init(top: 16, leading: 14, bottom: 16, trailing: 16))
            }
            .navigationTitle(operation != nil ? "Edit operation" : "Create operation")
            .toolbar {
                if let operation = operation {
                    ToolbarItem(placement: .topBarLeading) {
                        Button (role: .destructive) {
                            deleteOperation(operation: operation)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                        .tint(.red)
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        saveOperation()
                    } label: {
                        Label("Save", systemImage: "checkmark.circle")
                            .labelStyle(.titleOnly)
                    }
                    .disabled(name.isEmpty)
                }
                
                ToolbarItem(placement: .keyboard) {
                    Spacer()
                    
                    Button {
                        focusedField = .none
                    } label: {
                        Label("Hide keyboard", systemImage: "keyboard.chevron.compact.down")
                    }
                }
            }
        }
        .onAppear {
            focusedField = .name
            
            if let operation = operation {
                name = operation.name
                date = operation.date
                amount = operation.amount
                isExpense = operation.amount < 0
                note = operation.note
                
                if operation.asset == nil {
                    if let asset = assets.first {
                        operation.asset = asset
                        operation.currency = asset.currency
                    }
                }
                
                if operation.category == nil {
                    if let category = categoriesOperation.first {
                        operation.category = category
                    }
                }
            } else {
                if let asset = assets.first {
                    self.asset = asset
                    self.asset.currency = asset.currency
                }
                
                if let category = categoriesOperation.first {
                    self.category = category
                }
            }
        }
    }
    
    private func deleteOperation(operation: AssetOperation) {
        modelContext.delete(operation)
        
        dismiss()
    }
    
    private func saveOperation() {
        if let operation = operation {
            operation.name = name
            operation.date = date
            
            if let amount = amount {
                operation.amount = amount
            }
            
            operation.note = note

            operation.asset = asset
            operation.currency = asset.currency

            operation.category = category
            
            dismiss()
            return
        }
        
        let calculatedAmount = amount ?? .zero
        
        let newOperation = AssetOperation(
            name: name,
            currency: asset.currency,
            date: date,
            amount: calculatedAmount,
            asset: asset,
            category: category,
            note: note
        )
        
        modelContext.insert(newOperation)
        
        dismiss()   
    }
}

#Preview {
    EditAssetOperationView(
        operation:
            AssetOperation(
                name: "Shopping",
                date: .now,
                amount: 100.0,
                asset: Asset(name: "Cash", initialBalance: 10000)),
        asset: Asset(name: "Bank", initialBalance: 100.0),
        category: CategoryOperation(name: "Bank account")
    )
}
