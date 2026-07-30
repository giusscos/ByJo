//
//  SpendingTrendsWidget.swift
//  ByJoWidget
//

import WidgetKit
import SwiftUI
import Charts

struct SpendingTrendsEntry: TimelineEntry {
    let date: Date
    let data: WSpendingTrendsData
    static var placeholder: SpendingTrendsEntry {
        let cal = Calendar.current
        let now = Date()
        let buckets: [WSpendingTrendsData.Bucket] = (0..<6).compactMap { i in
            guard let m = cal.date(byAdding: .month, value: -5 + i, to: now),
                  let start = cal.date(from: cal.dateComponents([.year, .month], from: m))
            else { return nil }
            let amounts: [Double] = [1100, 980, 1250, 890, 1400, 1050]
            return .init(id: "\(i)", month: start, amount: amounts[i])
        }
        return SpendingTrendsEntry(date: now, data: WSpendingTrendsData(
            buckets: buckets, currencyCode: "USD", compactNumber: true, updatedAt: now))
    }
}

struct SpendingTrendsProvider: TimelineProvider {
    func placeholder(in context: Context) -> SpendingTrendsEntry { .placeholder }
    func getSnapshot(in context: Context, completion: @escaping (SpendingTrendsEntry) -> Void) {
        completion(SpendingTrendsEntry(date: Date(),
            data: UserDefaults.appGroup?.decode(WSpendingTrendsData.self, forKey: .spendingTrends) ?? SpendingTrendsEntry.placeholder.data))
    }
    func getTimeline(in context: Context, completion: @escaping (Timeline<SpendingTrendsEntry>) -> Void) {
        let data = UserDefaults.appGroup?.decode(WSpendingTrendsData.self, forKey: .spendingTrends) ?? SpendingTrendsEntry.placeholder.data
        let next = Calendar.current.date(byAdding: .minute, value: 30, to: Date())!
        completion(Timeline(entries: [SpendingTrendsEntry(date: Date(), data: data)], policy: .after(next)))
    }
}

