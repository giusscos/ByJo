//
//  AssetDetailView.swift
//  ByJo
//
//  Created by Giuseppe Cosenza on 04/11/24.
//

import SwiftUI
import SwiftData
import Charts

struct AssetDetailView: View {
    @Environment(\.modelContext) var modelContext
    
    var asset: Asset

    @Query(filter: #Predicate<AssetOperation> { value in
        value.name != "" || value.amount != 0.0
    }, sort: \AssetOperation.date, order: .reverse) var operations: [AssetOperation]
    
    @State var selectedOperation: AssetOperation?
    
    var assetOperation: [AssetOperation]? {
        operations.filter { $0.asset == asset }
    }
    
    var body: some View {
        NavigationStack {
            if assetOperation == [] {
                ContentUnavailableView("No operations yet", systemImage: "exclamationmark", description: Text("You need to add operations to this asset to see them here."))
            } else {
                if let operations = assetOperation {
                    List {
                        Chart(operations) { value in
                            LineMark(
                                x: .value("Date", value.date),
                                y: .value("Amount", value.amount)
                            )
                            .symbol(.square)
                            .symbolSize(30)
                        }
                        .aspectRatio(1, contentMode: .fit)
                        .listRowBackground(Color.clear)
                        
                        AssetOperationView(operations: operations)
                    }
                }
            }
        }
        .navigationTitle(asset.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    addOperation()
                } label: {
                    Label("Add operation", systemImage: "plus")
                }
            }
        }
        .sheet(item: $selectedOperation) { value in
            EditAssetOperation(operation: value)
        }
    }
    
    func addOperation(){
        let operation = AssetOperation(currency: asset.currency, asset: asset)
        selectedOperation = operation
        modelContext.insert(operation)
    }
}

#Preview {
    AssetDetailView(asset: Asset(name: "Cash", initialBalance: 0))
}
