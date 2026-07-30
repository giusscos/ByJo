//
//  SpendingTrendsWidgetView.swift
//  ByJo
//

import Charts
import SwiftData
import SwiftUI

private struct MonthBucket: Identifiable {
    let id = UUID()
    let month: Date
    let label: String
    let amount: Double
}

struct SpendingTrendsWidgetView: View {
    @AppStorage("currencyCode") var currencyCode: CurrencyCode = .usd
    @AppStorage("compactNumber") var compactNumber: Bool = true

    @Query var assets: [Asset]

    @State private var lookback: Int = 6

    private let lookbackOptions: [(label: String, months: Int)] = [
        ("3M", 3), ("6M", 6), ("12M", 12)
    ]

    private var monthlyExpenses: [MonthBucket] {
        let calendar = Calendar.current
        let now = Date()
        let allOps = assets.flatMap { $0.operations ?? [] }

        return (0..<lookback).compactMap { offset -> MonthBucket? in
            let monthsAgo = -(lookback - 1 - offset)
            guard let monthDate = calendar.date(byAdding: .month, value: monthsAgo, to: now),
                  let start = calendar.date(from: calendar.dateComponents([.year, .month], from: monthDate)),
                  let end = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: start)
            else { return nil }

            let total = allOps
                .filter { $0.amount < 0 && $0.date >= start && $0.date <= end }
                .reduce(0.0) { $0 + abs(NSDecimalNumber(decimal: $1.amount).doubleValue) }

            return MonthBucket(
                month: start,
                label: monthDate.formatted(.dateTime.month(.abbreviated)),
                amount: total
            )
        }
    }

    private var hasData: Bool { monthlyExpenses.contains { $0.amount > 0 } }

    var body: some View {
        if hasData {
            Section {
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Text("Spending trends")
                            .font(.headline)
                            .foregroundStyle(.secondary)

                        Spacer()

                        Picker("", selection: $lookback) {
                            ForEach(lookbackOptions, id: \.months) { opt in
                                Text(opt.label).tag(opt.months)
                            }
                        }
                        .labelsHidden()
                        .pickerStyle(.menu)
                    }

                    Chart(monthlyExpenses) { bucket in
                        BarMark(
                            x: .value("Month", bucket.month, unit: .month),
                            y: .value("Expenses", bucket.amount)
                        )
                        .foregroundStyle(Color.accentColor.gradient)
                        .cornerRadius(4)
                    }
                    .chartXAxis {
                        AxisMarks(values: .stride(by: .month)) { value in
                            AxisValueLabel(format: .dateTime.month(.abbreviated))
                                .font(.caption2)
                        }
                    }
                    .chartYAxis {
                        AxisMarks { value in
                            AxisValueLabel {
                                if let d = value.as(Double.self) {
                                    Text(d, format: compactNumber
                                         ? .currency(code: currencyCode.rawValue).notation(.compactName)
                                         : .currency(code: currencyCode.rawValue))
                                        .font(.caption2)
                                        .contentTransition(.numericText(value: compactNumber ? 0 : 1))
                                }
                            }
                            AxisGridLine().foregroundStyle(Color.secondary.opacity(0.15))
                        }
                    }
                    .frame(height: 160)
                }
                .padding(.vertical, 8)
            }
        }
    }
}

#Preview {
    SpendingTrendsWidgetView()
}