struct SpendingTrendsWidget: Widget {
    let kind = "SpendingTrendsWidget"
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: SpendingTrendsProvider()) { entry in
            SpendingTrendsWidgetView(entry: entry).containerBackground(.background, for: .widget)
        }
        .configurationDisplayName("Spending Trends")
        .description("Monthly spending over the last 6 months.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

private func stFmt(_ v: Double, currency: String, compact: Bool) -> String {
    if compact {
        let sym = NumberFormatter().then { $0.numberStyle = .currency; $0.currencyCode = currency }.currencySymbol ?? "$"
        if abs(v) >= 1_000_000 { return sym + String(format: "%.1fM", v / 1_000_000) }
        if abs(v) >= 1_000     { return sym + String(format: "%.1fK", v / 1_000) }
    }
    let f = NumberFormatter(); f.numberStyle = .currency; f.currencyCode = currency; f.maximumFractionDigits = 0
    return f.string(from: NSNumber(value: v)) ?? "\(v)"
}

private extension NumberFormatter {
    func then(_ block: (NumberFormatter) -> Void) -> NumberFormatter { block(self); return self }
}

private struct STBarChart: View {
    let buckets: [WSpendingTrendsData.Bucket]
    var showAxes: Bool = false
    var currencyCode: String = "USD"

    var body: some View {
        Chart(buckets) { bucket in
            BarMark(
                x: .value("Month", bucket.month, unit: .month),
                y: .value("Expenses", bucket.amount)
            )
            .foregroundStyle(Color.accentColor.gradient)
            .cornerRadius(4)
        }
        .chartXAxis {
            AxisMarks(values: .stride(by: .month)) { _ in
                AxisValueLabel(format: .dateTime.month(.abbreviated)).font(.caption2)
            }
        }
        .chartYAxis {
            if showAxes {
                AxisMarks { value in
                    AxisValueLabel {
                        if let d = value.as(Double.self) {
                            Text(stFmt(d, currency: currencyCode, compact: true)).font(.caption2)
                        }
                    }
                    AxisGridLine().foregroundStyle(Color.secondary.opacity(0.15))
                }
            }
        }
    }
}

struct SpendingTrendsWidgetView: View {
    @Environment(\.widgetFamily) var family
    let entry: SpendingTrendsEntry
    var body: some View {
        switch family {
        case .systemSmall:  STSmall(entry: entry)
        case .systemMedium: STMedium(entry: entry)
        default:            STLarge(entry: entry)
        }
    }
}

private struct STSmall: View {
    let entry: SpendingTrendsEntry
    var total: Double { entry.data.buckets.reduce(0) { $0 + $1.amount } }
    var hasData: Bool { entry.data.buckets.contains { $0.amount > 0 } }
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Label("Spending", systemImage: "chart.bar.fill")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
            if hasData {
                Text(stFmt(total, currency: entry.data.currencyCode, compact: entry.data.compactNumber))
                    .font(.title3.bold())
                    .fontDesign(.rounded)
                    .minimumScaleFactor(0.6).lineLimit(1)
                Text("6 months").font(.caption2).foregroundStyle(.secondary)
                STBarChart(buckets: entry.data.buckets)
                    .frame(maxHeight: .infinity)
            } else {
                Spacer()
                Text("No data").font(.caption).foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }
}

private struct STMedium: View {
    let entry: SpendingTrendsEntry
    var total: Double { entry.data.buckets.reduce(0) { $0 + $1.amount } }
    var hasData: Bool { entry.data.buckets.contains { $0.amount > 0 } }
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label("Spending Trends", systemImage: "chart.bar.fill")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
                Spacer()
                if hasData {
                    Text(stFmt(total, currency: entry.data.currencyCode, compact: entry.data.compactNumber))
                        .font(.subheadline.weight(.semibold))
                }
            }
            if hasData {
                STBarChart(buckets: entry.data.buckets)
                    .frame(maxHeight: .infinity)
            } else {
                Spacer()
                Text("No spending data").font(.subheadline).foregroundStyle(.secondary)
                Spacer()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }
}

private struct STLarge: View {
    let entry: SpendingTrendsEntry
    var total: Double { entry.data.buckets.reduce(0) { $0 + $1.amount } }
    var avg: Double {
        let nonZero = entry.data.buckets.filter { $0.amount > 0 }
        guard !nonZero.isEmpty else { return 0 }
        return nonZero.reduce(0.0) { $0 + $1.amount } / Double(nonZero.count)
    }
    var hasData: Bool { entry.data.buckets.contains { $0.amount > 0 } }
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Spending Trends", systemImage: "chart.bar.fill")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)

            if hasData {
                HStack(spacing: 24) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Total").font(.caption2).foregroundStyle(.secondary)
                        Text(stFmt(total, currency: entry.data.currencyCode, compact: entry.data.compactNumber))
                            .font(.title2.bold()).fontDesign(.rounded)
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Avg / month").font(.caption2).foregroundStyle(.secondary)
                        Text(stFmt(avg, currency: entry.data.currencyCode, compact: entry.data.compactNumber))
                            .font(.title2.bold()).fontDesign(.rounded)
                    }
                }
                STBarChart(buckets: entry.data.buckets, showAxes: true, currencyCode: entry.data.currencyCode)
                    .frame(maxHeight: .infinity)
            } else {
                Spacer()
                Text("No spending data").font(.subheadline).foregroundStyle(.secondary).frame(maxWidth: .infinity)
                Spacer()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

#Preview(as: .systemSmall)  { SpendingTrendsWidget() } timeline: { SpendingTrendsEntry.placeholder }
#Preview(as: .systemMedium) { SpendingTrendsWidget() } timeline: { SpendingTrendsEntry.placeholder }
#Preview(as: .systemLarge)  { SpendingTrendsWidget() } timeline: { SpendingTrendsEntry.placeholder }
