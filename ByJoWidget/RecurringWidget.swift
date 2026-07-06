//
//  RecurringWidget.swift
//  ByJoWidget
//

import WidgetKit
import SwiftUI

struct RecurringEntry: TimelineEntry {
    let date: Date
    let data: WRecurringData
    static var placeholder: RecurringEntry {
        let d1 = Calendar.current.date(byAdding: .day, value: 1, to: Date())!
        let d7 = Calendar.current.date(byAdding: .day, value: 7, to: Date())!
        let d30 = Calendar.current.date(byAdding: .month, value: 1, to: Date())!
        return RecurringEntry(date: Date(), data: WRecurringData(items: [
            .init(id: "1", name: "Netflix",   amount: 15.99, nextDate: d1,  frequencyLabel: "Monthly", assetName: "Checking", isIncome: false),
            .init(id: "2", name: "Salary",    amount: 3200,  nextDate: d7,  frequencyLabel: "Monthly", assetName: "Savings",  isIncome: true),
            .init(id: "3", name: "Gym",       amount: 40,    nextDate: d30, frequencyLabel: "Monthly", assetName: "Card",     isIncome: false),
            .init(id: "4", name: "Rent",      amount: 1200,  nextDate: d30, frequencyLabel: "Monthly", assetName: "Checking", isIncome: false),
            .init(id: "5", name: "Dividends", amount: 85,    nextDate: d30, frequencyLabel: "Monthly", assetName: "Stocks",   isIncome: true),
            .init(id: "6", name: "Dividends", amount: 85,    nextDate: d30, frequencyLabel: "Monthly", assetName: "Stocks",   isIncome: true),
        ], currencyCode: "USD", updatedAt: Date()))
    }
}

struct RecurringProvider: TimelineProvider {
    func placeholder(in context: Context) -> RecurringEntry { .placeholder }
    func getSnapshot(in context: Context, completion: @escaping (RecurringEntry) -> Void) {
        completion(RecurringEntry(date: Date(),
            data: UserDefaults.appGroup?.decode(WRecurringData.self, forKey: .recurring) ?? RecurringEntry.placeholder.data))
    }
    func getTimeline(in context: Context, completion: @escaping (Timeline<RecurringEntry>) -> Void) {
        let data = UserDefaults.appGroup?.decode(WRecurringData.self, forKey: .recurring) ?? RecurringEntry.placeholder.data
        let midnight = Calendar.current.startOfDay(for: Calendar.current.date(byAdding: .day, value: 1, to: Date())!)
        completion(Timeline(entries: [RecurringEntry(date: Date(), data: data)], policy: .after(midnight)))
    }
}

struct RecurringWidget: Widget {
    let kind = "RecurringWidget"
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: RecurringProvider()) { entry in
            RecurringWidgetView(entry: entry).containerBackground(.background, for: .widget)
        }
        .configurationDisplayName("Recurring Operations")
        .description("Upcoming recurring income and expenses.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

private func rFmt(_ v: Double, currency: String) -> String {
    let f = NumberFormatter(); f.numberStyle = .currency; f.currencyCode = currency; f.maximumFractionDigits = 0
    return f.string(from: NSNumber(value: v)) ?? "\(v)"
}

private func daysLabel(_ date: Date) -> String {
    let days = Calendar.current.dateComponents([.day],
        from: Calendar.current.startOfDay(for: Date()),
        to: Calendar.current.startOfDay(for: date)).day ?? 0
    if days == 0 { return "Today" }
    if days == 1 { return "Tomorrow" }
    return "in \(days)d"
}

private struct RRow: View {
    let item: WRecurringData.Item
    let currencyCode: String
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: item.isIncome ? "arrow.up.circle.fill" : "arrow.down.circle.fill")
                .foregroundStyle(item.isIncome ? .green : .red).font(.subheadline)
            VStack(alignment: .leading, spacing: 1) {
                Text(item.name).font(.subheadline).fontWeight(.medium).lineLimit(1)
                Text(item.assetName).font(.caption2).foregroundStyle(.secondary).lineLimit(1)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 1) {
                Text(rFmt(item.amount, currency: currencyCode))
                    .font(.subheadline).fontWeight(.semibold).foregroundStyle(item.isIncome ? .green : .primary)
                Text(daysLabel(item.nextDate)).font(.caption2).foregroundStyle(.secondary)
            }
        }
    }
}

struct RecurringWidgetView: View {
    @Environment(\.widgetFamily) var family
    let entry: RecurringEntry
    var body: some View {
        switch family {
        case .systemSmall:  RSmall(entry: entry)
        case .systemMedium: RMedium(entry: entry)
        default:            RLarge(entry: entry)
        }
    }
}

private struct RSmall: View {
    let entry: RecurringEntry
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label("Recurring", systemImage: "arrow.clockwise.circle.fill")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
            Spacer()
            if let item = entry.data.items.first {
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.name).font(.headline).lineLimit(1)
                    HStack(spacing: 4) {
                        Image(systemName: item.isIncome ? "arrow.up.circle.fill" : "arrow.down.circle.fill")
                            .foregroundStyle(item.isIncome ? .green : .red)
                        Text(rFmt(item.amount, currency: entry.data.currencyCode))
                            .font(.subheadline)
                            .fontWeight(.semibold)
                    }
                    Text(daysLabel(item.nextDate)).font(.caption).foregroundStyle(.secondary)
                }
            } else {
                Text("No recurring\noperations").font(.caption).foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }
}

private struct RMedium: View {
    let entry: RecurringEntry
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Next Recurring", systemImage: "arrow.clockwise.circle.fill")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
            if entry.data.items.isEmpty {
                Spacer(); Text("No recurring operations").font(.subheadline).foregroundStyle(.secondary); Spacer()
            } else {
                Spacer()
                
                ForEach(Array(entry.data.items.prefix(2).enumerated()), id: \.element.id) { idx, item in
                    RRow(item: item, currencyCode: entry.data.currencyCode)
                    if idx == 0 && entry.data.items.count > 1 { Divider() }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

private struct RLarge: View {
    let entry: RecurringEntry
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Next Recurring", systemImage: "arrow.clockwise.circle.fill")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
            if entry.data.items.isEmpty {
                Spacer(); Text("No recurring operations yet").font(.subheadline).foregroundStyle(.secondary).frame(maxWidth: .infinity); Spacer()
            } else {
                Spacer()
                
                ForEach(Array(entry.data.items.prefix(6).enumerated()), id: \.element.id) { idx, item in
                    RRow(item: item, currencyCode: entry.data.currencyCode)
                    if idx < min(entry.data.items.count, 6) - 1 { Divider() }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

#Preview(as: .systemSmall)  { RecurringWidget() } timeline: { RecurringEntry.placeholder }
#Preview(as: .systemMedium) { RecurringWidget() } timeline: { RecurringEntry.placeholder }
#Preview(as: .systemLarge)  { RecurringWidget() } timeline: { RecurringEntry.placeholder }
