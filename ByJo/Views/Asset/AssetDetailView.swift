//
//  AssetDetailView.swift
//  ByJo
//
//  Created by Giuseppe Cosenza on 04/11/24.
//

import SwiftUI
import Charts

struct AssetDetailView: View {
    @Environment(\.modelContext) var modelContext
    
    var asset: Asset
    
    @State var selectedOperation: AssetOperation?
            
    var body: some View {
        NavigationStack {
            if asset.operations == [] {
                ContentUnavailableView("No operations yet", systemImage: "exclamationmark", description: Text("You need to add operations to this asset to see them here."))
            } else {
                if let operations = asset.operations {
                    List {
                        Chart(operations.sorted(by: { $0.date < $1.date })) { value in
                            LineMark(
                                x: .value("Date", value.date),
                                y: .value("Amount", value.amount)
                            )
                            .foregroundStyle(by: .value("Type", value.type.rawValue))
                            
                        }
                        .frame(maxHeight: UIScreen.main.bounds.height / 3, alignment: .top)
                        .aspectRatio(16/9, contentMode: .fit)
                        .listRowBackground(Color.clear)
                        .listRowInsets(.init(top: 10, leading: 0, bottom: 0, trailing: 0))
                        
                        AssetOperationView(operations: operations.sorted(by: { $0.date > $1.date }))
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
                .presentationDragIndicator(.visible)
        }
    }
    
    func addOperation(){
        let operation = AssetOperation(name: "", currency: asset.currency, date: .now, type: .transaction, amount: 0, asset: asset)
        selectedOperation = operation
        modelContext.insert(operation)
    }
}

#Preview {
    AssetDetailView(asset: Asset(name: "Cash", initialBalance: 0))
}
