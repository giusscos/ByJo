//
//  GoalWidget.swift
//  ByJoWidget
//

import WidgetKit
import SwiftUI

struct GoalEntry: TimelineEntry {
    let date: Date
    let data: WGoalData
    static var placeholder: GoalEntry {
        let ny = Calendar.current.date(byAdding: .year, value: 1, to: Date())
        return GoalEntry(date: Date(), data: WGoalData(goals: [
            .init(id: "1", title: "Emergency Fund", currentAmount: 6200,  targetAmount: 10000, startingAmount: 0, assetName: "Savings",  dueDate: ny, progress: 0.62),
            .init(id: "2", title: "New Car",         currentAmount: 3400,  targetAmount: 20000, startingAmount: 0, assetName: "Savings",  dueDate: nil, progress: 0.17),
            .init(id: "3", title: "Vacation",        currentAmount: 800,   targetAmount: 3000,  startingAmount: 0, assetName: "Checking", dueDate: ny, progress: 0.27),
            .init(id: "4", title: "MacBook",         currentAmount: 1800,  targetAmount: 2400,  startingAmount: 0, assetName: "Checking", dueDate: nil, progress: 0.75),
        ], currencyCode: "USD", updatedAt: Date()))
    }
}

struct GoalProvider: TimelineProvider {
    func placeholder(in context: Context) -> GoalEntry { .placeholder }
    func getSnapshot(in context: Context, completion: @escaping (GoalEntry) -> Void) {
        completion(GoalEntry(date: Date(),
            data: UserDefaults.appGroup?.decode(WGoalData.self, forKey: .goals) ?? GoalEntry.placeholder.data))
    }
    func getTimeline(in context: Context, completion: @escaping (Timeline<GoalEntry>) -> Void) {
        let data = UserDefaults.appGroup?.decode(WGoalData.self, forKey: .goals) ?? GoalEntry.placeholder.data
        let next = Calendar.current.date(byAdding: .minute, value: 30, to: Date())!
        completion(Timeline(entries: [GoalEntry(date: Date(), data: data)], policy: .after(next)))
    }
}

struct GoalWidget: Widget {
    let kind = "GoalWidget"
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: GoalProvider()) { entry in
            GoalWidgetView(entry: entry).containerBackground(.background, for: .widget)
        }
        .configurationDisplayName("Goals")
        .description("Track your financial goals.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

private func gFmt(_ v: Double, currency: String) -> String {
    let f = NumberFormatter(); f.numberStyle = .currency; f.currencyCode = currency; f.maximumFractionDigits = 0
    return f.string(from: NSNumber(value: v)) ?? "\(v)"
}
private func gColor(_ p: Double) -> Color { p >= 1.0 ? .green : p >= 0.5 ? .blue : .orange }

private struct CircularProgress: View {
    let progress: Double; let size: CGFloat
    var body: some View {
        ZStack {
            Circle().stroke(Color.secondary.opacity(0.15), lineWidth: size * 0.1)
            Circle().trim(from: 0, to: min(progress, 1))
                .stroke(gColor(progress), style: StrokeStyle(lineWidth: size * 0.1, lineCap: .round))
                .rotationEffect(.degrees(-90))
            Text("\(Int(progress * 100))%")
                .font(.system(size: size * 0.22, weight: .bold, design: .rounded))
        }.frame(width: size, height: size)
    }
}

private struct GoalRow: View {
    let goal: WGoalData.GoalItem; let currencyCode: String
    var body: some View {
        HStack(spacing: 10) {
            CircularProgress(progress: goal.progress, size: 36)
            VStack(alignment: .leading, spacing: 2) {
                Text(goal.title).font(.subheadline).fontWeight(.medium).lineLimit(1)
                Text(goal.assetName).font(.caption2).foregroundStyle(.secondary).lineLimit(1)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text(gFmt(goal.currentAmount, currency: currencyCode)).font(.subheadline).fontWeight(.semibold)
                Text("/ " + gFmt(goal.targetAmount, currency: currencyCode)).font(.caption2).foregroundStyle(.secondary)
            }
        }
    }
}

struct GoalWidgetView: View {
    @Environment(\.widgetFamily) var family
    let entry: GoalEntry
    var body: some View {
        switch family {
        case .systemSmall:  GSmall(entry: entry)
        case .systemMedium: GMedium(entry: entry)
        default:            GLarge(entry: entry)
        }
    }
}

private struct GSmall: View {
    let entry: GoalEntry
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Label("Goals", systemImage: "target")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
            Spacer()
            if let g = entry.data.goals.first {
                CircularProgress(progress: g.progress, size: 48)
                
                Spacer()
                
                VStack (alignment: .leading, spacing: 2) {
                    Text(g.title).font(.caption).fontWeight(.semibold).lineLimit(1)
                    Text(gFmt(g.currentAmount, currency: entry.data.currencyCode) + " / " + gFmt(g.targetAmount, currency: entry.data.currencyCode))
                        .font(.caption2).foregroundStyle(.secondary).lineLimit(1).minimumScaleFactor(0.7)
                }
            } else {
                Text("No active\ngoals").font(.caption).foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }
}

private struct GMedium: View {
    let entry: GoalEntry
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Goals", systemImage: "target")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
            if entry.data.goals.isEmpty {
                Spacer(); Text("No active goals").font(.subheadline).foregroundStyle(.secondary); Spacer()
            } else {
                ForEach(Array(entry.data.goals.prefix(2).enumerated()), id: \.element.id) { idx, goal in
                    GoalRow(goal: goal, currencyCode: entry.data.currencyCode)
                    if idx == 0 && entry.data.goals.count > 1 { Divider() }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

private struct GLarge: View {
    let entry: GoalEntry
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Financial Goals", systemImage: "target").font(.subheadline.weight(.semibold)).foregroundStyle(.secondary)
            if entry.data.goals.isEmpty {
                Spacer(); Text("No active goals yet").font(.subheadline).foregroundStyle(.secondary).frame(maxWidth: .infinity); Spacer()
            } else {
                Spacer()
                
                ForEach(Array(entry.data.goals.prefix(4).enumerated()), id: \.element.id) { idx, goal in
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text(goal.title).font(.subheadline).fontWeight(.medium).lineLimit(1)
                            Spacer()
                            Text("\(Int(goal.progress * 100))%").font(.caption).fontWeight(.semibold).foregroundStyle(gColor(goal.progress))
                        }
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                Capsule().fill(Color.secondary.opacity(0.15)).frame(height: 6)
                                Capsule().fill(gColor(goal.progress)).frame(width: max(0, geo.size.width * goal.progress), height: 6)
                            }
                        }.frame(height: 6)
                        HStack {
                            Text(goal.assetName).font(.caption2).foregroundStyle(.secondary)
                            Spacer()
                            Text(gFmt(goal.currentAmount, currency: entry.data.currencyCode) + " / " + gFmt(goal.targetAmount, currency: entry.data.currencyCode))
                                .font(.caption2).foregroundStyle(.secondary)
                        }
                    }
                    if idx < min(entry.data.goals.count, 4) - 1 { Divider() }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

#Preview(as: .systemSmall)  { GoalWidget() } timeline: { GoalEntry.placeholder }
#Preview(as: .systemMedium) { GoalWidget() } timeline: { GoalEntry.placeholder }
#Preview(as: .systemLarge)  { GoalWidget() } timeline: { GoalEntry.placeholder }
