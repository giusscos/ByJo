//
//  OperationRow.swift
//  ByJo
//
//  Created by Giuseppe Cosenza on 05/11/24.
//

import SwiftUI

struct OperationRow: View {
    @AppStorage("currencyCode") var currency: CurrencyCode = .usd
    @AppStorage("compactNumber") var compactNumber: Bool = true
    
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var operation: AssetOperation
    
    var body: some View {
        AdaptiveStack(spacing: 6) {
            VStack (alignment: .leading) {                
                Text(operation.name)
                    .font(.title3)
                    .fontWeight(.semibold)

                HStack (alignment: .lastTextBaseline, spacing: 4) {
                    Text(operation.date, format: .dateTime.hour().minute())

                    if let asset = operation.asset {
                        Text("on")
                        
                        Text(asset.name)
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
            .lineLimit(dynamicTypeSize.isAccessibilitySize ? 3 : 1)
            
            Spacer(minLength: 0)

            HStack(spacing: 6) {
                Group {
                    if operation.swapId != nil {
                        Image(systemName: "arrow.left.arrow.right.circle.fill")
                            .foregroundStyle(.blue)
                    } else if operation.amount > 0 {
                        Image(systemName: "arrow.up.circle.fill")
                            .foregroundStyle(Color.rise)
                    } else {
                        Image(systemName: "arrow.down.circle.fill")
                            .foregroundStyle(Color.fall)
                    }
                }
                .imageScale(.large)
                .fontWeight(.semibold)
            
                Text(operation.amount < 0 ? operation.amount * -1 : operation.amount, format: compactNumber ? .currency(code: currency.rawValue).notation(.compactName) : .currency(code: currency.rawValue))
                    .font(.title)
                    .fontWeight(.semibold)
                    .contentTransition(.numericText(value: compactNumber ? 0 : 1))
                    .lineLimit(1)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(operation.name))
        .accessibilityValue(Text(verbatim: accessibilityValue))
    }

    /// "Outflow, $12.50, 9:41 AM, BuddyBank": the direction the arrow shows, then the details.
    private var accessibilityValue: String {
        let kind = NSLocalizedString(operation.swapId != nil ? "Swap" : (operation.amount > 0 ? "Inflow" : "Outflow"), comment: "")
        var parts = [kind, abs(operation.amount).accessibilityCurrency(currency), operation.date.formatted(.dateTime.hour().minute())]
        if let asset = operation.asset { parts.append(asset.name) }
        return parts.joined(separator: ", ")
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
    )
}
