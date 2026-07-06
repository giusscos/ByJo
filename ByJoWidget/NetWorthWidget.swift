//
//  NetWorthWidget.swift
//  ByJoWidget
//

import WidgetKit
import SwiftUI
import Charts

struct NetWorthEntry: TimelineEntry {
    let date: Date
    let data: WNetWorthData

    static var placeholder: NetWorthEntry {
        NetWorthEntry(date: Date(), data: WNetWorthData(
            netWorth: 48250, currencyCode: "USD", compactNumber: true,
            assets: [
                .init(id: "1", name: "Savings",     balance: 24000, colorIndex: 0),
                .init(id: "2", name: "Investments", balance: 18000, colorIndex: 1),
                .init(id: "3", name: "Cash",        balance: 6250,  colorIndex: 2),
                .init(id: "4", name: "Savings",     balance: 24000, colorIndex: 0),
                .init(id: "5", name: "Investments", balance: 18000, colorIndex: 1),
                .init(id: "6", name: "Cash",        balance: 6250,  colorIndex: 2),
            ], updatedAt: Date()
        ))
    }
}

struct NetWorthProvider: TimelineProvider {
    func placeholder(in context: Context) -> NetWorthEntry { .placeholder }
    func getSnapshot(in context: Context, completion: @escaping (NetWorthEntry) -> Void) {
        completion(NetWorthEntry(date: Date(),
            data: UserDefaults.appGroup?.decode(WNetWorthData.self, forKey: .netWorth) ?? NetWorthEntry.placeholder.data))
    }
    func getTimeline(in context: Context, completion: @escaping (Timeline<NetWorthEntry>) -> Void) {
        let data = UserDefaults.appGroup?.decode(WNetWorthData.self, forKey: .netWorth) ?? NetWorthEntry.placeholder.data
        let next = Calendar.current.date(byAdding: .minute, value: 30, to: Date())!
        completion(Timeline(entries: [NetWorthEntry(date: Date(), data: data)], policy: .after(next)))
    }
}

struct NetWorthWidget: Widget {
    let kind = "NetWorthWidget"
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: NetWorthProvider()) { entry in
            NetWorthWidgetView(entry: entry).containerBackground(.background, for: .widget)
        }
        .configurationDisplayName("Net Worth")
        .description("Your total net worth at a glance.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

// MARK: - Helpers

private let wPalette: [Color] = [.blue, .green, .orange, .purple, .cyan, .pink, .yellow, .indigo]
private func wColor(_ i: Int) -> Color { wPalette[i % wPalette.count] }

private func wFormatted(_ v: Double, currency: String, compact: Bool) -> String {
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

// MARK: - Views

struct NetWorthWidgetView: View {
    @Environment(\.widgetFamily) var family
    let entry: NetWorthEntry
    var body: some View {
        switch family {
        case .systemSmall:  NWSmall(entry: entry)
        case .systemMedium: NWMedium(entry: entry)
        default:            NWLarge(entry: entry)
        }
    }
}

private struct NWSmall: View {
    let entry: NetWorthEntry
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label("Net Worth", systemImage: "chart.line.uptrend.xyaxis")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
            Spacer()
            Text(wFormatted(entry.data.netWorth, currency: entry.data.currencyCode, compact: entry.data.compactNumber))
                .font(.title.bold())
                .fontDesign(.rounded)
                .minimumScaleFactor(0.6).lineLimit(1)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }
}

private struct NWMedium: View {
    let entry: NetWorthEntry
    var body: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                Label("Net Worth", systemImage: "chart.line.uptrend.xyaxis")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
                Spacer()
                Text(wFormatted(entry.data.netWorth, currency: entry.data.currencyCode, compact: entry.data.compactNumber))
                    .font(.title.bold())
                    .fontDesign(.rounded)
                    .minimumScaleFactor(0.5).lineLimit(1)
            }
            Divider()
            VStack(alignment: .leading, spacing: 6) {
                ForEach(entry.data.assets.prefix(6)) { a in
                    HStack(spacing: 6) {
                        Circle().fill(wColor(a.colorIndex)).frame(width: 7, height: 7)
                        Text(a.name).font(.caption2).lineLimit(1)
                        Spacer()
                        Text(wFormatted(a.balance, currency: entry.data.currencyCode, compact: true))
                            .font(.caption2).fontWeight(.semibold).foregroundStyle(.secondary)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

private struct NWLarge: View {
    let entry: NetWorthEntry
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Net Worth", systemImage: "chart.line.uptrend.xyaxis")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
            
            Spacer()
            
            Text(wFormatted(entry.data.netWorth, currency: entry.data.currencyCode, compact: entry.data.compactNumber))
                .font(.largeTitle.bold())
                .fontDesign(.rounded)
                .minimumScaleFactor(0.5).lineLimit(1)
            Divider()
            VStack(alignment: .leading, spacing: 8) {
                ForEach(entry.data.assets, id: \.id) { a in
                    HStack {
                        Circle().fill(wColor(a.colorIndex)).frame(width: 8, height: 8)
                        Text(a.name).font(.subheadline).lineLimit(1)
                        Spacer()
                        Text(wFormatted(a.balance, currency: entry.data.currencyCode, compact: entry.data.compactNumber))
                            .font(.subheadline).fontWeight(.semibold)
                            .foregroundStyle(a.balance >= 0 ? Color.primary : Color.red)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

#Preview(as: .systemSmall)  { NetWorthWidget() } timeline: { NetWorthEntry.placeholder }
#Preview(as: .systemMedium) { NetWorthWidget() } timeline: { NetWorthEntry.placeholder }
#Preview(as: .systemLarge)  { NetWorthWidget() } timeline: { NetWorthEntry.placeholder }
