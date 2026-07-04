//
//  FinancialSummaryWidgetView.swift
//  ByJo
//

import SwiftData
import SwiftUI

struct FinancialSummaryWidgetView: View {
    @AppStorage("currencyCode") var currencyCode: CurrencyCode = .usd
    @AppStorage("compactNumber") var compactNumber: Bool = true

    @Query var assets: [Asset]

    private var allOperations: [AssetOperation] {
        assets.flatMap { $0.operations ?? [] }
    }

    var netChangeThisMonth: Decimal {
        let range = DateRangeOption.month.dateRange
        return allOperations
            .filter { $0.date >= range.startDate && $0.date <= range.endDate }
            .reduce(Decimal(0)) { $0 + $1.amount }
    }

    var body: some View {
        Section {
            VStack(alignment: .leading, spacing: 4) {
                Text("This month")
                    .font(.headline)
                    .foregroundStyle(.secondary)

                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    if netChangeThisMonth > 0 {
                        Text("+")
                            .font(.system(size: 40, weight: .black, design: .rounded))
                            .foregroundStyle(.green)
                    }

                    Text(netChangeThisMonth, format: compactNumber
                         ? .currency(code: currencyCode.rawValue).notation(.compactName)
                         : .currency(code: currencyCode.rawValue))
                        .font(.system(size: 40, weight: .black, design: .rounded))
                        .foregroundStyle(netChangeThisMonth >= 0 ? Color.green : Color.red)
                        .contentTransition(.numericText(value: Double(truncating: netChangeThisMonth as NSDecimalNumber)))
                }
            }
            .padding(.vertical, 8)
        }
    }
}

#Preview {
    FinancialSummaryWidgetView()
}
