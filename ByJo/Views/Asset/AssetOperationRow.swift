//
//  AssetOperationRow.swift
//  ByJo
//
//  Created by Giuseppe Cosenza on 08/11/24.
//

import SwiftUI

struct AssetOperationRow: View {
    @AppStorage("currencyCode") var currencyCode: CurrencyCode = .usd

    var operation: AssetOperation
    
    var body: some View {
        HStack (spacing: 6) {
            VStack (alignment: .leading) {
                Text(operation.name)
                    .font(.title3)
                    .fontWeight(.semibold)
                
                Text(operation.date, format: .dateTime.hour().minute())
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .lineLimit(1)
            
            Spacer()
            
            Group {
                if operation.amount > 0 {
                    Image(systemName: "arrow.up.circle.fill")
                        .foregroundStyle(.green)
                } else {
                    Image(systemName: "arrow.down.circle.fill")
                        .foregroundStyle(.red)
                }
            }
            .imageScale(.large)
            .fontWeight(.semibold)
            
            Text(operation.amount < 0 ? operation.amount * -1 : operation.amount, format: .currency(code: currencyCode.rawValue).notation(.compactName))
                .font(.title)
                .fontWeight(.semibold)
                .lineLimit(1)
        }
    }
}

#Preview {
    AssetOperationRow(
        operation:
            AssetOperation(
                name: "Shopping",
                date: .now,
                amount: 100.0,
                asset: Asset(name: "Cash", initialBalance: 10000.0)
            ),
    )
}
