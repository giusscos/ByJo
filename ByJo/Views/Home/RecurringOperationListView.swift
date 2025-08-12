//
//  RecurringOperationListView.swift
//  ByJo
//
//  Created by Giuseppe Cosenza on 08/08/25.
//

import SwiftData
import SwiftUI

struct RecurringOperationListView: View {
    @Environment(\.modelContext) var modelContext
    
    @Query var operations: [AssetOperation]
    
    var filteredOperations: [OperationByDate] {
        let filteredOperations = operations.filter({ operation in operation.frequency != .single })
        
        return groupOperationsByDate(filteredOperations)
    }
    
    func groupOperationsByDate(_ operations: [AssetOperation]) -> [OperationByDate] {
        let calendar = Calendar.current
        let normalizedOperations = operations.map { operation -> (Date, AssetOperation) in
            let components = calendar.dateComponents([.year, .month, .day], from: operation.date)
            let normalizedDate = calendar.date(from: components)!
            return (normalizedDate, operation)
        }
        
        let groupedDict = Dictionary(grouping: normalizedOperations) { $0.0 }
        
        return groupedDict.map { (date, operationPairs) in
            OperationByDate(date: date, operations: operationPairs.map { $0.1 })
        }.sorted { $0.date > $1.date }
    }
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(filteredOperations) { item in
                    Section {
                        ForEach(item.operations) { operation in
                            if let asset = operation.asset {
                                NavigationLink {
                                    OperationDetailView(operation: operation, asset: asset)
                                } label: {
                                    OperationRow(operation: operation, asset: asset)
                                }
                                .tag(operation)
                                .swipeActions(edge: .trailing) {
                                    Button(role: .destructive) {
                                        deleteOperation(operation: operation)
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                            }
                        }
                    } header: {
                        Text(item.date.formatted(.dateTime.day().month().year()))
                            .headerProminence(.increased)
                    }
                }
            }
            .navigationTitle("Recurring Operations")
        }
    }
    
    private func deleteOperation(operation: AssetOperation) {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [operation.id.uuidString])
        
        modelContext.delete(operation)
    }
}

#Preview {
    RecurringOperationListView()
}
