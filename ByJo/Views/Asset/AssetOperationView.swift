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
    
    var body: some View {
        Section { 
            ForEach(operations) { value in
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
