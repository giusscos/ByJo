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
    @Query var assets: [Asset]
    
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
        ScrollView {
            Text("Assets")
                .font(.largeTitle)
                .bold()
                .frame(maxWidth: .infinity, alignment: .topLeading)
            
            if assets.isEmpty {
                ContentUnavailableView(
                    "No Assets Found",
                    systemImage: "exclamationmark",
                    description: Text("You need to add an asset by selecting the Assets tab and tapping the plus button on the top right corner")
                )
            } else {
                VStack(alignment: .leading, spacing: 16) {
                    if let totalAmount = totalAmountAsset {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Total Balance")
                                .foregroundStyle(.secondary)
                            Text(totalAmount, format: .currency(code: assets.first!.currency.rawValue))
                                .font(.title3)
                                .bold()
                                .foregroundStyle(Color.accentColor)
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        if let asset = topAsset {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Top Asset")
                                    .foregroundStyle(.secondary)
                                HStack {
                                    Text(asset.name)
                                        .bold()
                                    Text(asset.calculateCurrentBalance(), format: .currency(code: asset.currency.rawValue))
                                        .bold()
                                        .foregroundStyle(Color.accentColor)
                                }
                            }
                        }
                        
                        if let asset = worseAsset {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Lowest Asset")
                                    .foregroundStyle(.secondary)
                                HStack {
                                    Text(asset.name)
                                        .bold()
                                    Text(asset.calculateCurrentBalance(), format: .currency(code: asset.currency.rawValue))
                                        .bold()
                                        .foregroundStyle(Color.red)
                                }
                            }
                        }
                    }
                    .font(.subheadline)
                    
                    Chart(assets) { value in
                        BarMark(
                            x: .value("Asset", value.name),
                            y: .value("Amount", value.calculateCurrentBalance())
                        )
                        .foregroundStyle(by: .value("Asset", value.name))
                        .cornerRadius(8)
                    }
                    .chartLegend(.visible)
                    .chartYAxis {
                        AxisMarks(position: .leading)
                    }
                    .frame(height: 300)
                    .padding(.vertical, 8)
                }
                .padding(.top)
            }
        }
        .padding()
    }
}

#Preview {
    AssetChartDetailView()
}
