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
            
            VStack (alignment: .leading, spacing: 0) {
                if let asset = topAsset {
                    Text("Top asset: ")
                    + Text(asset.name)
                        .bold()
                    + Text(" with ")
                    + Text(asset.calculateCurrentBalance(), format: .currency(code: asset.currency.rawValue))
                        .bold()
                }
                
                if let asset = worseAsset {
                    Text("Worse asset: ")
                    + Text(asset.name)
                        .bold()
                    + Text(" with ")
                    + Text(asset.calculateCurrentBalance(), format: .currency(code: asset.currency.rawValue))
                        .bold()
                }
            }
            .frame(maxWidth: .infinity, alignment: .topLeading)
            .font(.subheadline)
            .foregroundStyle(.secondary)
            
            Chart(assets) { value in
                BarMark(
                    x: .value("Asset", value.name),
                    y: .value("Amount", value.calculateCurrentBalance())
                )
                .foregroundStyle(by: .value("Asset", value.name))
                .cornerRadius(4)
            }
            .aspectRatio(1, contentMode: .fit)
        }.padding()
    }
}

#Preview {
    AssetChartDetailView()
}
