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
    @Environment(Store.self) private var store
    @Query private var allAssets: [Asset]

    var asset: Asset?

    /// Whether the free plan's asset cap applied when the sheet opened. Frozen on appear
    /// so saving the 3rd asset doesn't flip the closing sheet to the paywall.
    @State private var wasAtFreeLimit: Bool?

    @State private var name: String = ""
    @State private var initialBalanceString: String = ""
    @State private var statusInitialBalance: StatusBalance = .positive
    @State private var type: AssetType = .bankAccount

    private var parsedBalance: Decimal? {
        guard !initialBalanceString.isEmpty else { return nil }
        let normalized = initialBalanceString.normalizedAmountInput
        return Decimal(string: normalized)
    }

    private var isAtFreeLimit: Bool {
        asset == nil && allAssets.count >= Store.freeAssetLimit
    }

    var body: some View {
        Group {
            if (wasAtFreeLimit ?? isAtFreeLimit) && !store.unlocksPro {
                PaywallView(store: store, context: .assetLimit, dismissOnUnlock: false)
            } else {
                editor
            }
        }
        .onAppear {
            if wasAtFreeLimit == nil { wasAtFreeLimit = isAtFreeLimit }
        }
    }

    private var editor: some View {
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
                    VStack(spacing: 6) {
                        ZStack {
                            TextField("0", text: $initialBalanceString)
                                .scaledFont(size: 52, weight: .bold, design: .rounded, maxSize: 88)
                                .minimumScaleFactor(0.5)
                                .accessibilityLabel(Text("Balance"))
                                .multilineTextAlignment(.center)
                                .keyboardType(.decimalPad)
                                .focused($focusedField, equals: .balance)
                                .submitLabel(.done)
                                .onSubmit {
                                    focusedField = .none
                                }

                            if !initialBalanceString.isEmpty {
                                HStack {
                                    Spacer()
                                    Button {
                                        initialBalanceString = ""
                                    } label: {
                                        Image(systemName: "xmark.circle.fill")
                                            .accessibilityLabel(Text("Clear"))
                                            .font(.callout)
                                            .foregroundStyle(.tertiary)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }

                        if let value = parsedBalance {
                            Text((statusInitialBalance == .negative ? value * -1 : value).formatted(.currency(code: currencyCode.rawValue)))
                                .font(.callout)
                                .foregroundStyle(statusInitialBalance == .negative ? .red : .secondary)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)

                    AdaptiveStack(spacing: 8) {
                        Button {
                            statusInitialBalance = .positive
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: statusInitialBalance == .positive ? "plus.circle.fill" : "plus.circle")
                                Text("Positive")
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        .tint(statusInitialBalance == .positive ? .green : .secondary)
                        .accessibilityAddTraits(statusInitialBalance == .positive ? .isSelected : [])

                        Button {
                            statusInitialBalance = .negative
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: statusInitialBalance == .negative ? "minus.circle.fill" : "minus.circle")
                                Text("Negative")
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        .tint(statusInitialBalance == .negative ? .red : .secondary)
                        .accessibilityAddTraits(statusInitialBalance == .negative ? .isSelected : [])
                    }
                }
                .listRowSeparator(.hidden)

                Section {
                    Picker("Asset type", selection: $type) {
                        ForEach(AssetType.allCases, id: \.self) { value in
                            Text(value.displayName)
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
                    if #available(iOS 26, *) {
                        Button(role: .confirm) {
                            save()
                        } label: {
                            Label("Save", systemImage: "checkmark")
                        }
                        .disabled(name.isEmpty || initialBalanceString.isEmpty)
                    } else {
                        Button {
                            save()
                        } label: {
                            Label("Save", systemImage: "checkmark")
                        }
                        .disabled(name.isEmpty || initialBalanceString.isEmpty)
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
                UITextField.appearance().clearButtonMode = .never
                focusedField = .name

                if let asset = asset {
                    name = asset.name
                    initialBalanceString = NSDecimalNumber(decimal: abs(asset.initialBalance)).stringValue

                    if asset.initialBalance < 0 {
                        statusInitialBalance = .negative
                    }

                    type = asset.type
                }
            }
        }
    }

    private func save() {
        var balance = parsedBalance ?? .zero
        if statusInitialBalance == .negative && balance > 0 {
            balance = balance * -1
        }

        if let asset = asset {
            asset.name = name
            asset.initialBalance = balance
            asset.type = type
            dismiss()
            return
        }

        let newAsset = Asset(name: name, type: type, initialBalance: balance)
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
        .environment(Store())
}
