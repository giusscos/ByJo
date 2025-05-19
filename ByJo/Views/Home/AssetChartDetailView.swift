//
//  AssetChartDetailView.swift
//  ByJo
//
//  Created by Giuseppe Cosenza on 15/11/24.
//

import SwiftUI
import SwiftData
import Charts

struct AssetChartDetailView: View {
    @Environment(\.modelContext) var modelContext
    @Query var assets: [Asset]
    @Query(sort: \AssetOperation.date, order: .reverse) var operations: [AssetOperation]
    
    @State private var dateRange: DateRangeOption = .all
    @AppStorage("showingChartLabels") private var showingChartLabels = true
    
    var availableDateRanges: [DateRangeOption] {
        DateRangeOption.availableRanges(for: operations)
    }
    
    var totalAmountAsset: Decimal? {
        assets.reduce(0) { $0 + $1.calculateCurrentBalance() }
    }
    
    var topAsset: Asset? {
        assets.max { $0.calculateCurrentBalance() < $1.calculateCurrentBalance() }
    }
    
    var worseAsset: Asset? {
        assets.max { $0.calculateCurrentBalance() > $1.calculateCurrentBalance() }
    }
        
    var body: some View {
        VStack(spacing: 16) {
            Picker("Date Range", selection: $dateRange.animation().animation(.spring())) {
                ForEach(availableDateRanges) { range in
                    Text(range.label)
                        .tag(range)
                }
            }
            .pickerStyle(.segmented)
            
            AssetsOverviewChart(
                assets: assets,
                operations: operations,
                showingChartLabels: true,
                dateRange: dateRange
            )
        }
        .frame(maxHeight: .infinity, alignment: .top)
        .padding()
        .navigationTitle("Assets Overview")
    }
}

#Preview {
    AssetChartDetailView()
}
