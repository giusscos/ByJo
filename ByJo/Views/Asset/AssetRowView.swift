//
//  AssetRowView.swift
//  ByJo
//
//  Created by Giuseppe Cosenza on 31/07/25.
//

import SwiftUI

struct AssetRowView: View {
    @AppStorage("currencyCode") var currency: CurrencyCode = .usd
    @AppStorage("compactNumber") var compactNumber: Bool = true
    
    var asset: Asset
    
    var body: some View {
        HStack (alignment: .center) {
            VStack (alignment: .leading, spacing: 0) {
                Text(asset.type.rawValue)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Text(asset.name)
                    .lineLimit(1)
                    .font(.title2)
                    .fontWeight(.semibold)
            }
            
            Spacer()
            
            Text(asset.calculateCurrentBalance(), format: compactNumber ? .currency(code: currency.rawValue).notation(.compactName) : .currency(code: currency.rawValue))
                .lineLimit(1)
                .truncationMode(.middle)
                .font(.title)
                .fontWeight(.semibold)
                .contentTransition(.numericText(value: compactNumber ? 0 : 1))
        }
    }
}

#Preview {
    AssetRowView(asset: Asset(name: "Bank", initialBalance: 100.0))
}
