//
//  RecurringOperationWidgetView.swift
//  ByJo
//
//  Created by Giuseppe Cosenza on 09/08/25.
//

import SwiftData
import SwiftUI

struct RecurringOperationWidgetView: View {
    @AppStorage("currencyCode") var currencyCode: CurrencyCode = .usd
    @AppStorage("compactNumber") var compactNumber: Bool = true

    @Query(sort: \AssetOperation.date, order: .reverse) var operations: [AssetOperation]

    @State var toAddOperations: [AssetOperation] = []
    
    @State private var showRecurringAlert = false
    
    var body: some View {
        if let recurringOperation = operations.first(where: { operation in
            operation.frequency != .single
        }) {
            Section {
                VStack (alignment: .leading, spacing: 24) {
                    NavigationLink {
                        RecurringOperationListView()
                    } label: {
                        Text("Recurring operation")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                    }
                    
                    VStack (alignment: .leading) {
                        Text(recurringOperation.name)
                            .font(.title3)
                            .fontWeight(.semibold)
                            .lineLimit(1)
                        
                        HStack (alignment: .lastTextBaseline) {
                            HStack (spacing: 4) {
                                Group {
                                    if recurringOperation.amount > 0 {
                                        Image(systemName: "arrow.up.circle.fill")
                                            .foregroundStyle(.green)
                                    } else if recurringOperation.amount == 0 {
                                        Image(systemName: "equal.circle.fill")
                                            .foregroundStyle(.gray)
                                    } else {
                                        Image(systemName: "arrow.down.circle.fill")
                                            .foregroundStyle(.red)
                                    }
                                    
                                }
                                .imageScale(.large)
                                .fontWeight(.semibold)
                                
                                Text(abs(recurringOperation.amount), format: compactNumber ? .currency(code: currencyCode.rawValue).notation(.compactName) : .currency(code: currencyCode.rawValue))
                                    .font(.title)
                                    .fontWeight(.semibold)
                                    .contentTransition(.numericText(value: compactNumber ? 0 : 1))
                            }
                            
                            Spacer()
                            
                            if let nextPaymentDate = recurringOperation.frequency.nextPaymentDate(from: recurringOperation.date) {
                                Text(nextPaymentDate, format: .dateTime.day().month(.abbreviated).year(.twoDigits).hour().minute())
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
            .onAppear() {
                processRecurringOperations()
            }
            .alert("New recurring \(toAddOperations.count == 1 ? "operation" : "operations")", isPresented: $showRecurringAlert) {
                Button("Continue", role: .cancel) {}
            } message: {
                Text("\(toAddOperations.count) new \(toAddOperations.count == 1 ? "operation" : "operations") will be added to your operations list.")
            }
        }
    }
    
    func processRecurringOperations() {
        toAddOperations.removeAll()
        
        let recurringOperations = operations.filter {
            $0.frequency != RecurrenceFrequency.single
        }
        
        for operation in recurringOperations {
            if let category = operation.category {
                let nextDate = operation.frequency.nextPaymentDate(from: operation.date)
                
                if let dueDate = nextDate, dueDate <= Date() {
                    let alreadyExists = operations.contains {
                        $0.name == operation.name && $0.date == dueDate
                    }
                    
                    if !alreadyExists {
                        let newOperation = AssetOperation(
                            id: UUID(),
                            name: operation.name,
                            date: dueDate,
                            amount: operation.amount,
                            asset: operation.asset,
                            category: category,
                            note: operation.note,
                            frequency: operation.frequency
                        )
                        
                        toAddOperations.append(newOperation)
                        
                        scheduleNotification(operation: newOperation)
                    }
                }
            }
        }
        
        if !toAddOperations.isEmpty {
            showRecurringAlert = true
        }
    }
    
    private func scheduleNotification(operation: AssetOperation) {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [operation.id.uuidString])
        
        let content = UNMutableNotificationContent()
        content.title = "Recurring operation"
        
        content.subtitle = "\(operation.name) \(operation.amount.formatted(.currency(code: currencyCode.rawValue).notation(.compactName)))"
        
        if let nextDate = operation.frequency.nextPaymentDate(from: operation.date) {
            let triggerDate = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: nextDate)
            
            let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: false)
            
            let request = UNNotificationRequest(identifier: operation.id.uuidString, content: content, trigger: trigger)
            
            UNUserNotificationCenter.current().add(request)
            
            return
        }
    }
}

#Preview {
    RecurringOperationWidgetView()
}
