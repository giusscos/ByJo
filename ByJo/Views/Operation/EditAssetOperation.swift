//
//  EditAssetOperation.swift
//  ByJo
//
//  Created by Giuseppe Cosenza on 05/11/24.
//

import SwiftUI
import SwiftData

struct EditAssetOperation: View {
    @Environment(\.modelContext) var modelContext
    @Environment(\.dismiss) var dismiss
    
    @Bindable var operation: AssetOperation
    
    @Query var assets: [Asset]
    @Query var categoriesOperation: [CategoryOperation]
    
    var body: some View {
        NavigationStack {
            List {
                TextField("Name", text: $operation.name)
                
                DatePicker("Date", selection: $operation.date, displayedComponents: .date)
                    .datePickerStyle(.compact)
                
                HStack {
                    Text("Amount: ")
                    
                    if let asset = operation.asset {
                        TextField("Amount", value: $operation.amount, format: .currency(code: asset.currency.rawValue))
                            .keyboardType(.decimalPad)
                            .frame(maxWidth: .infinity, alignment: .trailing)
                        
                        Button {
                            operation.amount *= -1
                        } label: {
                            Label("Negative Amount", systemImage: "minus")
                                .labelStyle(.iconOnly)
                        }
                        .disabled(operation.amount.isNaN || operation.amount == 0.0)
                        .padding(.leading)
                    }
                }
                
                Picker("Asset", selection: $operation.asset) {
                    ForEach(assets) { asset in
                        Text(asset.name)
                            .tag(asset)
                    }
                }
                .pickerStyle(.menu)
            
                Picker("Category", selection: $operation.category) {
                    ForEach(categoriesOperation) { category in
                        Text(category.name)
                            .tag(category)
                    }
                }.pickerStyle(.menu)
                
                VStack (alignment: .leading) {
                    Text("Note:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    TextEditor(text: $operation.note)
                        .frame(minHeight: 50)
                }.padding(.vertical)
            }.frame(maxHeight: .infinity, alignment: .top)
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button (role: .destructive) {
                            modelContext.delete(operation)
                            
                            dismiss()
                        } label: {
                            Label("Delete", systemImage: "chevron.left")
                                .labelStyle(.titleOnly)
                        }
                        .tint(.red)
                    }
    
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            dismiss()
                        } label: {
                            Label("Save", systemImage: "checkmark.circle")
                                .labelStyle(.titleOnly)
                        }
                        .disabled(operation.name.isEmpty)
                    }
                }
        }
        .interactiveDismissDisabled(operation.name.isEmpty)
        .onAppear {
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
        }
    }
}

#Preview {
    EditAssetOperation(operation:
                        AssetOperation(
                            name: "Shopping",
                            date: .now,
                            amount: 100.0,
                            asset: Asset(name: "Cash", initialBalance: 10000)
                        )
    )
}
