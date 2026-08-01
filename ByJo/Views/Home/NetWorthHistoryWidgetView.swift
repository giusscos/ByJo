//
//  NetWorthHistoryWidgetView.swift
//  ByJo
//

import Charts
import SwiftData
import SwiftUI

private struct NetWorthPoint: Identifiable {
    let id = UUID()
    let date: Date
    let value: Double
}

struct NetWorthHistoryWidgetView: View {
    @AppStorage("currencyCode") var currencyCode: CurrencyCode = .usd
    @AppStorage("compactNumber") var compactNumber: Bool = true

    @Query var assets: [Asset]

    @State private var selectedRange: DateRangeOption = .month

    private let rangeOptions: [DateRangeOption] = [.week, .month, .threeMonths, .sixMonths, .year, .all]

    private var currentNetWorth: Double {
        assets.reduce(0.0) { $0 + NSDecimalNumber(decimal: $1.calculateCurrentBalance()).doubleValue }
    }

    private var points: [NetWorthPoint] {
        guard !assets.isEmpty else { return [] }
        let calendar = Calendar.current
        let now = Date()

        let start: Date
        if case .all = selectedRange {
            let earliest = assets.flatMap { $0.operations ?? [] }.map(\.date).min()
            start = earliest.map { calendar.startOfDay(for: $0) } ?? now
        } else {
            start = calendar.startOfDay(for: selectedRange.rollingStartDate)
        }
        guard start < now else { return [NetWorthPoint(date: now, value: currentNetWorth)] }

        let totalDays = calendar.dateComponents([.day], from: start, to: now).day ?? 0
        let stepDays: Int = {
            switch totalDays {
            case 0...31:   return 1
            case 32...90:  return 3
            case 91...365: return 7
            default:       return 30
            }
        }()

        var result: [NetWorthPoint] = []
        var current = start
        while current <= now {
            result.append(NetWorthPoint(date: current, value: netWorthAt(current)))
            guard let next = calendar.date(byAdding: .day, value: stepDays, to: current), next <= now else { break }
            current = next
        }
        result.append(NetWorthPoint(date: now, value: currentNetWorth))
        return result
    }

    private func netWorthAt(_ date: Date) -> Double {
        assets.reduce(0.0) { sum, asset in
            let balance = asset.initialBalance + (asset.operations ?? [])
                .filter { $0.date <= date }
                .reduce(Decimal(0)) { $0 + $1.amount }
            return sum + NSDecimalNumber(decimal: balance).doubleValue
        }
    }

    private var delta: Double { (points.first?.value).map { currentNetWorth - $0 } ?? 0 }
    private var lineColor: Color { delta >= 0 ? .green : .red }

    var body: some View {
        if !assets.isEmpty {
            Section {
                VStack(alignment: .leading, spacing: 16) {
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Net worth history")
                                .font(.headline)
                                .foregroundStyle(.secondary)

                            Text(currentNetWorth, format: compactNumber
                                 ? .currency(code: currencyCode.rawValue).notation(.compactName)
                                 : .currency(code: currencyCode.rawValue))
                                .font(.title2)
                                .fontWeight(.bold)
                                .contentTransition(.numericText(value: compactNumber ? 0 : 1))

                            if points.count > 1 {
                                HStack(spacing: 3) {
                                    Image(systemName: delta >= 0 ? "arrow.up" : "arrow.down")
                                    Text(abs(delta), format: compactNumber
                                         ? .currency(code: currencyCode.rawValue).notation(.compactName)
                                         : .currency(code: currencyCode.rawValue))
                                        .contentTransition(.numericText(value: compactNumber ? 0 : 1))
                                }
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundStyle(lineColor)
                            }
                        }

                        Spacer()

                        Picker("", selection: $selectedRange) {
                            ForEach(rangeOptions, id: \.self) { option in
                                Text(option.label).tag(option)
                            }
                        }
                        .labelsHidden()
                        .pickerStyle(.menu)
                    }

                    if points.count > 1 {
                        Chart(points) { point in
                            AreaMark(
                                x: .value("Date", point.date),
                                y: .value("Net Worth", point.value)
                            )
                            .foregroundStyle(.linearGradient(
                                colors: [lineColor.opacity(0.25), lineColor.opacity(0.0)],
                                startPoint: .top, endPoint: .bottom
                            ))
                            .interpolationMethod(.monotone)

                            LineMark(
                                x: .value("Date", point.date),
                                y: .value("Net Worth", point.value)
                            )
                            .foregroundStyle(lineColor)
                            .lineStyle(StrokeStyle(lineWidth: 2))
                            .interpolationMethod(.monotone)
                        }
                        .chartYScale(domain: .automatic(includesZero: false))
                        .chartXAxis {
                            AxisMarks(values: .automatic(desiredCount: 4)) { value in
                                if let date = value.as(Date.self) {
                                    AxisValueLabel {
                                        Text(date, format: selectedRange == .week
                                             ? .dateTime.weekday(.abbreviated)
                                             : .dateTime.month(.abbreviated).day())
                                            .font(.caption2)
                                    }
                                }
                                AxisGridLine().foregroundStyle(Color.secondary.opacity(0.15))
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
                }
                .padding(.vertical, 8)
            }
        }
    }
}

#Preview {
    NetWorthHistoryWidgetView()
}
