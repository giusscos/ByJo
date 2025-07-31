//
//  AssetDetailView.swift
//  ByJo
//
//  Created by Giuseppe Cosenza on 04/11/24.
//

import Charts
import SwiftData
import SwiftUI

struct AssetDetailView: View {
    @Environment(\.modelContext) var modelContext
    
    var asset: Asset

    @Query(sort: \AssetOperation.date, order: .reverse) var operations: [AssetOperation]
    
    @State private var dateRange: DateRangeOption = .all
    
    @State var selectedOperation: AssetOperation?
    
    var availableDateRanges: [DateRangeOption] {
        DateRangeOption.availableRanges(for: assetOperation ?? [])
    }
    
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
    
    var totalIncome: Decimal {
        incomeData.reduce(0) { $0 + $1.amount }
    }
    
    var totalOutcome: Decimal {
        outcomeData.reduce(0) { $0 + $1.amount }
    }
    
    var chartYScale: ClosedRange<Decimal> {
        let maxIncome = totalIncome
        let minOutcome = totalOutcome
        let buffer = max(abs(maxIncome), abs(minOutcome)) * 0.1
        
        return (minOutcome - buffer)...(maxIncome + buffer)
    }
    
    var body: some View {
        NavigationStack {
            
        }
        .navigationTitle(asset.name)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    
                } label: {
                    Label("Add operation", systemImage: "plus.circle.fill")
                }
            }
        }
        .sheet(item: $selectedOperation) { value in
            EditAssetOperation(operation: value)
        }
    }
}

#Preview {
    AssetDetailView(asset: Asset(name: "Cash", initialBalance: 0))
}
