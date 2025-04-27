//
//  EditAsset.swift
//  ByJo
//
//  Created by Giuseppe Cosenza on 04/11/24.
//

import SwiftUI

struct EditAsset: View {
    @Environment(\.modelContext) var modelContext
    @Environment(\.dismiss) var dismiss
    
    @Bindable var asset: Asset
    
    @FocusState var isInputActive: Bool
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    TextField("Name", text: $asset.name)
                        .autocorrectionDisabled()

                    Picker("Currency", selection: $asset.currency) {
                        ForEach(CurrencyCode.allCases, id: \.self) { value in
                            Text(value.rawValue)
                        }
                    }
                    .pickerStyle(.menu)
                    
                    TextField("Initial balance", value: $asset.initialBalance, format: .currency(code: asset.currency.rawValue))
                        .keyboardType(.decimalPad)
                        .autocorrectionDisabled()
                        .focused($isInputActive)
                        .toolbar {
                            ToolbarItemGroup(placement: .keyboard) {
                                Spacer()
                                
                                Button("Done") {
                                    isInputActive = false
                                }
                            }
                        }
                    
                    Picker("Asset type", selection: $asset.type) {
                        ForEach(AssetType.allCases, id: \.self) { value in
                            Text(value.rawValue)
                        }
                    }
                    .pickerStyle(.menu)
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button (role: .destructive) {
                        modelContext.delete(asset)
                        
                        dismiss()
                    } label: {
                        Label("Delete", systemImage: "trash")
                            .labelStyle(.titleOnly)
                    }
                    .foregroundColor(.red)
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Label("Save", systemImage: "checkmark.circle")
                            .labelStyle(.titleOnly)
                    }
                }
            }
        }
    }
}

#Preview {
    EditAsset(asset: Asset(name: "", initialBalance: 0))
        .modelContainer(for: Asset.self, inMemory: true)
}
