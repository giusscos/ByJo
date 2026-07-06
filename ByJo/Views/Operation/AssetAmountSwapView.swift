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
    @State private var swapRotation: Double = 0
    
    @State private var selectedCategory: CategoryOperation?
    @State private var date: Date = .now
    @State private var note: String = ""
    
    var nilAmount: Bool {
        amountToSwap == nil || amountToSwap == .zero
    }
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    VStack(spacing: 4) {
                        ZStack {
                            TextField("0", value: $amountToSwap, format: .number.precision(.fractionLength(2)))
                                .font(.system(size: 52, weight: .bold, design: .rounded))
                                .multilineTextAlignment(.center)
                                .keyboardType(.decimalPad)
                                .focused($focusedField, equals: .amount)
                                .submitLabel(.next)
                                .onSubmit {
                                    focusedField = .note
                                }
                            
                            if !nilAmount {
                                HStack {
                                    Spacer()
                                    Button {
                                        amountToSwap = nil
                                    } label: {
                                        Image(systemName: "xmark.circle.fill")
                                            .font(.callout)
                                            .foregroundStyle(.tertiary)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                        
                        if let amount = amountToSwap, amount != 0 {
                            Text(amount.formatted(.currency(code: currencyCode.rawValue)))
                                .font(.callout)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                }
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
                
                Section("From") {
                    VStack(alignment: .leading, spacing: 4) {
                        Picker("Asset from", selection: $assetFrom) {
                            ForEach(assets.filter { $0.id != assetTo.id }) { asset in
                                Text(asset.name).tag(asset)
                            }
                        }
                        .labelsHidden()
                        
                        balancePreview(
                            current: assetFrom.calculateCurrentBalance(),
                            delta: amountToSwap.map { -$0 }
                        )
                    }
                }
                .listRowSeparator(.hidden)
                
                Section {
                    Button {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                            swapRotation += 180
                        }
                        let temp = assetFrom
                        assetFrom = assetTo
                        assetTo = temp
                    } label: {
                        Image(systemName: "arrow.up.arrow.down")
                            .imageScale(.large)
                            .font(.title2)
                            .fontWeight(.bold)
                            .rotationEffect(.degrees(swapRotation))
                    }
                    .frame(maxWidth: .infinity)
                }
                .listRowInsets(.init(top: 4, leading: 0, bottom: 4, trailing: 0))
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
                
                Section("To") {
                    VStack(alignment: .leading, spacing: 4) {
                        Picker("Asset to", selection: $assetTo) {
                            ForEach(assets.filter { $0.id != assetFrom.id }) { asset in
                                Text(asset.name).tag(asset)
                            }
                        }
                        .labelsHidden()
                        
                        balancePreview(
                            current: assetTo.calculateCurrentBalance(),
                            delta: amountToSwap
                        )
                    }
                }
                .listRowSeparator(.hidden)
                
                Section("Details") {
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
            .listSectionSpacing(.compact)
            .navigationTitle("Swap")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button { dismiss() } label: {
                        Label("Cancel", systemImage: "xmark")
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    if #available(iOS 26, *) {
                        Button(role: .confirm) { save() } label: {
                            Label("Save", systemImage: "checkmark")
                        }
                        .disabled(nilAmount)
                    } else {
                        Button { save() } label: {
                            Label("Save", systemImage: "checkmark")
                        }
                        .disabled(nilAmount)
                    }
                }
                
                ToolbarItem(placement: .keyboard) {
                    Button { focusedField = .none } label: {
                        Label("Hide keyboard", systemImage: "keyboard.chevron.compact.down")
                    }
                }
            }
            .onAppear {
                UITextField.appearance().clearButtonMode = .never
                focusedField = .amount
                if let firstCategory = categoriesOperation.first {
                    selectedCategory = firstCategory
                }
            }
        }
    }
    
    @ViewBuilder
    private func balancePreview(current: Decimal, delta: Decimal?) -> some View {
        HStack(spacing: 8) {
            Text(current.formatted(.currency(code: currencyCode.rawValue)))
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
            
            if let d = delta, d != 0 {
                Image(systemName: "arrow.right")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                
                Text((current + d).formatted(.currency(code: currencyCode.rawValue)))
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundStyle(d < 0 ? .red : .green)
            }
        }
    }
    
    private func save() {
        guard let amount = amountToSwap, amount != 0, assetFrom.id != assetTo.id else { return }
        guard let category = selectedCategory else { return }
        
        let swapId = UUID()
        let swapName = "\(assetFrom.name) → \(assetTo.name)"
        
        let swaps = [
            AssetOperation(
                name: swapName,
                date: date,
                amount: amount,
                asset: assetTo,
                category: category,
                note: note,
                swapId: swapId
            ),
            AssetOperation(
                name: swapName,
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
