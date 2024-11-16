//
//  AssetOperationView.swift
//  ByJo
//
//  Created by Giuseppe Cosenza on 05/11/24.
//

import SwiftUI
import SwiftData

struct AssetOperationView: View {
    @Environment(\.modelContext) var modelContext
        
    var operations: [AssetOperation]
    
    @State var selectedOperation: AssetOperation?
    
    var dateBasedOperations: [OperationByDate] {
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
        ForEach(dateBasedOperations) { item in
            Section {
                ForEach(item.operations) { value in
                    NavigationLink {
                        OperationDetailView(operation: value)
                    } label: {
                        AssetOperationRow(operation: value)
                    }
                    .swipeActions (edge: .trailing) {
                        Button (role: .destructive) {
                            modelContext.delete(value)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                        
                        Button {
                            selectedOperation = value
                        } label: {
                            Label("Edit", systemImage: "pencil")
                        }.tint(.blue)
                    }
                }
            } header: {
                Text(item.date.formatted(.dateTime.day().month().year()))
                    .headerProminence(.increased)
            }
        }
        .sheet(item: $selectedOperation) { value in
            EditAssetOperation(operation: value)
                .presentationDragIndicator(.visible)
            }
    }
}

#Preview {
    AssetOperationView(operations: [])
}
