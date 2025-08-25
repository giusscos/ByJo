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
    
    var body: some View {
        ForEach(filteredAndSortedOperations) { item in
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
                            
                            Button {
                                activeSheet = .edit(operation)
                            } label: {
                                Label("Edit", systemImage: "pencil")
                            }
                            .tint(.blue)
                        }
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
    
    private func deleteOperation(operation: AssetOperation) {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [operation.id.uuidString])
        
        modelContext.delete(operation)
    }
}

#Preview {
    OperationByDateSectionView(filteredAndSortedOperations: [], activeSheet: .constant(nil))
}
