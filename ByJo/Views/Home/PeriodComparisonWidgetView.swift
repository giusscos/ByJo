//
//  PeriodComparisonWidgetView.swift
//  ByJo
//
//  Created by Giuseppe Cosenza on 10/08/25.
//

import SwiftData
import SwiftUI

struct NetWorthComparison {
    var amount: Decimal
    var percentage: Decimal
}

struct PeriodComparisonWidgetView: View {
    @Query var assets: [Asset]
    
    @AppStorage("currencyCode") var currencyCode: CurrencyCode = .usd
    @AppStorage("compactNumber") var compactNumber: Bool = true
    
    var netWorth: Decimal {
        var netWorth: Decimal = 0.0
        
        for asset in assets {
            netWorth += asset.calculateCurrentBalance()
        }
        
        return netWorth
    }
    
    var netWorthPreviousPeriod: NetWorthComparison {
        var balancePreviousPeriod: Decimal = 0.0
        var balanceCurrentPeriod: Decimal = 0.0
        
        let period: DateRangeOption = .month
        
        for asset in assets {
            balancePreviousPeriod += asset.calculatePreviousBalanceForDateRangeWithoutInitialBalance(period)
            balanceCurrentPeriod += asset.calculateBalanceForDateRangeWithoutInitialBalance(period)
        }
        
        let amount = balancePreviousPeriod + balanceCurrentPeriod
        
        return NetWorthComparison(amount: amount, percentage: amount == 0 ? 0 : (amount / (netWorth - amount)) * 100)
    }
    
    var body: some View {
        if !assets.isEmpty {
            Section {
                VStack (alignment: .leading, spacing: 24) {
                    HStack (spacing: 4) {
                        Text("VS last month")
                    }
                    .font(.headline)
                    .foregroundStyle(.secondary)
                    
                    HStack (spacing: 4) {
                        Group {
                            if netWorthPreviousPeriod.amount > 0 {
                                Image(systemName: "arrow.up.circle.fill")
                                    .foregroundStyle(.green)
                            } else if netWorthPreviousPeriod.amount == 0 {
                                Image(systemName: "equal.circle.fill")
                                    .foregroundStyle(.gray)
                            } else {
                                Image(systemName: "arrow.down.circle.fill")
                                    .foregroundStyle(.red)
                            }
                            
                        }
                        .imageScale(.large)
                        .fontWeight(.semibold)
                        
                        HStack (alignment: .lastTextBaseline) {
                            Text(abs(netWorthPreviousPeriod.amount), format: compactNumber ? .currency(code: currencyCode.rawValue).notation(.compactName) : .currency(code: currencyCode.rawValue))
                                .font(.title)
                                .fontWeight(.semibold)
                                .contentTransition(.numericText(value: compactNumber ? 0 : 1))
                            
                            Group {
                                Text("(")
                                +
                                Text(netWorthPreviousPeriod.percentage, format: .number.precision(.fractionLength(2)))
                                +
                                Text("%)")
                            }
                            .font(.headline)
                            .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
    }
}

#Preview {
    PeriodComparisonWidgetView()
}
