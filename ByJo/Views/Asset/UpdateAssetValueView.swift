//
//  UpdateAssetValueView.swift
//  ByJo
//

import SwiftData
import SwiftUI

struct UpdateAssetValueView: View {
    enum FocusField: Hashable {
        case value
        case note
    }

    @FocusState private var focusedField: FocusField?

    @Environment(\.modelContext) var modelContext
    @Environment(\.dismiss) var dismiss

    @AppStorage("currencyCode") var currencyCode: CurrencyCode = .usd

    var asset: Asset

    @State private var valueString: String = ""
    @State private var statusValue: StatusBalance = .positive
    @State private var date: Date = .now
    @State private var note: String = ""

    private var currentBalance: Decimal {
        asset.calculateCurrentBalance()
    }

    private var parsedValue: Decimal? {
        guard !valueString.isEmpty else { return nil }
        let normalized = valueString.replacingOccurrences(of: ",", with: ".")
        return Decimal(string: normalized)
    }

    private var newValue: Decimal? {
        guard let parsed = parsedValue else { return nil }
        return statusValue == .negative ? parsed * -1 : parsed
    }

    private var delta: Decimal? {
        guard let newValue else { return nil }
        return newValue - currentBalance
    }

    private var canSave: Bool {
        guard let delta else { return false }
        return delta != 0
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    LabeledContent("Current") {
                        Text(currentBalance, format: .currency(code: currencyCode.rawValue))
                            .foregroundStyle(.secondary)
                    }
                }

                Section {
                    VStack(spacing: 6) {
                        ZStack {
                            TextField("0", text: $valueString)
                                .font(.system(size: 52, weight: .bold, design: .rounded))
                                .multilineTextAlignment(.center)
                                .keyboardType(.decimalPad)
                                .focused($focusedField, equals: .value)

                            if !valueString.isEmpty {
                                HStack {
                                    Spacer()
                                    Button {
                                        valueString = ""
                                    } label: {
                                        Image(systemName: "xmark.circle.fill")
                                            .font(.callout)
                                            .foregroundStyle(.tertiary)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }

                        if let newValue {
                            Text(newValue, format: .currency(code: currencyCode.rawValue))
                                .font(.callout)
                                .foregroundStyle(statusValue == .negative ? .red : .secondary)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)

                    HStack(spacing: 8) {
                        Button {
                            statusValue = .positive
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "plus.circle.fill")
                                Text("Positive")
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        .tint(statusValue == .positive ? .green : .secondary)

                        Button {
                            statusValue = .negative
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "minus.circle.fill")
                                Text("Negative")
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        .tint(statusValue == .negative ? .red : .secondary)
                    }
                } header: {
                    Text("New value")
                } footer: {
                    if let delta, delta != 0 {
                        Text("Adjustment: \(delta.formatted(.currency(code: currencyCode.rawValue)))")
                            .foregroundStyle(delta >= 0 ? .green : .red)
                    }
                }
                .listRowSeparator(.hidden)

                Section {
                    DatePicker("Date", selection: $date)

                    TextField("Note (optional)", text: $note, axis: .vertical)
                        .lineLimit(2...4)
                        .focused($focusedField, equals: .note)
                }
            }
            .navigationTitle("Update value")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    if #available(iOS 26, *) {
                        Button(role: .confirm) {
                            save()
                        } label: {
                            Label("Save", systemImage: "checkmark")
                        }
                        .disabled(!canSave)
                    } else {
                        Button {
                            save()
                        } label: {
                            Label("Save", systemImage: "checkmark")
                        }
                        .disabled(!canSave)
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
            .onAppear {
                UITextField.appearance().clearButtonMode = .never
                focusedField = .value

                let balance = currentBalance
                valueString = NSDecimalNumber(decimal: abs(balance)).stringValue
                statusValue = balance < 0 ? .negative : .positive
            }
        }
    }

    private func save() {
        guard let delta, delta != 0 else {
            dismiss()
            return
        }

        let category = findOrCreateValueUpdateCategory()
        modelContext.insert(AssetOperation(
            name: "Value update",
            date: date,
            amount: delta,
            asset: asset,
            category: category,
            note: note
        ))
        dismiss()
    }

    private func findOrCreateValueUpdateCategory() -> CategoryOperation {
        let descriptor = FetchDescriptor<CategoryOperation>(
            predicate: #Predicate { $0.name == "Value update" }
        )
        if let existing = (try? modelContext.fetch(descriptor))?.first {
            return existing
        }
        let category = CategoryOperation(name: "Value update")
        modelContext.insert(category)
        return category
    }
}

#Preview {
    UpdateAssetValueView(asset: Asset(name: "Bitcoin", type: .crypto, initialBalance: 3500))
        .modelContainer(for: Asset.self, inMemory: true)
}
