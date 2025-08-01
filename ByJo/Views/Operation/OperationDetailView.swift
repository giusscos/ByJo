//
//  OperationDetailView.swift
//  ByJo
//
//  Created by Giuseppe Cosenza on 05/11/24.
//

import SwiftData
import SwiftUI

struct OperationDetailView: View {
    @Environment(\.modelContext) var modelContext
    
    var operation: AssetOperation
    var asset: Asset
    
    @State var showEditSheet: Bool = false
    
    var body: some View {
        List {
            Section {
                Text(operation.name)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("\(asset.name)")
                    .font(.headline)
                    .foregroundStyle(.secondary)
                
                Text(operation.date, format: .dateTime.day().month().year().hour().minute())
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            if !operation.note.isEmpty {
                Section {
                    VStack (alignment: .leading) {
                        Text("Note: ")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        Text(operation.note)
                            .font(.body)
                            .multilineTextAlignment(.center)
                    }
                }
            }
        }
        .navigationTitle(Text(operation.amount, format: .currency(code: asset.currency.rawValue)))
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showEditSheet = true
                } label: {
                    Label("Edit", systemImage: "pencil")
                }
            }
        }
        .sheet(isPresented: $showEditSheet, content: {
            if let category = operation.category {
                EditAssetOperationView(operation: operation, asset: asset, category: category)
            }
        })
    }
}

#Preview {
    OperationDetailView(
        operation: AssetOperation(date: .now, amount: 100.0),
        asset: Asset(name: "BuddyBank", initialBalance: 10000.0)
    )
}
