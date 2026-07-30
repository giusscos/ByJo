//
//  SavingsRateTrendWidget.swift
//  ByJoWidget
//

import WidgetKit
import SwiftUI
import Charts

struct SavingsRateTrendEntry: TimelineEntry {
    let date: Date
    let data: WSavingsRateTrendData
    static var placeholder: SavingsRateTrendEntry {
        let cal = Calendar.current
        let now = Date()
        let rates: [Double] = [0.18, 0.22, 0.15, 0.28, 0.12, 0.31]
        let points: [WSavingsRateTrendData.Point] = (0..<6).compactMap { i in
            guard let m = cal.date(byAdding: .month, value: -5 + i, to: now),
                  let start = cal.date(from: cal.dateComponents([.year, .month], from: m))
            else { return nil }
            return .init(id: "\(i)", month: start, rate: rates[i])
        }
        return SavingsRateTrendEntry(date: now, data: WSavingsRateTrendData(points: points, updatedAt: now))
    }
}

struct SavingsRateTrendProvider: TimelineProvider {
    func placeholder(in context: Context) -> SavingsRateTrendEntry { .placeholder }
    func getSnapshot(in context: Context, completion: @escaping (SavingsRateTrendEntry) -> Void) {
        completion(SavingsRateTrendEntry(date: Date(),
            data: UserDefaults.appGroup?.decode(WSavingsRateTrendData.self, forKey: .savingsRateTrend) ?? SavingsRateTrendEntry.placeholder.data))
    }
    func getTimeline(in context: Context, completion: @escaping (Timeline<SavingsRateTrendEntry>) -> Void) {
        let data = UserDefaults.appGroup?.decode(WSavingsRateTrendData.self, forKey: .savingsRateTrend) ?? SavingsRateTrendEntry.placeholder.data
        let next = Calendar.current.date(byAdding: .minute, value: 30, to: Date())!
        completion(Timeline(entries: [SavingsRateTrendEntry(date: Date(), data: data)], policy: .after(next)))
    }
}

struct SavingsRateTrendWidget: Widget {
    let kind = "SavingsRateTrendWidget"
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: SavingsRateTrendProvider()) { entry in
            SavingsRateTrendWidgetView(entry: entry).containerBackground(.background, for: .widget)
        }
        .configurationDisplayName("Savings Rate Trend")
        .description("Your savings rate over the last 6 months.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

private func srtColor(_ r: Double) -> Color { r >= 0.20 ? .green : r >= 0.10 ? .yellow : .red }
private func srtLabel(_ r: Double) -> String { r >= 0.20 ? "Great" : r >= 0.10 ? "OK" : "Low" }

private struct SRTChart: View {
    let points: [WSavingsRateTrendData.Point]
    var showAxes: Bool = false

    var body: some View {
        Chart(points) { point in
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
            .foregroundStyle(srtColor(point.rate))
            .symbolSize(showAxes ? 50 : 36)
        }
        .chartYScale(domain: 0...100)
        .chartXAxis {
            AxisMarks(values: .stride(by: .month)) { _ in
                AxisValueLabel(format: .dateTime.month(.abbreviated)).font(.caption2)
            }
        }
        .chartYAxis {
            if showAxes {
                AxisMarks(values: [0, 10, 20, 50, 100]) { value in
                    AxisValueLabel {
                        if let d = value.as(Double.self) {
                            Text("\(Int(d))%").font(.caption2)
                        }
                    }
                    AxisGridLine().foregroundStyle(Color.secondary.opacity(0.15))
                }
            }
        }
    }
}

struct SavingsRateTrendWidgetView: View {
    @Environment(\.widgetFamily) var family
    let entry: SavingsRateTrendEntry
    var body: some View {
        switch family {
        case .systemSmall:  SRTSmall(entry: entry)
        case .systemMedium: SRTMedium(entry: entry)
        default:            SRTLarge(entry: entry)
        }
    }
}

private struct SRTSmall: View {
    let entry: SavingsRateTrendEntry
    var latest: WSavingsRateTrendData.Point? { entry.data.points.last }
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Label("Savings Trend", systemImage: "chart.xyaxis.line")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
            if let latest {
                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text("\(Int((latest.rate * 100).rounded()))")
                        .font(.title.weight(.black))
                        .fontDesign(.rounded)
                        .foregroundStyle(srtColor(latest.rate))
                    Text("%")
                        .font(.title3.bold())
                        .fontDesign(.rounded)
                        .foregroundStyle(srtColor(latest.rate))
                }
                Text(srtLabel(latest.rate)).font(.caption).foregroundStyle(srtColor(latest.rate))
                SRTChart(points: entry.data.points)
                    .frame(maxHeight: .infinity)
            } else {
                Spacer()
                Text("No data").font(.caption).foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }
}

private struct SRTMedium: View {
    let entry: SavingsRateTrendEntry
    var latest: WSavingsRateTrendData.Point? { entry.data.points.last }
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label("Savings Rate Trend", systemImage: "chart.xyaxis.line")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
                Spacer()
                if let latest {
                    Text("\(Int((latest.rate * 100).rounded()))%")
                        .font(.subheadline.weight(.bold))
                        .fontDesign(.rounded)
                        .foregroundStyle(srtColor(latest.rate))
                }
            }
            if entry.data.points.isEmpty {
                Spacer()
                Text("No data").font(.subheadline).foregroundStyle(.secondary)
                Spacer()
            } else {
                SRTChart(points: entry.data.points)
                    .frame(maxHeight: .infinity)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }
}

private struct SRTLarge: View {
    let entry: SavingsRateTrendEntry
    var latest: WSavingsRateTrendData.Point? { entry.data.points.last }
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Savings Rate Trend", systemImage: "chart.xyaxis.line")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)

            if let latest {
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text("\(Int((latest.rate * 100).rounded()))")
                        .font(.system(size: 48, weight: .black, design: .rounded))
                        .foregroundStyle(srtColor(latest.rate))
                    VStack(alignment: .leading, spacing: 2) {
                        Text("%")
                            .font(.title.bold())
                            .fontDesign(.rounded)
                            .foregroundStyle(srtColor(latest.rate))
                        Text(srtLabel(latest.rate)).font(.caption).fontWeight(.semibold).foregroundStyle(srtColor(latest.rate))
                    }
                    Spacer()
                    Text("This month").font(.caption).foregroundStyle(.secondary)
                }

                SRTChart(points: entry.data.points, showAxes: true)
                    .frame(maxHeight: .infinity)

                HStack {
                    Label("≥20% great", systemImage: "circle.fill").foregroundStyle(.green)
                    Spacer()
                    Label("10–20% ok", systemImage: "circle.fill").foregroundStyle(.yellow)
                    Spacer()
                    Label("<10% low", systemImage: "circle.fill").foregroundStyle(.red)
                }
                .font(.caption2).foregroundStyle(.secondary)
            } else {
                Spacer()
                Text("No data yet").font(.subheadline).foregroundStyle(.secondary).frame(maxWidth: .infinity)
                Spacer()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

#Preview(as: .systemSmall)  { SavingsRateTrendWidget() } timeline: { SavingsRateTrendEntry.placeholder }
#Preview(as: .systemMedium) { SavingsRateTrendWidget() } timeline: { SavingsRateTrendEntry.placeholder }
#Preview(as: .systemLarge)  { SavingsRateTrendWidget() } timeline: { SavingsRateTrendEntry.placeholder }
