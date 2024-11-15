//
//  AssetRow.swift
//  ByJo
//
//  Created by Giuseppe Cosenza on 04/11/24.
//

import SwiftUI

struct AssetRow: View {
    var asset: Asset
    
    var body: some View {
        HStack (alignment: .center) {
            VStack (alignment: .leading, spacing: 0) {
                Text(asset.name)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .lineLimit(1)
                
                Text(asset.type.rawValue)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fontWeight(.semibold)
            }.frame(maxWidth: .infinity, alignment: .leading)
            
            Text(asset.calculateCurrentBalance(), format: .currency(code: asset.currency.rawValue))
                .font(.title2)
                .fontWeight(.semibold)
        }
    }
}

#Preview {
    AssetRow(asset: Asset(name: "Asset", type: .cash, initialBalance: 20000))
}
