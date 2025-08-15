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
    
    @AppStorage("currencyCode") var currency: CurrencyCode = .usd
    
    @Environment(\.modelContext) var modelContext
    @Environment(\.dismiss) var dismiss
    
    @Query var assets: [Asset]
    @Query var categoriesOperation: [CategoryOperation]
    
    var operation: AssetOperation?
    
    @State private var name: String = ""
    @State private var date: Date = .now
    @State private var amount: Decimal?
    @State var asset: Asset
    @State var category: CategoryOperation
    @State private var note: String = ""
    @State private var frequency: RecurrenceFrequency = .single

    var nilAmount: Bool {
        amount == .zero || amount == nil
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
                    HStack (spacing: 6) {
                        Text(currency.symbol)
                            .foregroundStyle(nilAmount ? .secondary : .primary)
                            .opacity(nilAmount ? 0.5 : 1)
                            
                        TextField("Amount", value: $amount, format: .number.precision(.fractionLength(2)))
                            .keyboardType(.numbersAndPunctuation)
                            .focused($focusedField, equals: .amount)
                            .submitLabel(.next)
                            .onSubmit {
                                focusedField = .note
                            }
                    }
                }
                
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
                    TextEditor(text: $note)
                        .autocorrectionDisabled()
                        .overlay(alignment: .topLeading, content: {
                            if note.isEmpty {
                                Text("Insert note")
                                    .foregroundColor(.secondary.opacity(0.5))
                                    .padding(.horizontal, 2)
                                    .padding(.vertical, 8)
                            }
                        })
                        .frame(maxHeight: 256)
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
                    Button {
                        saveOperation()
                    } label: {
                        Label("Save", systemImage: "checkmark.circle")
                            .labelStyle(.titleOnly)
                    }
                    .disabled(name.isEmpty || amount == nil)
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
        .onAppear {
            focusedField = .name
            
            if let operation = operation {
                name = operation.name
                date = operation.date
                amount = operation.amount
                note = operation.note
                frequency = operation.frequency
                
                if operation.asset == nil {
                    operation.asset = asset
                }
                
                if operation.category == nil {
                    operation.category = category
                }
            }
        }
    }
    
    private func deleteOperation(operation: AssetOperation) {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [operation.id.uuidString])
        
        modelContext.delete(operation)
        
        dismiss()
    }
    
    private func saveOperation() {
        let uuid = UUID()
        
        if let operation = operation {
            operation.name = name
            operation.date = date
            operation.frequency = frequency
            
            if let amount = amount {
                operation.amount = amount
            }
            
            operation.note = note

            operation.asset = asset

            operation.category = category
            
            scheduleNotification(uuid: operation.id)
            
            dismiss()
            
            return
        }
        
        let calculatedAmount = amount ?? .zero
        
        let newOperation = AssetOperation(
            id: uuid,
            name: name,
            date: date,
            amount: calculatedAmount,
            asset: asset,
            category: category,
            note: note,
            frequency: frequency
        )
        
        modelContext.insert(newOperation)

        scheduleNotification(uuid: newOperation.id)
        
        dismiss()
    }
    
    private func scheduleNotification(uuid: UUID) {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [uuid.uuidString])
        
        let content = UNMutableNotificationContent()
        content.title = "Recurring operation"
        if let amount = amount {
            content.subtitle = "\(name) \(amount.formatted(.currency(code: currency.rawValue).notation(.compactName)))"
        } else {
            content.subtitle = name
        }
                
        let triggerDate = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: false)
        
        let request = UNNotificationRequest(identifier: uuid.uuidString, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request)
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
        asset: Asset(name: "Bank", initialBalance: 100.0),
        category: CategoryOperation(name: "Bank account")
    )
}
