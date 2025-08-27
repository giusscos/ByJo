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
        case note
    }
    
    @FocusState private var focusedField: FocusField?

    @Environment(\.modelContext) var modelContext
    @Environment(\.dismiss) var dismiss
    
    @AppStorage("currencyCode") var currencyCode: CurrencyCode = .usd
    
    @Query var assets: [Asset]
    @Query var categoriesOperation: [CategoryOperation]
    
    @State var assetFrom: Asset
    @State var assetTo: Asset
    
    @State private var amountToSwap: Decimal?
    
    @State private var selectedCategory: CategoryOperation?
    @State private var date: Date = .now
    @State private var note: String = ""
    
    var nilAmount: Bool {
        amountToSwap == nil || amountToSwap == .zero
    }
    
    var body: some View {
        NavigationStack {
            List {
                Section("From") {
                    VStack (alignment: .leading) {
                        Picker("Asset from", selection: $assetFrom) {
                            ForEach(assets.filter { $0.id != assetTo.id } ) { asset in
                                Text(asset.name)
                                    .tag(asset)
                            }
                        }
                        .labelsHidden()
                                                    
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
                        
                        Button(action: {
                            let temp = assetFrom
                            
                            assetFrom = assetTo
                            assetTo = temp
                        }) {
                            Image(systemName: "arrow.up.arrow.down")
                                .imageScale(.large)
                                .font(.title2)
                                .fontWeight(.bold)
                        }
                        
                        Spacer()
                    }
                }
                .listRowInsets(.init(top: 0, leading: 0, bottom: 0, trailing: 0))
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
                
                Section("To") {
                    VStack (alignment: .leading) {
                        Picker("Asset to", selection: $assetTo) {
                            ForEach(assets.filter { $0.id != assetFrom.id } ) { asset in
                                Text(asset.name)
                                    .tag(asset)
                            }
                        }
                        .labelsHidden()
                        
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
                
                Section("Details") {
                    HStack (spacing: 6) {
                        Text(currencyCode.symbol)
                            .foregroundStyle(nilAmount ? .secondary : .primary)
                            .opacity(nilAmount ? 0.5 : 1)
                        
                        TextField("Amount", value: $amountToSwap, format: .number.precision(.fractionLength(2)))
                            .keyboardType(.decimalPad)
                            .focused($focusedField, equals: .amount)
                            .submitLabel(.next)
                            .onSubmit {
                                focusedField = .note
                            }
                    }
                    
                    Picker("Category", selection: $selectedCategory) {
                        ForEach(categoriesOperation) { category in
                            Text(category.name).tag(category as CategoryOperation?)
                        }
                    }
                    .pickerStyle(.menu)
                    .disabled(categoriesOperation.isEmpty)
                    
                    DatePicker("Date", selection: $date)
                    
                    TextEditor(text: $note)
                        .autocorrectionDisabled()
                        .overlay(alignment: .topLeading) {
                            if note.isEmpty {
                                Text("Insert note")
                                    .foregroundColor(.secondary.opacity(0.5))
                                    .padding(.horizontal, 2)
                                    .padding(.vertical, 8)
                            }
                        }
                        .focused($focusedField, equals: .note)
                        .frame(minHeight: 60, maxHeight: 180)
                }
            }
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
                            save()
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
                
                ToolbarItem(placement: .keyboard) {
                    Button {
                        focusedField = .none
                    } label: {
                        Label("Hide keyboard", systemImage: "keyboard.chevron.compact.down")
                    }
                }
            }
            .onAppear() {
                focusedField = .amount
                
                if let firstCategory = categoriesOperation.first {
                    selectedCategory = firstCategory
                }
            }
        }
    }
    
    private func save() {
        guard let amount = amountToSwap, amount != 0, assetFrom.id != assetTo.id else { return }
        guard let category = selectedCategory else { return }
        
        let swapId = UUID()
                
        let swaps = [
            AssetOperation(
                name: "Swap",
                date: date,
                amount: amount,
                asset: assetTo,
                category: category,
                note: note,
                swapId: swapId,
            ),
            AssetOperation(
                name: "Swap",
                date: date,
                amount: -amount,
                asset: assetFrom,
                category: category,
                note: note,
                swapId: swapId
            ),
        ]
        
        for swap in swaps {
            modelContext.insert(swap)
        }
        
        dismiss()
    }
}

#Preview {
    AssetAmountSwapView(
        assetFrom: Asset(name: "Bank", initialBalance: 200.0),
        assetTo: Asset(name: "Cash", initialBalance: 0.0)
    )
}
