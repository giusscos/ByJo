//
//  SavingsRateWidget.swift
//  ByJoWidget
//

import WidgetKit
import SwiftUI

struct SavingsRateEntry: TimelineEntry {
    let date: Date
    let data: WSavingsRateData
    static var placeholder: SavingsRateEntry {
        SavingsRateEntry(date: Date(), data: WSavingsRateData(rate: 0.32, inflow: 3200, outflow: 2176, currencyCode: "USD", updatedAt: Date()))
    }
}

struct SavingsRateProvider: TimelineProvider {
    func placeholder(in context: Context) -> SavingsRateEntry { .placeholder }
    func getSnapshot(in context: Context, completion: @escaping (SavingsRateEntry) -> Void) {
        completion(SavingsRateEntry(date: Date(),
            data: UserDefaults.appGroup?.decode(WSavingsRateData.self, forKey: .savingsRate) ?? SavingsRateEntry.placeholder.data))
    }
    func getTimeline(in context: Context, completion: @escaping (Timeline<SavingsRateEntry>) -> Void) {
        let data = UserDefaults.appGroup?.decode(WSavingsRateData.self, forKey: .savingsRate) ?? SavingsRateEntry.placeholder.data
        let next = Calendar.current.date(byAdding: .minute, value: 30, to: Date())!
        completion(Timeline(entries: [SavingsRateEntry(date: Date(), data: data)], policy: .after(next)))
    }
}

struct SavingsRateWidget: Widget {
    let kind = "SavingsRateWidget"
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: SavingsRateProvider()) { entry in
            SavingsRateWidgetViewKit(entry: entry).containerBackground(.background, for: .widget)
        }
        .configurationDisplayName("Savings Rate")
        .description("Your monthly savings rate.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

private func srColor(_ r: Double) -> Color { r >= 0.20 ? .green : r >= 0.10 ? .yellow : .red }
private func srLabel(_ r: Double) -> String { r >= 0.20 ? "Great" : r >= 0.10 ? "OK" : "Low" }
private func srFmt(_ v: Double, currency: String) -> String {
    let f = NumberFormatter(); f.numberStyle = .currency; f.currencyCode = currency; f.maximumFractionDigits = 0
    return f.string(from: NSNumber(value: v)) ?? "\(v)"
}

private struct RateBar: View {
    let rate: Double
    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(Color.secondary.opacity(0.15)).frame(height: 8)
                Capsule().fill(srColor(rate)).frame(width: max(0, geo.size.width * rate), height: 8)
            }
        }.frame(height: 8)
    }
}

struct SavingsRateWidgetViewKit: View {
    @Environment(\.widgetFamily) var family
    let entry: SavingsRateEntry
    var body: some View {
        switch family {
        case .systemSmall:  SRSmall(entry: entry)
        case .systemMedium: SRMedium(entry: entry)
        default:            SRLarge(entry: entry)
        }
    }
}

private struct SRSmall: View {
    let entry: SavingsRateEntry
    var pct: Int { Int((entry.data.rate * 100).rounded()) }
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Label("Savings Rate", systemImage: "percent")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
            Spacer()
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text("\(pct)")
                    .font(.title.weight(.black))
                    .fontDesign(.rounded)
                    .foregroundStyle(srColor(entry.data.rate))
                Text("%")
                    .font(.title3.bold())
                    .fontDesign(.rounded)
                    .foregroundStyle(srColor(entry.data.rate))
            }
            Text(srLabel(entry.data.rate)).font(.caption).foregroundStyle(srColor(entry.data.rate))
            RateBar(rate: entry.data.rate)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }
}

