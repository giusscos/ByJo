//
//  SpendmeterWidget.swift
//  ByJoWidget
//

import WidgetKit
import SwiftUI

struct SpendmeterEntry: TimelineEntry {
    let date: Date
    let data: WSpendmeterData
    static var placeholder: SpendmeterEntry {
        SpendmeterEntry(date: Date(), data: WSpendmeterData(
            inflow: 3200, outflow: 1800, savedAmount: 1400, ratio: 0.56, currencyCode: "USD", updatedAt: Date()))
    }
}

struct SpendmeterProvider: TimelineProvider {
    func placeholder(in context: Context) -> SpendmeterEntry { .placeholder }
    func getSnapshot(in context: Context, completion: @escaping (SpendmeterEntry) -> Void) {
        completion(SpendmeterEntry(date: Date(),
            data: UserDefaults.appGroup?.decode(WSpendmeterData.self, forKey: .spendmeter) ?? SpendmeterEntry.placeholder.data))
    }
    func getTimeline(in context: Context, completion: @escaping (Timeline<SpendmeterEntry>) -> Void) {
        let data = UserDefaults.appGroup?.decode(WSpendmeterData.self, forKey: .spendmeter) ?? SpendmeterEntry.placeholder.data
        let next = Calendar.current.date(byAdding: .minute, value: 30, to: Date())!
        completion(Timeline(entries: [SpendmeterEntry(date: Date(), data: data)], policy: .after(next)))
    }
}

struct SpendmeterWidget: Widget {
    let kind = "SpendmeterWidget"
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: SpendmeterProvider()) { entry in
            SpendmeterWidgetView(entry: entry).containerBackground(.background, for: .widget)
        }
        .configurationDisplayName("Spendmeter")
        .description("This month's inflow vs. outflow ratio.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

// MARK: - Elliptical arc (static port of app's SpendmeterView arc)

private struct SpendArcView: View {
    var ratio: Double
    var trackWidth: CGFloat = 20

    private let startDeg: Double = 150
    private let sweepDeg: Double = 240

    private var capsuleAngleFraction: Double { max(0.18, min(ratio, 0.82)) }

    var body: some View {
        GeometryReader { geo in
            let rx: CGFloat = min(geo.size.width * 0.44, 175)
            let ry: CGFloat = rx * 0.56
            let center = CGPoint(x: geo.size.width / 2, y: geo.size.height - 8)
            let unitCenter = UnitPoint(x: 0.5, y: (geo.size.height - 8) / geo.size.height)

            let capsuleDeg = startDeg + capsuleAngleFraction * sweepDeg
            let capsuleRad = capsuleDeg * .pi / 180
            let capsuleX = center.x + rx * CGFloat(cos(capsuleRad))
            let capsuleY = center.y + ry * CGFloat(sin(capsuleRad))
            let tangentX = -rx * CGFloat(sin(capsuleRad))
            let tangentY = ry * CGFloat(cos(capsuleRad))
            let capsuleRotation = Angle(radians: Double(atan2(tangentY, tangentX)))

            let f = capsuleAngleFraction
            let focusMask = AngularGradient(
                stops: [
                    .init(color: .black.opacity(0),   location: 0),
                    .init(color: .black.opacity(0),   location: max(0, f - 0.22)),
                    .init(color: .black,              location: max(0, f - 0.08)),
                    .init(color: .black,              location: min(1, f + 0.08)),
                    .init(color: .black.opacity(0),   location: min(1, f + 0.22)),
                    .init(color: .black.opacity(0),   location: 1),
                ],
                center: unitCenter,
                startAngle: .degrees(startDeg),
                endAngle: .degrees(startDeg + sweepDeg)
            )

            ZStack {
                arcPath(center: center, rx: rx, ry: ry)
                    .stroke(arcGradient(unitCenter: unitCenter),
                            style: StrokeStyle(lineWidth: trackWidth, lineCap: .round))
                    .blur(radius: 4)

                arcPath(center: center, rx: rx, ry: ry)
                    .stroke(arcGradient(unitCenter: unitCenter),
                            style: StrokeStyle(lineWidth: trackWidth, lineCap: .round))
                    .mask(Rectangle().fill(focusMask))

                Text("\(Int(ratio * 100))%")
                    .font(.system(size: 10, weight: .semibold, design: .rounded))
                    .monospacedDigit()
                    .padding(.horizontal, 8).padding(.vertical, 4)
                    .background(.ultraThinMaterial, in: Capsule())
                    .overlay(Capsule().strokeBorder(Color.primary.opacity(0.2), lineWidth: 0.5))
                    .rotationEffect(capsuleRotation)
                    .position(x: capsuleX, y: capsuleY)
            }
        }
    }

    private func arcPath(center: CGPoint, rx: CGFloat, ry: CGFloat) -> Path {
        var path = Path()
        let segAngle = sweepDeg / 6
        for i in 0..<6 {
            let a1 = (startDeg + Double(i) * segAngle) * .pi / 180
            let a2 = (startDeg + Double(i + 1) * segAngle) * .pi / 180
            let alpha = CGFloat(4.0 / 3.0 * tan((a2 - a1) / 4.0))
            let cos1 = CGFloat(cos(a1)), sin1 = CGFloat(sin(a1))
            let cos2 = CGFloat(cos(a2)), sin2 = CGFloat(sin(a2))
            let p0 = CGPoint(x: center.x + rx * cos1, y: center.y + ry * sin1)
            let p3 = CGPoint(x: center.x + rx * cos2, y: center.y + ry * sin2)
            let p1 = CGPoint(x: p0.x - alpha * rx * sin1, y: p0.y + alpha * ry * cos1)
            let p2 = CGPoint(x: p3.x + alpha * rx * sin2, y: p3.y - alpha * ry * cos2)
            if i == 0 { path.move(to: p0) }
            path.addCurve(to: p3, control1: p1, control2: p2)
        }
        return path
    }

    private func arcGradient(unitCenter: UnitPoint) -> AngularGradient {
        AngularGradient(
            stops: [
                .init(color: .green.opacity(0),  location: 0),
                .init(color: .green,             location: 0.07),
                .init(color: .yellow,            location: 0.50),
                .init(color: .orange,            location: 0.70),
                .init(color: .red,               location: 0.93),
                .init(color: .red.opacity(0),    location: 1.0),
            ],
            center: unitCenter,
            startAngle: .degrees(startDeg),
            endAngle: .degrees(startDeg + sweepDeg)
        )
    }
}

// MARK: - Value display (matches app's sign / number / symbol layout)

private struct SpendValueView: View {
    let savedAmount: Double
    let currencyCode: String
    let fontSize: CGFloat

    var isPositive: Bool { savedAmount >= 0 }

    var currencySymbol: String {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.currencyCode = currencyCode
        return f.currencySymbol ?? currencyCode
    }

    var body: some View {
        HStack(alignment: .top, spacing: 2) {
            Text(isPositive ? "+" : "-")
                .font(.system(size: fontSize, weight: .bold, design: .rounded))
            Text(String(format: "%.0f", abs(savedAmount)))
                .font(.system(size: fontSize, weight: .bold, design: .rounded))
                .monospacedDigit()
                .minimumScaleFactor(0.5)
                .lineLimit(1)
            Text(currencySymbol)
                .font(.system(size: fontSize * 0.55, weight: .semibold, design: .rounded))
                .foregroundStyle(.secondary)
                .padding(.top, fontSize * 0.15)
        }
        .foregroundStyle(isPositive ? Color.primary : Color.red)
    }
}

private func sFmt(_ v: Double, currency: String) -> String {
    let f = NumberFormatter(); f.numberStyle = .currency; f.currencyCode = currency; f.maximumFractionDigits = 0
    return f.string(from: NSNumber(value: v)) ?? "\(v)"
}

// MARK: - Widget views

struct SpendmeterWidgetView: View {
    @Environment(\.widgetFamily) var family
    let entry: SpendmeterEntry
    var body: some View {
        switch family {
        case .systemSmall:  SMSmall(entry: entry)
        case .systemMedium: SMMedium(entry: entry)
        default:            SMLarge(entry: entry)
        }
    }
}

private struct SMSmall: View {
    let entry: SpendmeterEntry
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Label("Spendmeter", systemImage: "gauge.with.needle")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
            Spacer()
            SpendValueView(savedAmount: entry.data.savedAmount, currencyCode: entry.data.currencyCode, fontSize: 24)
            SpendArcView(ratio: entry.data.ratio, trackWidth: 20)
                .offset(y: 28)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }
}

