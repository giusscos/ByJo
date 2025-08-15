//
//  NetWorthWidgetView.swift
//  ByJo
//
//  Created by Giuseppe Cosenza on 15/08/25.
//

import SwiftData
import SwiftUI

struct NetWorthWidgetView: View {
    @AppStorage("currencyCode") var currencyCode: CurrencyCode = .usd
    @AppStorage("compactNumber") var compactNumber: Bool = true
    
    @Query var assets: [Asset]
    
    var netWorth: Decimal {
        var netWorth: Decimal = 0.0
        
        for asset in assets {
            netWorth += asset.calculateCurrentBalance()
        }
        
        return netWorth
    }
    
    var body: some View {
        Section {
            VStack (alignment: .leading) {
                Text("Net worth")
                    .font(.headline)
                    .foregroundStyle(.secondary)
                
                Text(netWorth, format: compactNumber ? .currency(code: currencyCode.rawValue).notation(.compactName) : .currency(code: currencyCode.rawValue))
                    .contentTransition(.numericText(value: compactNumber ? 0 : 1))
                    .font(.title)
                    .fontWeight(.semibold)
            }
        }
    }
}

#Preview {
    NetWorthWidgetView()
}
