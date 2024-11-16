//
//  AssetOperationRow.swift
//  ByJo
//
//  Created by Giuseppe Cosenza on 08/11/24.
//

import SwiftUI

struct AssetOperationRow: View {
    var operation: AssetOperation
    
    var body: some View {
        HStack (alignment: .center) {
            VStack (alignment: .leading, spacing: 8) {
                Text(operation.name)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .lineLimit(1)
                
                if let category = operation.category {
                    Text(category.name)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
//                Text(operation.date, format: .dateTime.day().month().year())
//                    .font(.caption2)
//                    .foregroundStyle(.secondary)
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
    AssetOperationRow(operation:
                        AssetOperation(
                            name: "Shopping",
                            date: .now,
                            amount: 100.0,
                            asset: Asset(name: "Cash", initialBalance: 10000)
                        )
    )
}
