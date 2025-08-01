//
//  EditAssetView.swift
//  ByJo
//
//  Created by Giuseppe Cosenza on 04/11/24.
//

import SwiftData
import SwiftUI

struct EditAssetView: View {
    enum FocusField: Hashable {
        case name
        case balance
    }
    
    @FocusState private var focusedField: FocusField?
    
    @Environment(\.modelContext) var modelContext
    @Environment(\.dismiss) var dismiss
    
    var asset: Asset?
    
    @State private var name: String = ""
    @State private var currency: CurrencyCode = .usd
    @State private var initialBalance: Decimal?
    @State private var type: AssetType = .bankAccount
    @State private var isNegative: Bool = false
    
    private var nilBalance: Bool {
        initialBalance == nil || initialBalance == .zero
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Name", text: $name)
                        .autocorrectionDisabled()
                        .focused($focusedField, equals: .name)
                        .submitLabel(.next)
                        .onSubmit {
                            focusedField = .balance
                        }
                }
                
                Section {
                    VStack (spacing: 24) {
                        Picker("Balance Type", selection: $isNegative.animation()) {
                            Text("Positive")
                                .tag(false)
                            
                            Text("Negative")
                                .tag(true)
                        }
                        .pickerStyle(.segmented)
                        .disabled(nilBalance)
                        .onChange(of: isNegative) { _, _ in
                            let calculatedAmount = initialBalance ?? .zero
                            
                            initialBalance = calculatedAmount * -1
                        }
                        
                        HStack (spacing: 6) {
                            Text(currency.symbol)
                                .foregroundStyle(nilBalance ? .secondary : .primary)
                                .opacity(nilBalance ? 0.5 : 1)
                            
                            TextField("Initial balance", value: $initialBalance, format: .number)
                                .keyboardType(.decimalPad)
                                .autocorrectionDisabled()
                                .focused($focusedField, equals: .balance)
                                .submitLabel(.done)
                                .onSubmit {
                                    focusedField = .none
                                }
                            
                            Picker("Currency", selection: $currency) {
                                ForEach(CurrencyCode.allCases, id: \.self) { value in
                                    Text(value.rawValue)
                                }
                            }
                            .labelsHidden()
                        }
                    }
                }
                
                Section {
                    Picker("Asset type", selection: $type) {
                        ForEach(AssetType.allCases, id: \.self) { value in
                            Text(value.rawValue)
                        }
                    }
                    .pickerStyle(.menu)
                }
            }
            .navigationTitle(asset == nil ? "Create asset" : "Edit asset")
            .toolbar {
                if let asset = asset {
                    ToolbarItem(placement: .topBarLeading) {
                        Button (role: .destructive) {
                            deleteAsset(asset: asset)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                        .tint(.red)
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        saveAsset()
                    } label: {
                        Label("Save", systemImage: "checkmark")
                    }
                    .disabled(name.isEmpty)
                }
            }
            .onAppear() {
                focusedField = .name
                
                if let asset = asset {
                    name = asset.name
                    currency = asset.currency
                    initialBalance = asset.initialBalance
                    type = asset.type
                }
            }
        }
    }
    
    private func saveAsset() {
        if let asset = asset {
            asset.name = name
            asset.currency = currency
            if let initialBalance = initialBalance {
                asset.initialBalance = initialBalance
            }
            asset.type = type
            
            dismiss()
        } else {
            let newAsset = Asset(
                name: name,
                currency: currency,
                type: type,
                initialBalance: initialBalance ?? 0.0
            )
            
            modelContext.insert(newAsset)
            
            dismiss()
        }
    }
    
    private func deleteAsset(asset: Asset) {
        modelContext.delete(asset)
        
        dismiss()
    }
}

#Preview {
    EditAssetView(asset: Asset(name: "Bank", currency: .usd, type: .bankAccount, initialBalance: 100))
        .modelContainer(for: Asset.self, inMemory: true)
}
