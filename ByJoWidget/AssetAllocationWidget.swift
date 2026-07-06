//
//  AssetAllocationWidget.swift
//  ByJoWidget
//

import WidgetKit
import SwiftUI
import Charts

struct AssetAllocEntry: TimelineEntry {
    let date: Date
    let data: WAssetAllocData
    static var placeholder: AssetAllocEntry {
        AssetAllocEntry(date: Date(), data: WAssetAllocData(slices: [
            .init(id: "1", label: "Savings",     value: 45, colorIndex: 0),
            .init(id: "2", label: "Stocks",      value: 30, colorIndex: 1),
            .init(id: "3", label: "Cash",        value: 15, colorIndex: 2),
            .init(id: "4", label: "Crypto",      value: 10, colorIndex: 3),
        ], currencyCode: "USD", updatedAt: Date()))
    }
}

struct AssetAllocProvider: TimelineProvider {
    func placeholder(in context: Context) -> AssetAllocEntry { .placeholder }
    func getSnapshot(in context: Context, completion: @escaping (AssetAllocEntry) -> Void) {
        completion(AssetAllocEntry(date: Date(),
            data: UserDefaults.appGroup?.decode(WAssetAllocData.self, forKey: .assetAlloc) ?? AssetAllocEntry.placeholder.data))
    }
    func getTimeline(in context: Context, completion: @escaping (Timeline<AssetAllocEntry>) -> Void) {
        let data = UserDefaults.appGroup?.decode(WAssetAllocData.self, forKey: .assetAlloc) ?? AssetAllocEntry.placeholder.data
        let next = Calendar.current.date(byAdding: .minute, value: 30, to: Date())!
        completion(Timeline(entries: [AssetAllocEntry(date: Date(), data: data)], policy: .after(next)))
    }
}

struct AssetAllocationWidget: Widget {
    let kind = "AssetAllocationWidget"
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: AssetAllocProvider()) { entry in
            AssetAllocWidgetView(entry: entry).containerBackground(.background, for: .widget)
        }
        .configurationDisplayName("Asset Allocation")
        .description("How your wealth is distributed across assets.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

private let allocPalette: [Color] = [.blue, .green, .orange, .purple, .cyan, .pink, .yellow, .indigo]
private func allocColor(_ i: Int) -> Color { allocPalette[i % allocPalette.count] }

private struct DonutChart: View {
    let slices: [WAssetAllocData.Slice]
    var body: some View {
        Chart(slices) { s in
            SectorMark(angle: .value("Value", s.value), innerRadius: .ratio(0.55), angularInset: 2)
                .foregroundStyle(allocColor(s.colorIndex)).cornerRadius(4)
        }
    }
}

struct AssetAllocWidgetView: View {
    @Environment(\.widgetFamily) var family
    let entry: AssetAllocEntry
    var body: some View {
        switch family {
        case .systemSmall:  AASmall(entry: entry)
        case .systemMedium: AAMedium(entry: entry)
        default:            AALarge(entry: entry)
        }
    }
}

private struct AASmall: View {
    let entry: AssetAllocEntry
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Label("Allocation", systemImage: "chart.pie.fill")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
            Spacer()
            if entry.data.slices.isEmpty {
                Text("No data").font(.caption).foregroundStyle(.secondary)
            } else {
                DonutChart(slices: entry.data.slices).frame(width: 90, height: 90).frame(maxWidth: .infinity)
                if let top = entry.data.slices.first {
                    HStack(spacing: 4) {
                        Circle().fill(allocColor(top.colorIndex)).frame(width: 6, height: 6)
                        Text(top.label).font(.caption2).lineLimit(1)
                        Spacer()
                        Text(String(format: "%.0f%%", top.value)).font(.caption2).fontWeight(.semibold)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }
}

private struct AAMedium: View {
    let entry: AssetAllocEntry
    var body: some View {
        VStack (alignment: .leading) {
            if entry.data.slices.isEmpty {
                Text("No data").font(.subheadline).foregroundStyle(.secondary)
            } else {
                Label("Allocation", systemImage: "chart.pie.fill")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
                
                HStack(spacing: 16) {
                    DonutChart(slices: entry.data.slices).frame(width: 100, height: 100)
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(entry.data.slices.prefix(4)) { s in
                            HStack(spacing: 8) {
                                Circle().fill(allocColor(s.colorIndex)).frame(width: 8, height: 8)
                                Text(s.label).font(.caption).lineLimit(1)
                                Spacer()
                                Text(String(format: "%.0f%%", s.value)).font(.caption).fontWeight(.semibold).foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

private struct AALarge: View {
    let entry: AssetAllocEntry
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Asset Allocation", systemImage: "chart.pie.fill")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
            if entry.data.slices.isEmpty {
                Spacer()
                Text("No assets yet").font(.subheadline).foregroundStyle(.secondary).frame(maxWidth: .infinity)
                Spacer()
            } else {
                Spacer()
                
                HStack { Spacer(); DonutChart(slices: entry.data.slices).frame(width: 120, height: 120); Spacer() }
                Spacer()
                
                Divider()
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(entry.data.slices) { s in
                        HStack(spacing: 10) {
                            Circle().fill(allocColor(s.colorIndex)).frame(width: 8, height: 8)
                            Text(s.label).font(.subheadline).lineLimit(1)
                            Spacer()
                            Text(String(format: "%.1f%%", s.value)).font(.subheadline).fontWeight(.semibold).foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

#Preview(as: .systemSmall)  { AssetAllocationWidget() } timeline: { AssetAllocEntry.placeholder }
#Preview(as: .systemMedium) { AssetAllocationWidget() } timeline: { AssetAllocEntry.placeholder }
#Preview(as: .systemLarge)  { AssetAllocationWidget() } timeline: { AssetAllocEntry.placeholder }
