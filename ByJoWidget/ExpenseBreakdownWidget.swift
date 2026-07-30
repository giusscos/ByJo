//
//  ExpenseBreakdownWidget.swift
//  ByJoWidget
//

import WidgetKit
import SwiftUI
import Charts

struct ExpenseBreakdownEntry: TimelineEntry {
    let date: Date
    let data: WExpenseBreakdownData
    static var placeholder: ExpenseBreakdownEntry {
        ExpenseBreakdownEntry(date: Date(), data: WExpenseBreakdownData(slices: [
            .init(id: "1", label: "Food",      value: 35, amount: 420, colorIndex: 0),
            .init(id: "2", label: "Rent",      value: 30, amount: 360, colorIndex: 1),
            .init(id: "3", label: "Transport", value: 20, amount: 240, colorIndex: 2),
            .init(id: "4", label: "Other",     value: 15, amount: 180, colorIndex: 3),
        ], currencyCode: "USD", compactNumber: true, updatedAt: Date()))
    }
}

struct ExpenseBreakdownProvider: TimelineProvider {
    func placeholder(in context: Context) -> ExpenseBreakdownEntry { .placeholder }
    func getSnapshot(in context: Context, completion: @escaping (ExpenseBreakdownEntry) -> Void) {
        completion(ExpenseBreakdownEntry(date: Date(),
            data: UserDefaults.appGroup?.decode(WExpenseBreakdownData.self, forKey: .expenseBreakdown) ?? ExpenseBreakdownEntry.placeholder.data))
    }
    func getTimeline(in context: Context, completion: @escaping (Timeline<ExpenseBreakdownEntry>) -> Void) {
        let data = UserDefaults.appGroup?.decode(WExpenseBreakdownData.self, forKey: .expenseBreakdown) ?? ExpenseBreakdownEntry.placeholder.data
        let next = Calendar.current.date(byAdding: .minute, value: 30, to: Date())!
        completion(Timeline(entries: [ExpenseBreakdownEntry(date: Date(), data: data)], policy: .after(next)))
    }
}

struct ExpenseBreakdownWidget: Widget {
    let kind = "ExpenseBreakdownWidget"
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: ExpenseBreakdownProvider()) { entry in
            ExpenseBreakdownWidgetView(entry: entry).containerBackground(.background, for: .widget)
        }
        .configurationDisplayName("Expense Breakdown")
        .description("This month's expenses by category.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

private let ebPalette: [Color] = [.red, .orange, .pink, .purple, .indigo, .blue, .green, .cyan]
private func ebColor(_ i: Int) -> Color { ebPalette[i % ebPalette.count] }

private func ebFmt(_ v: Double, currency: String, compact: Bool) -> String {
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

private struct EBDonut: View {
    let slices: [WExpenseBreakdownData.Slice]
    var body: some View {
        Chart(slices) { s in
            SectorMark(angle: .value("Value", s.value), innerRadius: .ratio(0.55), angularInset: 2)
                .foregroundStyle(ebColor(s.colorIndex)).cornerRadius(4)
        }
    }
}

struct ExpenseBreakdownWidgetView: View {
    @Environment(\.widgetFamily) var family
    let entry: ExpenseBreakdownEntry
    var body: some View {
        switch family {
        case .systemSmall:  EBSmall(entry: entry)
        case .systemMedium: EBMedium(entry: entry)
        default:            EBLarge(entry: entry)
        }
    }
}

private struct EBSmall: View {
    let entry: ExpenseBreakdownEntry
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Label("Expenses", systemImage: "chart.pie.fill")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
            Spacer()
            if entry.data.slices.isEmpty {
                Text("No data").font(.caption).foregroundStyle(.secondary)
            } else {
                EBDonut(slices: entry.data.slices).frame(width: 90, height: 90).frame(maxWidth: .infinity)
                if let top = entry.data.slices.first {
                    HStack(spacing: 4) {
                        Circle().fill(ebColor(top.colorIndex)).frame(width: 6, height: 6)
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

private struct EBMedium: View {
    let entry: ExpenseBreakdownEntry
    var body: some View {
        VStack(alignment: .leading) {
            if entry.data.slices.isEmpty {
                Text("No data").font(.subheadline).foregroundStyle(.secondary)
            } else {
                Label("Expense Breakdown", systemImage: "chart.pie.fill")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)

                HStack(spacing: 16) {
                    EBDonut(slices: entry.data.slices).frame(width: 100, height: 100)
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(entry.data.slices.prefix(4)) { s in
                            HStack(spacing: 8) {
                                Circle().fill(ebColor(s.colorIndex)).frame(width: 8, height: 8)
                                Text(s.label).font(.caption).lineLimit(1)
                                Spacer()
                                Text(ebFmt(s.amount, currency: entry.data.currencyCode, compact: entry.data.compactNumber))
                                    .font(.caption).fontWeight(.semibold).foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

private struct EBLarge: View {
    let entry: ExpenseBreakdownEntry
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Expense Breakdown", systemImage: "chart.pie.fill")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
            if entry.data.slices.isEmpty {
                Spacer()
                Text("No expenses this month").font(.subheadline).foregroundStyle(.secondary).frame(maxWidth: .infinity)
                Spacer()
            } else {
                Spacer()
                HStack { Spacer(); EBDonut(slices: entry.data.slices).frame(width: 120, height: 120); Spacer() }
                Spacer()
                Divider()
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(entry.data.slices.prefix(8)) { s in
                        HStack(spacing: 10) {
                            Circle().fill(ebColor(s.colorIndex)).frame(width: 8, height: 8)
                            Text(s.label).font(.subheadline).lineLimit(1)
                            Spacer()
                            Text(ebFmt(s.amount, currency: entry.data.currencyCode, compact: entry.data.compactNumber))
                                .font(.subheadline).fontWeight(.semibold).foregroundStyle(.secondary)
                            Text(String(format: "%.0f%%", s.value))
                                .font(.caption).foregroundStyle(.tertiary)
                                .frame(width: 36, alignment: .trailing)
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

#Preview(as: .systemSmall)  { ExpenseBreakdownWidget() } timeline: { ExpenseBreakdownEntry.placeholder }
#Preview(as: .systemMedium) { ExpenseBreakdownWidget() } timeline: { ExpenseBreakdownEntry.placeholder }
#Preview(as: .systemLarge)  { ExpenseBreakdownWidget() } timeline: { ExpenseBreakdownEntry.placeholder }
