//
//  OperationByDateSectionView.swift
//  ByJo
//
//  Created by Giuseppe Cosenza on 25/08/25.
//

import SwiftData
import SwiftUI

struct OperationByDateSectionView: View {
    @Environment(\.modelContext) var modelContext
    
    var filteredAndSortedOperations: [OperationByDate]
    
    @Binding var activeSheet: OperationListViewSheet?
    
    @Query var allOperations: [AssetOperation]
    
    func linkedOperation(for operation: AssetOperation) -> AssetOperation? {
        guard let swapId = operation.swapId else { return nil }
        return allOperations.first(where: { $0.id != operation.id && $0.swapId == swapId })
    }
    
    var body: some View {
        ForEach(filteredAndSortedOperations) { item in
            Section {
                ForEach(item.operations) { operation in
                    let linked = linkedOperation(for: operation)
                    NavigationLink {
                        OperationDetailView(operation: operation, linkedOperation: linked)
                    } label: {
                        OperationRow(operation: operation)
                    }
                    .tag(operation)
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                            deleteOperation(operation: operation, linkedOperation: linked)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                        
                        Button {
                            activeSheet = .edit(operation)
                        } label: {
                            Label("Edit", systemImage: "pencil")
                        }
                        .tint(.blue)
                    }
                }
            } header: {
                Text(item.date.formatted(.dateTime.day().month().year()))
                    .headerProminence(.increased)
            } footer: {
                Text("\(item.operations.count) Operation\(item.operations.count != 1 ? "s" : "")")
            }
        }
    }
    
    private func deleteOperation(operation: AssetOperation, linkedOperation: AssetOperation?) {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [operation.id.uuidString])
        
        withAnimation {
            if let linkedOperation = linkedOperation {
                modelContext.delete(linkedOperation)
            }
            modelContext.delete(operation)
        }
    }
}

#Preview {
    OperationByDateSectionView(filteredAndSortedOperations: [], activeSheet: .constant(nil))
}
