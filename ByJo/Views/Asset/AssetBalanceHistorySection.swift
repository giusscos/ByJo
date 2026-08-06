//
//  AssetBalanceHistorySection.swift
//  ByJo
//

import Charts
import SwiftUI

private struct AssetBalancePoint: Identifiable {
    let id = UUID()
    let date: Date
    let value: Double
}

struct AssetBalanceHistorySection: View {
    @AppStorage("currencyCode") var currencyCode: CurrencyCode = .usd
    @AppStorage("compactNumber") var compactNumber: Bool = true

    var asset: Asset

    @State private var selectedRange: DateRangeOption = .all

    private let rangeOptions: [DateRangeOption] = [.week, .month, .threeMonths, .sixMonths, .year, .all]

    private var currentBalance: Double {
        NSDecimalNumber(decimal: asset.calculateCurrentBalance()).doubleValue
    }

    private var points: [AssetBalancePoint] {
        let calendar = Calendar.current
        let now = Date()

        let start: Date
        if case .all = selectedRange {
            let earliestOp = (asset.operations ?? []).map(\.date).min()
            let candidate = earliestOp.map { calendar.startOfDay(for: $0) } ?? calendar.startOfDay(for: asset.timestamp)
            start = min(candidate, calendar.startOfDay(for: asset.timestamp))
        } else {
            start = calendar.startOfDay(for: selectedRange.rollingStartDate)
        }
        guard start < now else { return [AssetBalancePoint(date: now, value: currentBalance)] }

        let totalDays = calendar.dateComponents([.day], from: start, to: now).day ?? 0
        let stepDays: Int = {
            switch totalDays {
            case 0...31:   return 1
            case 32...90:  return 3
            case 91...365: return 7
            default:       return 30
            }
        }()

        var result: [AssetBalancePoint] = []
        var current = start
        while current <= now {
            let balance = NSDecimalNumber(decimal: asset.calculateBalance(at: current)).doubleValue
            result.append(AssetBalancePoint(date: current, value: balance))
            guard let next = calendar.date(byAdding: .day, value: stepDays, to: current), next <= now else { break }
            current = next
        }
        result.append(AssetBalancePoint(date: now, value: currentBalance))
        return result
    }

    private var delta: Double { (points.first?.value).map { currentBalance - $0 } ?? 0 }
    private var lineColor: Color { delta >= 0 ? .green : .red }

    var body: some View {
        Section {
            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Balance history")
                            .font(.headline)
                            .foregroundStyle(.secondary)

                        Text(currentBalance, format: compactNumber
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
                    Chart {
                        ForEach(points) { point in
                            AreaMark(
                                x: .value("Date", point.date),
                                y: .value("Balance", point.value)
                            )
                            .foregroundStyle(.linearGradient(
                                colors: [lineColor.opacity(0.25), lineColor.opacity(0.0)],
                                startPoint: .top, endPoint: .bottom
                            ))
                            .interpolationMethod(.monotone)

                            LineMark(
                                x: .value("Date", point.date),
                                y: .value("Balance", point.value)
                            )
                            .foregroundStyle(lineColor)
                            .lineStyle(StrokeStyle(lineWidth: 2))
                            .interpolationMethod(.monotone)
                        }
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

#Preview {
    List {
        AssetBalanceHistorySection(asset: Asset(name: "Bitcoin", type: .crypto, initialBalance: 3500))
    }
}
