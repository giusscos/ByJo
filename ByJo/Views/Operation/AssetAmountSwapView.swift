//
//  AssetAmountSwapView.swift
//  ByJo
//
//  Created by Giuseppe Cosenza on 23/08/25.
//

import SwiftData
import SwiftUI

struct AssetAmountSwapView: View {
    enum FocusField: Hashable {
        case amount
    }
    
    @FocusState private var focusedField: FocusField?

    @Environment(\.modelContext) var modelContext
    @Environment(\.dismiss) var dismiss
    
    @AppStorage("currencyCode") var currencyCode: CurrencyCode = .usd
    
    @Query var assets: [Asset]
    
    @State var assetFrom: Asset
    @State var assetTo: Asset
    
    @State private var amountToSwap: Decimal?
    
    var nilAmount: Bool {
        amountToSwap == nil || amountToSwap == .zero
    }
    
    var body: some View {
        NavigationStack {
            List {
                Section("From") {
                    VStack {
                        Picker("Select asset from", selection: $assetFrom) {
                            ForEach(assets) { asset in
                                Text(asset.name)
                                    .font(.title)
                                    .fontWeight(.semibold)
                                    .tag(asset)
                            }
                        }
                        .pickerStyle(.wheel)
                                                    
                        if let amount = amountToSwap {
                            let calculatedAmount = assetFrom.calculateCurrentBalance() - amount
                            
                            HStack (spacing: 6) {
                                Text(currencyCode.symbol)
                                
                                Text(calculatedAmount.formatted(.number.precision(.fractionLength(2))))
                                
                                Spacer()
                            }
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundStyle(.secondary)
                        } else {
                            HStack (spacing: 6) {
                                Text(currencyCode.symbol)
                                
                                Text(0.formatted(.number.precision(.fractionLength(2))))
                            }
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundStyle(.secondary)
                        }
                    }
                }
                .listRowSeparator(.hidden)
                
                Section {
                    HStack {
                        Spacer()
                        
                        Image(systemName: "arrow.down")
                            .imageScale(.large)
                            .font(.title)
                            .fontWeight(.semibold)
                        
                        Spacer()
                    }
                }
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
                
                Section("To") {
                    VStack {
                        Picker("Select asset to", selection: $assetTo) {
                            ForEach(assets) { asset in
                                Text(asset.name)
                                    .font(.title)
                                    .fontWeight(.semibold)
                                    .tag(asset)
                            }
                        }
                        .pickerStyle(.wheel)
                        
                        if let amount = amountToSwap {
                            let calculatedAmount = assetTo.calculateCurrentBalance() + amount
                            
                            HStack (spacing: 6) {
                                Text(currencyCode.symbol)
                                
                                Text(calculatedAmount.formatted(.number.precision(.fractionLength(2))))
                            }
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundStyle(.secondary)
                        } else {
                            HStack (spacing: 6) {
                                Text(currencyCode.symbol)
                                
                                Text(0.formatted(.number.precision(.fractionLength(2))))
                            }
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundStyle(.secondary)
                        }
                    }
                }
                .listRowSeparator(.hidden)
                
                Section {
                    HStack (spacing: 6) {
                        Text(currencyCode.symbol)
                            .foregroundStyle(nilAmount ? .secondary : .primary)
                            .opacity(nilAmount ? 0.5 : 1)
                        
                        TextField("Amount", value: $amountToSwap, format: .number.precision(.fractionLength(2)))
                            .keyboardType(.decimalPad)
                            .font(.headline)
                            .focused($focusedField, equals: .amount)
                            .submitLabel(.done)
                    }
                }
            }
            .padding()
            .navigationTitle("Swap")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Label("Cancel", systemImage: "xmark")
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    if #available(iOS 26, *) {
                        Button (role: .confirm) {
                            print("Save")
                        } label: {
                            Label("Save", systemImage: "checkmark")
                        }
                        .disabled(nilAmount)
                    } else {
                        Button {
                            save()
                        } label: {
                            Label("Save", systemImage: "checkmark")
                        }
                        .disabled(nilAmount)
                    }
                }
            }
            .onAppear() {
                focusedField = .amount
            }
            
            Spacer()
        }
    }
    
    private func save() {
        print("save")
    }
}

#Preview {
    AssetAmountSwapView(
        assetFrom: Asset(name: "Bank", initialBalance: 200.0),
        assetTo: Asset(name: "Cash", initialBalance: 0.0)
    )
}