private struct SMMedium: View {
    let entry: SpendmeterEntry
    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Label("Spendmeter", systemImage: "gauge.with.needle")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
                Spacer()
                SpendValueView(savedAmount: entry.data.savedAmount, currencyCode: entry.data.currencyCode, fontSize: 26)
                SpendArcView(ratio: entry.data.ratio, trackWidth: 20)
                    .frame(height: 80)
                    .offset(y: 20)
            }
            Divider()
            VStack(alignment: .leading, spacing: 10) {
                VStack(alignment: .leading, spacing: 2) {
                    Label("Inflow", systemImage: "arrow.up.circle.fill").font(.caption2).foregroundStyle(.green)
                    Text(sFmt(entry.data.inflow, currency: entry.data.currencyCode)).font(.subheadline).fontWeight(.semibold)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Label("Outflow", systemImage: "arrow.down.circle.fill").font(.caption2).foregroundStyle(.red)
                    Text(sFmt(entry.data.outflow, currency: entry.data.currencyCode)).font(.subheadline).fontWeight(.semibold)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

private struct SMLarge: View {
    let entry: SpendmeterEntry
    var isPositive: Bool { entry.data.savedAmount >= 0 }
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Spendmeter", systemImage: "gauge.with.needle")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
            HStack(spacing: 0) {
                Spacer()
                VStack(spacing: 2) {
                    Image(systemName: "arrow.up.circle.fill").foregroundStyle(.green)
                    Text("Inflow").font(.caption2).foregroundStyle(.secondary)
                    Text(sFmt(entry.data.inflow, currency: entry.data.currencyCode)).font(.subheadline).fontWeight(.semibold)
                }
                Spacer(); Divider().frame(height: 44); Spacer()
                VStack(spacing: 2) {
                    Image(systemName: "arrow.down.circle.fill").foregroundStyle(.red)
                    Text("Outflow").font(.caption2).foregroundStyle(.secondary)
                    Text(sFmt(entry.data.outflow, currency: entry.data.currencyCode)).font(.subheadline).fontWeight(.semibold)
                }
                Spacer()
            }
            Divider()
            Spacer()
            SpendValueView(savedAmount: entry.data.savedAmount, currencyCode: entry.data.currencyCode, fontSize: 48)
                .frame(maxWidth: .infinity)
            SpendArcView(ratio: entry.data.ratio, trackWidth: 24)
                .offset(y: 24)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

#Preview(as: .systemSmall)  { SpendmeterWidget() } timeline: { SpendmeterEntry.placeholder }
#Preview(as: .systemMedium) { SpendmeterWidget() } timeline: { SpendmeterEntry.placeholder }
#Preview(as: .systemLarge)  { SpendmeterWidget() } timeline: { SpendmeterEntry.placeholder }
