//
//  OperationRow.swift
//  ByJo
//
//  Created by Giuseppe Cosenza on 05/11/24.
//

import SwiftUI

struct OperationRow: View {
    var operation: AssetOperation
    
    var body: some View {
        HStack (alignment: .center) {
            VStack (alignment: .leading, spacing: 8) {
                Text(operation.name)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .lineLimit(1)

                HStack {
                    if let asset = operation.asset {
                        Text(asset.name)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.accentColor)
                            .foregroundStyle(.white)
                            .fontWeight(.semibold)
                            .clipShape(Capsule())
                    }
                    
                    Text(operation.date, format: .dateTime.day().month().year())
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }.frame(maxWidth: .infinity, alignment: .leading)
            
            HStack {
                Text(operation.amount, format: .currency(code: operation.currency.rawValue))
                    .foregroundStyle(operation.amount > 0 ? .green : .red)
                    .font(.title2)
                    .fontWeight(.semibold)
            }
        }
    }
}

#Preview {
    OperationRow(operation:
        AssetOperation(
            name: "Shopping",
            date: .now,
            amount: 100.0,
            asset: Asset(name: "Cash", initialBalance: 10000)
        )
    )
}
