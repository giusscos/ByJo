//
//  EditAssetOperationView.swift
//  ByJo
//
//  Created by Giuseppe Cosenza on 05/11/24.
//

import SwiftUI
import SwiftData
import UserNotifications

private struct SplitRow: Identifiable {
    var id: UUID = UUID()
    var category: CategoryOperation?
    var amountString: String = ""

    init(category: CategoryOperation? = nil, amountString: String = "") {
        self.category = category
        self.amountString = amountString
    }

    var amount: Decimal? {
        let normalized = amountString.replacingOccurrences(of: ",", with: ".")
        guard !normalized.isEmpty else { return nil }
        return Decimal(string: normalized)
    }
}

struct EditAssetOperationView: View {
    enum FocusField: Hashable {
        case name
        case amount
        case note
    }

    @FocusState private var focusedField: FocusField?

    @AppStorage("currencyCode") var currencyCode: CurrencyCode = .usd

    @Environment(\.modelContext) var modelContext
    @Environment(\.dismiss) var dismiss

    @Query var assets: [Asset]
    @Query var categoriesOperation: [CategoryOperation]
    @Query var allOperations: [AssetOperation]

    var operation: AssetOperation?

    @State private var name: String = ""
    @State private var date: Date = .now
    @State private var operationType: OperationType = .inflow
    @State private var amountString: String = ""
    @State var asset: Asset?
    @State var category: CategoryOperation
    @State private var note: String = ""
    @State private var frequency: RecurrenceFrequency = .single
    @State private var isSplit: Bool = false
    @State private var splitRows: [SplitRow] = []

    @State private var showUpdateScopeDialog = false
    @State private var pendingAmount: Decimal = 0

    private var parsedAmount: Decimal? {
        guard !amountString.isEmpty else { return nil }
        let normalized = amountString.replacingOccurrences(of: ",", with: ".")
        return Decimal(string: normalized)
    }

    private var splitTotal: Decimal {
        splitRows.compactMap { $0.amount }.reduce(Decimal(0), +)
    }

    private var splitBalanced: Bool {
        guard let parsed = parsedAmount else { return false }
        return splitTotal == parsed
    }

    private var canSave: Bool {
        guard !name.isEmpty, !amountString.isEmpty else { return false }
        if isSplit { return !splitRows.isEmpty && splitBalanced }
        return true
    }

    private var nameSuggestions: [String] {
        guard !name.isEmpty else { return [] }
        let existing = Set(allOperations.compactMap { $0.name.isEmpty ? nil : $0.name })
        return existing
            .filter { $0.localizedCaseInsensitiveContains(name) && $0.caseInsensitiveCompare(name) != .orderedSame }
            .sorted()
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    TextField("Name", text: $name)
                        .autocorrectionDisabled()
                        .focused($focusedField, equals: .name)
                        .submitLabel(.next)
                        .onSubmit {
                            focusedField = .amount
                        }

                    DatePicker("Date", selection: $date)

                    VStack(alignment: .leading) {
                        Picker("Recurring", selection: $frequency) {
                            ForEach(RecurrenceFrequency.allCases, id: \.self) { frequencyType in
                                Text(frequencyType.displayName)
                            }
                        }
                        .pickerStyle(.menu)

                        if frequency != .single, let nextDate = frequency.nextPaymentDate(from: date) {
                            Group {
                                Text("Next occurrence: ")
                                +
                                Text(nextDate, format: .dateTime.day().month(.abbreviated).year(.twoDigits).hour().minute())
                            }
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .onAppear() {
                                UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { success, error in
                                    if success {
                                        print("All set!")
                                    } else if let error {
                                        print(error.localizedDescription)
                                    }
                                }
                            }
                        }
                    }
                }

                if focusedField == .name && !nameSuggestions.isEmpty {
                    Section("Suggestions") {
                        ForEach(nameSuggestions.prefix(5), id: \.self) { suggestion in
                            Button {
                                name = suggestion
                                focusedField = .amount
                            } label: {
                                Text(suggestion)
                                    .foregroundStyle(.primary)
                            }
                        }
                    }
                }

