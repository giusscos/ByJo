//
//  NetWorthHistoryWidget.swift
//  ByJoWidget
//

import WidgetKit
import SwiftUI
import Charts

struct NetWorthHistoryEntry: TimelineEntry {
    let date: Date
    let data: WNetWorthHistoryData
    static var placeholder: NetWorthHistoryEntry {
        let cal = Calendar.current
        let now = Date()
        let points: [WNetWorthHistoryData.Point] = (0..<12).compactMap { i in
            guard let d = cal.date(byAdding: .day, value: -30 + i * 3, to: now) else { return nil }
            return .init(id: "\(i)", date: d, value: 42000 + Double(i) * 450)
        }
        return NetWorthHistoryEntry(date: now, data: WNetWorthHistoryData(
            points: points, currentNetWorth: 47400, delta: 5400,
            currencyCode: "USD", compactNumber: true, updatedAt: now))
    }
}

struct NetWorthHistoryProvider: TimelineProvider {
    func placeholder(in context: Context) -> NetWorthHistoryEntry { .placeholder }
    func getSnapshot(in context: Context, completion: @escaping (NetWorthHistoryEntry) -> Void) {
        completion(NetWorthHistoryEntry(date: Date(),
            data: UserDefaults.appGroup?.decode(WNetWorthHistoryData.self, forKey: .netWorthHistory) ?? NetWorthHistoryEntry.placeholder.data))
    }
    func getTimeline(in context: Context, completion: @escaping (Timeline<NetWorthHistoryEntry>) -> Void) {
        let data = UserDefaults.appGroup?.decode(WNetWorthHistoryData.self, forKey: .netWorthHistory) ?? NetWorthHistoryEntry.placeholder.data
        let next = Calendar.current.date(byAdding: .minute, value: 30, to: Date())!
        completion(Timeline(entries: [NetWorthHistoryEntry(date: Date(), data: data)], policy: .after(next)))
    }
}

