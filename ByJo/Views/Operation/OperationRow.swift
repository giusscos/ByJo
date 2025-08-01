//
//  OperationRow.swift
//  ByJo
//
//  Created by Giuseppe Cosenza on 05/11/24.
//

import SwiftUI

struct OperationRow: View {
    var operation: AssetOperation
    var asset: Asset
    
    var body: some View {
        HStack (spacing: 6) {
            VStack (alignment: .leading) {                
                Text(operation.name)
                    .font(.title3)
                    .fontWeight(.semibold)

                HStack (alignment: .lastTextBaseline) {
                    Text(operation.date, format: .dateTime.hour().minute())
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    
                    HStack (spacing: 6) {
                        Text("on")

                        Text(asset.name)
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
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
            
            Text(operation.amount, format: .currency(code: asset.currency.rawValue).notation(.compactName))
                .font(.title)
                .fontWeight(.semibold)
        }
    }
}

#Preview {
    OperationRow(operation:
        AssetOperation(
            name: "🚗 Transport",
            date: .now,
            amount: 1000.0,
            asset: Asset(name: "BuddyBank", initialBalance: 10000.0),
            category: CategoryOperation(name: "Bank Accouunt")
        ),
         asset: Asset(name: "BuddyBank", initialBalance: 10000.0)
    )
}
