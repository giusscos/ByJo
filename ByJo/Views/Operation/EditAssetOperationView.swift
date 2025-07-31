//
//  EditAssetOperationView.swift
//  ByJo
//
//  Created by Giuseppe Cosenza on 05/11/24.
//

import SwiftUI
import SwiftData

struct EditAssetOperationView: View {
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
    
    
    var body: some View {
        NavigationStack {
            List {
                TextField("Name", text: $name)
                
                DatePicker("Date", selection: $date, displayedComponents: .date)
                    .datePickerStyle(.compact)
                
                HStack {
                    Text("Amount: ")
                    
                    TextField("Amount", value: $amount, format: .number)
                        .keyboardType(.decimalPad)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                    
                    if var amount = amount {
                        Button {
                            amount *= -1
                        } label: {
                            Label(amount > 0 ? "Negative Amount" : "Positive Amount", systemImage: amount > 0 ? "minus.circle" : "plus.circle")
                                .labelStyle(.iconOnly)
                        }
                        .disabled(amount == 0.0)
                        .padding(.leading)
                    }
                }
                
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
                
                VStack (alignment: .leading) {
                    Text("Note:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    TextEditor(text: $note)
                        .frame(minHeight: 50)
                }
                .padding(.vertical)
            }.frame(maxHeight: .infinity, alignment: .top)
                .toolbar {
                    if let operation = operation {
                        ToolbarItem(placement: .topBarLeading) {
                            Button (role: .destructive) {
                                deleteOperation(operation: operation)
                            } label: {
                                Label("Delete", systemImage: "chevron.left")
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
                }
        }
        .onAppear {
            if let operation = operation {
                name = operation.name
                date = operation.date
                amount = operation.amount
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
        } else {
            let newOperation = AssetOperation(
                name: name,
                currency: asset.currency,
                date: date,
                amount: amount ?? 0.0,
                asset: asset,
                category: category,
                note: note
            )
            
            modelContext.insert(newOperation)
            
            dismiss()
        }
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