struct NetWorthHistoryWidget: Widget {
    let kind = "NetWorthHistoryWidget"
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: NetWorthHistoryProvider()) { entry in
            NetWorthHistoryWidgetView(entry: entry).containerBackground(.background, for: .widget)
        }
        .configurationDisplayName("Net Worth History")
        .description("Your net worth trend over the past month.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

private func nwhFmt(_ v: Double, currency: String, compact: Bool) -> String {
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

private struct NWHChart: View {
    let points: [WNetWorthHistoryData.Point]
    let lineColor: Color
    var showAxes: Bool = false
    var currencyCode: String = "USD"
    var compact: Bool = true

    var body: some View {
        Chart(points) { point in
            AreaMark(x: .value("Date", point.date), y: .value("Net Worth", point.value))
                .foregroundStyle(.linearGradient(
                    colors: [lineColor.opacity(0.25), lineColor.opacity(0.0)],
                    startPoint: .top, endPoint: .bottom
                ))
                .interpolationMethod(.monotone)
            LineMark(x: .value("Date", point.date), y: .value("Net Worth", point.value))
                .foregroundStyle(lineColor)
                .lineStyle(StrokeStyle(lineWidth: 2))
                .interpolationMethod(.monotone)
        }
        .chartYScale(domain: .automatic(includesZero: false))
        .chartXAxis {
            if showAxes {
                AxisMarks(values: .automatic(desiredCount: 4)) { value in
                    if let date = value.as(Date.self) {
                        AxisValueLabel {
                            Text(date, format: .dateTime.month(.abbreviated).day()).font(.caption2)
                        }
                    }
                    AxisGridLine().foregroundStyle(Color.secondary.opacity(0.15))
                }
            }
        }
        .chartYAxis {
            if showAxes {
                AxisMarks { value in
                    AxisValueLabel {
                        if let d = value.as(Double.self) {
                            Text(nwhFmt(d, currency: currencyCode, compact: true)).font(.caption2)
                        }
                    }
                    AxisGridLine().foregroundStyle(Color.secondary.opacity(0.15))
                }
            }
        }
    }
}

struct NetWorthHistoryWidgetView: View {
    @Environment(\.widgetFamily) var family
    let entry: NetWorthHistoryEntry
    var body: some View {
        switch family {
        case .systemSmall:  NWHSmall(entry: entry)
        case .systemMedium: NWHMedium(entry: entry)
        default:            NWHLarge(entry: entry)
        }
    }
}

private struct NWHSmall: View {
    let entry: NetWorthHistoryEntry
    var lineColor: Color { entry.data.delta >= 0 ? .green : .red }
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Label("Net Worth", systemImage: "chart.line.uptrend.xyaxis")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
            Text(nwhFmt(entry.data.currentNetWorth, currency: entry.data.currencyCode, compact: entry.data.compactNumber))
                .font(.title3.bold())
                .fontDesign(.rounded)
                .minimumScaleFactor(0.6).lineLimit(1)
            if entry.data.points.count > 1 {
                HStack(spacing: 2) {
                    Image(systemName: entry.data.delta >= 0 ? "arrow.up" : "arrow.down")
                    Text(nwhFmt(abs(entry.data.delta), currency: entry.data.currencyCode, compact: true))
                }
                .font(.caption2).fontWeight(.semibold).foregroundStyle(lineColor)
                NWHChart(points: entry.data.points, lineColor: lineColor)
                    .frame(maxHeight: .infinity)
            } else {
                Spacer()
                Text("No history").font(.caption).foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }
}

private struct NWHMedium: View {
    let entry: NetWorthHistoryEntry
    var lineColor: Color { entry.data.delta >= 0 ? .green : .red }
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 2) {
                    Label("Net Worth History", systemImage: "chart.line.uptrend.xyaxis")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                    Text(nwhFmt(entry.data.currentNetWorth, currency: entry.data.currencyCode, compact: entry.data.compactNumber))
                        .font(.title.bold())
                        .fontDesign(.rounded)
                        .minimumScaleFactor(0.6).lineLimit(1)
                }
                Spacer()
                if entry.data.points.count > 1 {
                    HStack(spacing: 3) {
                        Image(systemName: entry.data.delta >= 0 ? "arrow.up" : "arrow.down")
                        Text(nwhFmt(abs(entry.data.delta), currency: entry.data.currencyCode, compact: entry.data.compactNumber))
                    }
                    .font(.caption).fontWeight(.semibold).foregroundStyle(lineColor)
                }
            }
            if entry.data.points.count > 1 {
                NWHChart(points: entry.data.points, lineColor: lineColor)
                    .frame(maxHeight: .infinity)
            } else {
                Spacer()
                Text("No history yet").font(.subheadline).foregroundStyle(.secondary)
                Spacer()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }
}

private struct NWHLarge: View {
    let entry: NetWorthHistoryEntry
    var lineColor: Color { entry.data.delta >= 0 ? .green : .red }
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Net Worth History", systemImage: "chart.line.uptrend.xyaxis")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)

            HStack(alignment: .lastTextBaseline, spacing: 8) {
                Text(nwhFmt(entry.data.currentNetWorth, currency: entry.data.currencyCode, compact: entry.data.compactNumber))
                    .font(.largeTitle.bold())
                    .fontDesign(.rounded)
                    .minimumScaleFactor(0.5).lineLimit(1)
                if entry.data.points.count > 1 {
                    HStack(spacing: 3) {
                        Image(systemName: entry.data.delta >= 0 ? "arrow.up" : "arrow.down")
                        Text(nwhFmt(abs(entry.data.delta), currency: entry.data.currencyCode, compact: entry.data.compactNumber))
                    }
                    .font(.subheadline).fontWeight(.semibold).foregroundStyle(lineColor)
                }
            }

            if entry.data.points.count > 1 {
                NWHChart(points: entry.data.points, lineColor: lineColor, showAxes: true,
                         currencyCode: entry.data.currencyCode, compact: entry.data.compactNumber)
                    .frame(maxHeight: .infinity)
            } else {
                Spacer()
                Text("No history yet").font(.subheadline).foregroundStyle(.secondary).frame(maxWidth: .infinity)
                Spacer()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

#Preview(as: .systemSmall)  { NetWorthHistoryWidget() } timeline: { NetWorthHistoryEntry.placeholder }
#Preview(as: .systemMedium) { NetWorthHistoryWidget() } timeline: { NetWorthHistoryEntry.placeholder }
#Preview(as: .systemLarge)  { NetWorthHistoryWidget() } timeline: { NetWorthHistoryEntry.placeholder }
