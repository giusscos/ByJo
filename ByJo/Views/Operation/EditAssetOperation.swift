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
        VStack{
            HStack {
                Button (role: .destructive) {
                    modelContext.delete(operation)
                    
                    dismiss()
                } label: {
                    Label("Delete", systemImage: "chevron.left")
                        .labelStyle(.titleOnly)
                }.frame(maxWidth: .infinity, alignment: .leading)
                
                Button {
                    dismiss()
                } label: {
                    Label("Save", systemImage: "checkmark.circle")
                        .labelStyle(.titleOnly)
                }.frame(maxWidth: .infinity, alignment: .trailing)
            }.padding()
            
            List {
                TextField("Name", text: $operation.name)
                
                DatePicker("Date", selection: $operation.date, displayedComponents: .date)
                    .datePickerStyle(.compact)
                
                Picker("Type", selection: $operation.type) {
                    ForEach(AssetOperationType.allCases, id: \.self) { value in
                        Text(value.rawValue)
                    }
                }
                .pickerStyle(.menu)
                
                Picker("Currency", selection: $operation.currency) {
                    ForEach(CurrencyCode.allCases, id: \.self) { value in
                        Text(value.rawValue)
                    }
                }
                .pickerStyle(.menu)
                
                HStack {
                    Text("Amount: ")
                    
                    TextField("Amount", value: $operation.amount, format: .currency(code: operation.currency.rawValue))
                        .keyboardType(.decimalPad)
                        .frame(maxWidth: .infinity, alignment: .trailing)
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
                }.padding(.vertical)
            }.frame(maxHeight: .infinity, alignment: .top)
            .listStyle(.plain)
        }
        .onAppear {
            UITextField.appearance().clearButtonMode = .whileEditing
            
            if let asset = assets.first {
                operation.asset = asset
                operation.currency = asset.currency
            }
                    
            if let category = categoriesOperation.first {
                operation.category = category
            }
        }
    }
}

#Preview {
    EditAssetOperation(operation:
                        AssetOperation(
                            name: "Shopping",
                            date: .now,
                            type: AssetOperationType.transfer,
                            amount: 100.0,
                            asset: Asset(name: "Cash", initialBalance: 10000)
                        )
    )
}
