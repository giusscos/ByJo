//
//  EditAssetOperationView.swift
//  ByJo
//
//  Created by Giuseppe Cosenza on 05/11/24.
//

import SwiftUI
import SwiftData
import UserNotifications

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

    @State private var showUpdateScopeDialog = false
    @State private var pendingAmount: Decimal = 0

    private var parsedAmount: Decimal? {
        guard !amountString.isEmpty else { return nil }
        let normalized = amountString.replacingOccurrences(of: ",", with: ".")
        return Decimal(string: normalized)
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
                                Text(frequencyType.rawValue)
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
                                Text(OperationType.inflow.rawValue)
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
                                Text(OperationType.outflow.rawValue)
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

                    Picker("Category", selection: $category) {
                        ForEach(categoriesOperation) { category in
                            Text(category.name)
                                .tag(category)
                        }
                    }
                    .pickerStyle(.menu)
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
                        .disabled(name.isEmpty || amountString.isEmpty)
                    } else {
                        Button {
                            save()
                        } label: {
                            Label("Save", systemImage: "checkmark")
                        }
                        .disabled(name.isEmpty || amountString.isEmpty)
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
                }
                dismiss()
            }
            Button("Update all occurrences") {
                if let op = operation {
                    applyChangesToAll(to: op, amount: pendingAmount)
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

                if operation.asset == nil {
                    operation.asset = asset
                }

                if operation.category == nil {
                    operation.category = category
                }
            }

            if let firstAsset = assets.first {
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
