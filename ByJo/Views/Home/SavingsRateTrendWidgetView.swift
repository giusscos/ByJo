//
//  SavingsRateTrendWidgetView.swift
//  ByJo
//

import Charts
import SwiftData
import SwiftUI

private struct MonthRate: Identifiable {
    let id = UUID()
    let month: Date
    let rate: Double
    let hasData: Bool
}

struct SavingsRateTrendWidgetView: View {
    @Query var assets: [Asset]

    private var monthlyRates: [MonthRate] {
        let calendar = Calendar.current
        let now = Date()
        let allOps = assets.flatMap { $0.operations ?? [] }

        return (0..<6).compactMap { offset -> MonthRate? in
            let monthsAgo = -(5 - offset)
            guard let monthDate = calendar.date(byAdding: .month, value: monthsAgo, to: now),
                  let start = calendar.date(from: calendar.dateComponents([.year, .month], from: monthDate)),
                  let end = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: start)
            else { return nil }

            let ops = allOps.filter { $0.date >= start && $0.date <= end }
            let inflow = ops.filter { $0.amount > 0 }.reduce(Decimal(0)) { $0 + $1.amount }
            let outflow = ops.filter { $0.amount < 0 }.reduce(Decimal(0)) { $0 + abs($1.amount) }

            if inflow > 0 {
                let rate = max(0.0, min(1.0, NSDecimalNumber(decimal: (inflow - outflow) / inflow).doubleValue))
                return MonthRate(month: start, rate: rate, hasData: true)
            } else {
                return MonthRate(month: start, rate: 0.0, hasData: false)
            }
        }
    }

    private var dataPoints: [MonthRate] { monthlyRates.filter { $0.hasData } }

    private func rateColor(_ rate: Double) -> Color {
        if rate >= 0.20 { return .green }
        if rate >= 0.10 { return .yellow }
        return .red
    }

    var body: some View {
        if !dataPoints.isEmpty {
            Section {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Savings rate trend")
                        .font(.headline)
                        .foregroundStyle(.secondary)

                    Chart(dataPoints) { point in
                        LineMark(
                            x: .value("Month", point.month, unit: .month),
                            y: .value("Rate", point.rate * 100)
                        )
                        .foregroundStyle(Color.accentColor)
                        .lineStyle(StrokeStyle(lineWidth: 2))
                        .interpolationMethod(.monotone)

                        PointMark(
                            x: .value("Month", point.month, unit: .month),
                            y: .value("Rate", point.rate * 100)
                        )
                        .foregroundStyle(rateColor(point.rate))
                        .symbolSize(50)
                    }
                    .chartYScale(domain: 0...100)
                    .chartXAxis {
                        AxisMarks(values: .stride(by: .month)) { value in
                            AxisValueLabel(format: .dateTime.month(.abbreviated))
                                .font(.caption2)
                        }
                    }
                    .chartYAxis {
                        AxisMarks(values: [0, 10, 20, 50, 100]) { value in
                            AxisValueLabel {
                                if let d = value.as(Double.self) {
                                    Text("\(Int(d))%")
                                        .font(.caption2)
                                }
                            }
                            AxisGridLine().foregroundStyle(Color.secondary.opacity(0.15))
                        }
                    }
                    .frame(height: 140)

                    HStack {
                        Label("≥20% great", systemImage: "circle.fill").foregroundStyle(.green)
                        Spacer()
                        Label("10–20% ok", systemImage: "circle.fill").foregroundStyle(.yellow)
                        Spacer()
                        Label("<10% low", systemImage: "circle.fill").foregroundStyle(.red)
                    }
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                }
                .padding(.vertical, 8)
            }
        }
    }
}

#Preview {
    SavingsRateTrendWidgetView()
}
