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

    @Query(sort: \AssetOperation.date, order: .reverse) var operations: [AssetOperation]
    
    @State private var dateRange: DateRangeOption = .month
    
    @State var selectedOperation: AssetOperation?
    
    var assetOperation: [AssetOperation]? {
        operations.filter { $0.asset == asset }
    }
    
    var incomeData: [AssetOperation] {
        if let operationsAsset = assetOperation {
            return filterData(for: dateRange, data: operationsAsset.filter { $0.amount > 0.0 })
        } else {
            return []
        }
    }
    
    var outcomeData: [AssetOperation] {
        if let operationsAsset = assetOperation {
            return filterData(for: dateRange, data: operationsAsset.filter { $0.amount < 0.0 })
        } else {
            return []
        }
    }
    
    var operationsData: [OperationDataType] {
        [OperationDataType(type: "Outcome", data: outcomeData),
         OperationDataType(type: "Income", data: incomeData)]
    }
    
    var body: some View {
        NavigationStack {
            if assetOperation == [] {
                ContentUnavailableView("No operations yet", systemImage: "exclamationmark", description: Text("You need to add operations to this asset to see them here."))
            } else {
                if let operations = assetOperation {
                    List {
                        Picker("Date Range", selection: $dateRange.animation()) {
                            ForEach(DateRangeOption.allCases) { range in
                                Text(range.rawValue).tag(range)
                            }
                        }
                        .pickerStyle(.segmented)
                        .listRowBackground(Color.clear)
                        
                        Chart (operationsData) { operation in
                            ForEach(operation.data) { value in
                                PointMark(
                                    x: .value("Date", value.date),
                                    y: .value("Amount", value.amount)
                                )
                            }
                            .foregroundStyle(by: .value("Type", operation.type))
                            .symbol(by: .value("Type", operation.type))
                            .symbolSize(30)
                        }
                        .chartForegroundStyleScale([
                            "Outcome": Color.red,
                            "Income": Color.green
                        ])
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