                Section {
                    VStack(spacing: 6) {
                        ZStack {
                            TextField("0", text: $amountString)
                                .font(.system(size: 52, weight: .bold, design: .rounded))
                                .multilineTextAlignment(.center)
                                .keyboardType(.decimalPad)
                                .focused($focusedField, equals: .amount)
                                .submitLabel(.next)
                                .onSubmit {
                                    focusedField = .note
                                }

                            if !amountString.isEmpty {
                                HStack {
                                    Spacer()
                                    Button {
                                        amountString = ""
                                    } label: {
                                        Image(systemName: "xmark.circle.fill")
                                            .font(.callout)
                                            .foregroundStyle(.tertiary)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }

                        if let value = parsedAmount {
                            Text((operationType == .outflow ? value * -1 : value).formatted(.currency(code: currencyCode.rawValue)))
                                .font(.callout)
                                .foregroundStyle(operationType == .outflow ? .red : .secondary)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)

                    HStack(spacing: 8) {
                        Button {
                            operationType = .inflow
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "arrow.down.circle.fill")
                                Text(OperationType.inflow.displayName)
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        .tint(operationType == .inflow ? .green : .secondary)

                        Button {
                            operationType = .outflow
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "arrow.up.circle.fill")
                                Text(OperationType.outflow.displayName)
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        .tint(operationType == .outflow ? .red : .secondary)
                    }
                }
                .listRowSeparator(.hidden)

                Section {
                    Picker("Asset", selection: $asset) {
                        ForEach(assets) { asset in
                            Text(asset.name)
                                .tag(asset)
                        }
                    }
                    .pickerStyle(.menu)

                    if isSplit {
                        ForEach($splitRows) { $row in
                            HStack {
                                Picker("Category", selection: $row.category) {
                                    Text("—").tag(Optional<CategoryOperation>.none)
                                    ForEach(categoriesOperation) { cat in
                                        Text(cat.name).tag(Optional(cat))
                                    }
                                }
                                .pickerStyle(.menu)
                                .labelsHidden()

                                TextField("Amount", text: $row.amountString)
                                    .keyboardType(.decimalPad)
                                    .multilineTextAlignment(.trailing)
                                    .frame(width: 100)
                            }
                        }
                        .onDelete { indices in splitRows.remove(atOffsets: indices) }

                        Button {
                            splitRows.append(SplitRow(category: categoriesOperation.first))
                        } label: {
                            Label("Add split", systemImage: "plus")
                        }

                        Button {
                            isSplit = false
                            splitRows = []
                        } label: {
                            Label("Remove splits", systemImage: "xmark.circle")
                        }
                        .foregroundStyle(.red)
                    } else {
                        Picker("Category", selection: $category) {
                            ForEach(categoriesOperation) { category in
                                Text(category.name)
                                    .tag(category)
                            }
                        }
                        .pickerStyle(.menu)

                        Button {
                            isSplit = true
                            splitRows = [SplitRow(category: category)]
                        } label: {
                            Label("Split transaction", systemImage: "arrow.triangle.branch")
                        }
                        .foregroundStyle(.secondary)
                    }
                } footer: {
                    if isSplit && parsedAmount != nil {
                        Label(
                            splitBalanced
                                ? "Splits balanced"
                                : "Remaining: \((parsedAmount! - splitTotal).formatted(.currency(code: currencyCode.rawValue)))",
                            systemImage: splitBalanced ? "checkmark.circle.fill" : "exclamationmark.circle.fill"
                        )
                        .font(.caption)
                        .foregroundStyle(splitBalanced ? .green : .orange)
                    }
                }

                Section {
                    TextField("Insert note", text: $note, axis: .vertical)
                        .autocorrectionDisabled()
                        .lineLimit(3...8)
                        .focused($focusedField, equals: .note)
                        .mask {
                            VStack(spacing: 0) {
                                LinearGradient(colors: [.clear, .black], startPoint: .top, endPoint: .bottom)
                                    .frame(height: 10)
                                Color.black
                                LinearGradient(colors: [.black, .clear], startPoint: .top, endPoint: .bottom)
                                    .frame(height: 10)
                            }
                        }
                }
                .listRowInsets(.init(top: 16, leading: 14, bottom: 16, trailing: 16))
            }
            .navigationTitle(operation != nil ? "Edit operation" : "Create operation")
            .toolbar {
                if let operation = operation {
                    ToolbarItem(placement: .topBarLeading) {
                        Button (role: .destructive) {
                            deleteOperation(operation: operation)
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
        }
        .confirmationDialog("Update recurring operation", isPresented: $showUpdateScopeDialog) {
            Button("Update this occurrence only") {
                if let op = operation {
                    applyChanges(to: op, amount: pendingAmount)
                    saveSplits(to: op)
                }
                dismiss()
            }
            Button("Update all occurrences") {
                if let op = operation {
                    applyChangesToAll(to: op, amount: pendingAmount)
                    saveSplits(to: op)
                }
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Do you want to update only this occurrence or all \(siblings.count + 1) occurrences in the series?")
        }
        .onAppear {
            UITextField.appearance().clearButtonMode = .never
            focusedField = .name

            if let operation = operation {
                name = operation.name
                date = operation.date
                amountString = NSDecimalNumber(decimal: abs(operation.amount)).stringValue

                if operation.amount < 0 {
                    operationType = .outflow
                }

                note = operation.note
                frequency = operation.frequency

                if let opAsset = operation.asset {
                    asset = opAsset
                } else {
                    operation.asset = asset
                }

                if let opCategory = operation.category {
                    category = opCategory
                } else {
                    operation.category = category
                }

                if let existingSplits = operation.splits, !existingSplits.isEmpty {
                    isSplit = true
                    splitRows = existingSplits.map { split in
                        SplitRow(
                            category: split.category,
                            amountString: NSDecimalNumber(decimal: abs(split.amount)).stringValue
                        )
                    }
                }
            }

            if asset == nil, let firstAsset = assets.first {
                asset = firstAsset
            }
        }
    }

    private func deleteOperation(operation: AssetOperation) {
        if let seriesId = operation.seriesId {
            cancelRecurringNotifications(seriesId: seriesId)
        }
        modelContext.delete(operation)
        dismiss()
    }

    private var siblings: [AssetOperation] {
        guard let op = operation, let seriesId = op.seriesId else { return [] }
        return allOperations.filter { $0.id != op.id && $0.seriesId == seriesId }
    }

    private func save() {
        var calculatedAmount = parsedAmount ?? .zero
        if operationType == .outflow && calculatedAmount > 0 {
            calculatedAmount = calculatedAmount * -1
        }

        if let op = operation {
            if !siblings.isEmpty {
                pendingAmount = calculatedAmount
                showUpdateScopeDialog = true
                return
            }
            applyChanges(to: op, amount: calculatedAmount)
            saveSplits(to: op)
            if let seriesId = op.seriesId {
                scheduleRecurringNotifications(
                    seriesId: seriesId,
                    name: name,
                    amount: calculatedAmount,
                    startingFrom: date,
                    frequency: frequency,
                    currencyCode: currencyCode
                )
            }
            dismiss()
            return
        }

        let newSeriesId: UUID? = frequency != .single ? UUID() : nil
        let newOperation = AssetOperation(
            id: UUID(),
            name: name,
            date: date,
            amount: calculatedAmount,
            asset: asset,
            category: category,
            note: note,
            frequency: frequency,
            seriesId: newSeriesId
        )

        modelContext.insert(newOperation)
        saveSplits(to: newOperation)

        if let seriesId = newSeriesId {
            scheduleRecurringNotifications(
                seriesId: seriesId,
                name: name,
                amount: calculatedAmount,
                startingFrom: date,
                frequency: frequency,
                currencyCode: currencyCode
            )
        }

        dismiss()
    }

    private func applyChanges(to op: AssetOperation, amount: Decimal) {
        op.name = name
        op.date = date
        op.frequency = frequency
        op.amount = amount
        op.note = note
        op.asset = asset
        op.category = category
    }

    private func applyChangesToAll(to op: AssetOperation, amount: Decimal) {
        applyChanges(to: op, amount: amount)
        let calendar = Calendar.current
        let newTime = calendar.dateComponents([.hour, .minute, .second], from: date)
        for sibling in siblings {
            sibling.name = name
            sibling.amount = amount
            sibling.note = note
            sibling.category = category
            if let updatedDate = calendar.date(
                bySettingHour: newTime.hour ?? 0,
                minute: newTime.minute ?? 0,
                second: newTime.second ?? 0,
                of: sibling.date
            ) {
                sibling.date = updatedDate
            }
        }
        if let seriesId = op.seriesId {
            scheduleRecurringNotifications(
                seriesId: seriesId,
                name: name,
                amount: amount,
                startingFrom: op.date,
                frequency: frequency,
                currencyCode: currencyCode
            )
        }
    }

    private func saveSplits(to op: AssetOperation) {
        for split in op.splits ?? [] {
            modelContext.delete(split)
        }
        guard isSplit else { return }
        for row in splitRows {
            guard let amt = row.amount, amt > 0 else { continue }
            let split = OperationSplit(amount: amt, category: row.category)
            split.operation = op
            modelContext.insert(split)
        }
    }

}

#Preview {
    EditAssetOperationView(
        operation:
            AssetOperation(
                name: "Shopping",
                date: .now,
                amount: 100.0,
                asset: Asset(name: "Cash", initialBalance: 10000)),
        asset: Asset(name: "Cash", initialBalance: 10000),
        category: CategoryOperation(name: "Bank account")
    )
}