private struct SRMedium: View {
    let entry: SavingsRateEntry
    var pct: Int { Int((entry.data.rate * 100).rounded()) }
    var body: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                Label("Savings Rate", systemImage: "percent")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
                Spacer()
                
                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text("\(pct)")
                        .font(.title.weight(.black))
                        .fontDesign(.rounded)
                        .foregroundStyle(srColor(entry.data.rate))
                    Text("%").font(.system(.title3, design: .rounded, weight: .bold)).foregroundStyle(srColor(entry.data.rate))
                }
                
                RateBar(rate: entry.data.rate)
                
                Spacer()
            }
            Divider()
            VStack(alignment: .leading, spacing: 10) {
                VStack(alignment: .leading, spacing: 2) {
                    Label("Inflow", systemImage: "arrow.up.circle.fill").font(.caption2).foregroundStyle(.green)
                    Text(srFmt(entry.data.inflow, currency: entry.data.currencyCode)).font(.subheadline).fontWeight(.semibold)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Label("Outflow", systemImage: "arrow.down.circle.fill").font(.caption2).foregroundStyle(.red)
                    Text(srFmt(entry.data.outflow, currency: entry.data.currencyCode)).font(.subheadline).fontWeight(.semibold)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

private struct SRLarge: View {
    let entry: SavingsRateEntry
    var pct: Int { Int((entry.data.rate * 100).rounded()) }
    var saved: Double { entry.data.inflow - entry.data.outflow }
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Monthly Savings Rate", systemImage: "percent")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
            
            Spacer()
            
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text("\(pct)").font(.system(size: 64, weight: .black, design: .rounded)).foregroundStyle(srColor(entry.data.rate))
                VStack(alignment: .leading, spacing: 2) {
                    Text("%")
                        .font(.title.bold())
                        .fontDesign(.rounded)
                        .foregroundStyle(srColor(entry.data.rate))
                    Text(srLabel(entry.data.rate)).font(.caption).fontWeight(.semibold).foregroundStyle(srColor(entry.data.rate))
                }
            }
            RateBar(rate: entry.data.rate)
            Divider()
            HStack(spacing: 0) {
                Spacer()
                VStack(spacing: 2) {
                    Image(systemName: "arrow.up.circle.fill").foregroundStyle(.green)
                    Text("Inflow").font(.caption2).foregroundStyle(.secondary)
                    Text(srFmt(entry.data.inflow, currency: entry.data.currencyCode)).font(.subheadline).fontWeight(.semibold)
                }
                Spacer(); Divider().frame(height: 44); Spacer()
                VStack(spacing: 2) {
                    Image(systemName: "arrow.down.circle.fill").foregroundStyle(.red)
                    Text("Outflow").font(.caption2).foregroundStyle(.secondary)
                    Text(srFmt(entry.data.outflow, currency: entry.data.currencyCode)).font(.subheadline).fontWeight(.semibold)
                }
                Spacer(); Divider().frame(height: 44); Spacer()
                VStack(spacing: 2) {
                    Image(systemName: saved >= 0 ? "banknote" : "exclamationmark.circle").foregroundStyle(saved >= 0 ? .green : .red)
                    Text("Saved").font(.caption2).foregroundStyle(.secondary)
                    Text(srFmt(abs(saved), currency: entry.data.currencyCode))
                        .font(.subheadline).fontWeight(.semibold).foregroundStyle(saved >= 0 ? Color.primary : Color.red)
                }
                Spacer()
            }
            Divider()
            HStack {
                Label("≥20% great", systemImage: "circle.fill").foregroundStyle(.green)
                Spacer()
                Label("10–20% ok", systemImage: "circle.fill").foregroundStyle(.yellow)
                Spacer()
                Label("<10% low", systemImage: "circle.fill").foregroundStyle(.red)
            }
            .font(.caption2).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

#Preview(as: .systemSmall)  { SavingsRateWidget() } timeline: { SavingsRateEntry.placeholder }
#Preview(as: .systemMedium) { SavingsRateWidget() } timeline: { SavingsRateEntry.placeholder }
#Preview(as: .systemLarge)  { SavingsRateWidget() } timeline: { SavingsRateEntry.placeholder }
