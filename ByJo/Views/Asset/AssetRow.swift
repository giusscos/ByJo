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
            Text(asset.icon)
                .font(.largeTitle)
                               
            VStack (alignment: .leading, spacing: 8) {
                Text(asset.name)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .lineLimit(1)
                
                Text(asset.type.rawValue)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.accentColor)
                    .foregroundStyle(.white)
                    .fontWeight(.semibold)
                    .clipShape(Capsule())
            }.frame(maxWidth: .infinity, alignment: .leading)
            
            Text(asset.calculateCurrentBalance(), format: .currency(code: asset.currency.rawValue))
                .font(.title2)
                .fontWeight(.semibold)
        }
    }
}

#Preview {
    AssetRow(asset: Asset(name: "Asset", icon: "💰", type: .cash, initialBalance: 20000))
}
