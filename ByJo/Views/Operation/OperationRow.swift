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
            VStack (alignment: .leading, spacing: 0) {
                Text(operation.name)
                    .font(.title3)
                    .fontWeight(.semibold)

                HStack {
                    if let asset = operation.asset {
                        Text(asset.name)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            
                        Divider()
                    }
                    
                    if let category = operation.category {
                        Text(category.name)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        Divider()
                    }
                    
                    Text(operation.date, format: .dateTime.day().month().year())
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }.lineLimit(1)
            .padding(.top, 4)
            .frame(maxWidth: .infinity, alignment: .leading)
            
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
