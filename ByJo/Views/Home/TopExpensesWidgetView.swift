//
//  TopExpensesWidgetView.swift
//  ByJo
//

import SwiftData
import SwiftUI

struct TopExpensesWidgetView: View {
    @AppStorage("currencyCode") var currencyCode: CurrencyCode = .usd
    @AppStorage("compactNumber") var compactNumber: Bool = true

    @Query var assets: [Asset]

    private var topExpenses: [AssetOperation] {
        let range = DateRangeOption.month.dateRange
        let filtered = assets
            .flatMap { $0.operations ?? [] }
            .filter { $0.date >= range.startDate && $0.date <= range.endDate && $0.amount < 0 }
        let sorted = filtered.sorted { (a: AssetOperation, b: AssetOperation) -> Bool in
            let absA: Decimal = a.amount < 0 ? -a.amount : a.amount
            let absB: Decimal = b.amount < 0 ? -b.amount : b.amount
            return absA > absB
        }
        return Array(sorted.prefix(3))
    }

    private var maxExpense: Double {
        guard let first = topExpenses.first else { return 1 }
        return abs(NSDecimalNumber(decimal: first.amount).doubleValue)
    }

    var body: some View {
        if !assets.isEmpty && !topExpenses.isEmpty {
            Section {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Top expenses")
                        .font(.headline)
                        .foregroundStyle(.secondary)

                    ForEach(Array(topExpenses.enumerated()), id: \.offset) { index, op in
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text(op.name)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .lineLimit(1)

                                Spacer()

                                Text(abs(op.amount), format: compactNumber
                                     ? .currency(code: currencyCode.rawValue).notation(.compactName)
                                     : .currency(code: currencyCode.rawValue))
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(.red)
                            }

                            GeometryReader { geo in
                                let ratio = abs(NSDecimalNumber(decimal: op.amount).doubleValue) / maxExpense
                                Capsule()
                                    .fill(Color.red.opacity(0.8 - Double(index) * 0.2))
                                    .frame(width: max(0, geo.size.width * ratio), height: 6)
                                    .animation(.spring(response: 0.6, dampingFraction: 0.8), value: ratio)
                            }
                            .frame(height: 6)
                        }
                    }
                }
                .padding(.vertical, 8)
            }
        }
    }
}

#Preview {
    TopExpensesWidgetView()
}
