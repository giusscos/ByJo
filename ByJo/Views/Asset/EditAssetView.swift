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
    
    @AppStorage("currencyCode") var currencyCode: CurrencyCode = .usd
    
    var asset: Asset?
    
    @State private var name: String = ""
    @State private var initialBalance: Decimal?
    @State private var statusInitialBalance: StatusBalance = .positive
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
                    Picker("Status initial balance", selection: $statusInitialBalance) {
                        ForEach(StatusBalance.allCases, id: \.self) { status in
                            Text(status.rawValue)
                        }
                    }
                    .pickerStyle(.segmented)
                    .disabled(initialBalance == nil)
                    .onChange(of: statusInitialBalance) { oldValue, newValue in
                        if let amountValue = initialBalance {
                            if amountValue > 0, newValue == .negative {
                                initialBalance = amountValue * -1
                            } else {
                                initialBalance = abs(amountValue)
                            }
                        }
                    }
                    
                    HStack (spacing: 6) {
                        Text(currencyCode.symbol)
                            .foregroundStyle(nilBalance ? .secondary : .primary)
                            .opacity(nilBalance ? 0.5 : 1)
                        
                        TextField("Initial balance", value: $initialBalance, format: .number.precision(.fractionLength(2)))
                            .keyboardType(.decimalPad)
                            .autocorrectionDisabled()
                            .focused($focusedField, equals: .balance)
                            .submitLabel(.done)
                            .onSubmit {
                                focusedField = .none
                            }
                    }
                }
                .listRowSeparator(.hidden)
                
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
//                    if #available(iOS 26, *) {
//                        Button(role: .confirm) {
//                            save()
//                        } label: {
//                            Label("Save", systemImage: "checkmark")
//                        }
//                        .disabled(name.isEmpty || initialBalance == nil)
//                    } else {
                        Button {
                            save()
                        } label: {
                            Label("Save", systemImage: "checkmark")
                        }
                        .disabled(name.isEmpty || initialBalance == nil)
//                    }
                }
                
                ToolbarItem(placement: .keyboard) {
                    Button {
                        focusedField = .none
                    } label: {
                        Label("Hide keyboard", systemImage: "keyboard.chevron.compact.down")
                    }
                }
            }
            .onAppear() {
                focusedField = .name
                
                if let asset = asset {
                    name = asset.name
                    initialBalance = asset.initialBalance
                    
                    if asset.initialBalance < 0 {
                        statusInitialBalance = .negative
                    }
                    
                    type = asset.type
                }
            }
        }
    }
    
    private func save() {
        if let amountValue = initialBalance {
            if amountValue < 0, statusInitialBalance == .positive {
                initialBalance = abs(amountValue)
            } else if amountValue > 0, statusInitialBalance == .negative {
                initialBalance = amountValue * -1
            }
        }
        
        if let asset = asset {
            asset.name = name
            
            if let initialBalance = initialBalance {
                asset.initialBalance = initialBalance
            }
            
            asset.type = type
            
            dismiss()
            
            return
        }
        
        let newAsset = Asset(
            name: name,
            type: type,
            initialBalance: initialBalance ?? 0.0
        )
        
        modelContext.insert(newAsset)
        
        dismiss()
    }
    
    private func deleteAsset(asset: Asset) {
        modelContext.delete(asset)
        
        dismiss()
    }
}

#Preview {
    EditAssetView(asset: Asset(name: "Bank", type: .bankAccount, initialBalance: 100))
        .modelContainer(for: Asset.self, inMemory: true)
}
