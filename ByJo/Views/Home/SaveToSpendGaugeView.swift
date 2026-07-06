//
//  SaveToSpendGaugeView.swift
//  ByJo

import SwiftData
import SwiftUI
import UIKit

private enum SpendmeterTimeframe: String, CaseIterable {
    case day = "Day"
    case week = "Week"
    case month = "Month"
    case year = "Year"

    var dateRange: (startDate: Date, endDate: Date) {
        let calendar = Calendar.current
        let now = Date()
        switch self {
        case .day:
            let start = calendar.startOfDay(for: now)
            let end = calendar.date(byAdding: .day, value: 1, to: start)!
            return (start, end)
        case .week:
            return DateRangeOption.week.dateRange
        case .month:
            return DateRangeOption.month.dateRange
        case .year:
            return DateRangeOption.year.dateRange
        }
    }

    var previousRange: (startDate: Date, endDate: Date) {
        let calendar = Calendar.current
        let now = Date()
        switch self {
        case .day:
            let todayStart = calendar.startOfDay(for: now)
            let yesterdayStart = calendar.date(byAdding: .day, value: -1, to: todayStart)!
            return (yesterdayStart, todayStart)
        case .week:
            return DateRangeOption.week.previousRange
        case .month:
            return DateRangeOption.month.previousRange
        case .year:
            return DateRangeOption.year.previousRange
        }
    }

    var previousPeriodLabel: String {
        switch self {
        case .day:   return "yesterday"
        case .week:  return "last week"
        case .month: return "last month"
        case .year:  return "last year"
        }
    }
}

struct SaveToSpendGaugeView: View {
    @AppStorage("currencyCode") var currencyCode: CurrencyCode = .usd

    @Query var assets: [Asset]

    @State private var selectedTimeframe: SpendmeterTimeframe = .month

    private var allOperations: [AssetOperation] {
        assets.flatMap { $0.operations ?? [] }
    }

    private var income: Decimal {
        let range = selectedTimeframe.dateRange
        return allOperations
            .filter { $0.date >= range.startDate && $0.date <= range.endDate && $0.amount > 0 }
            .reduce(Decimal(0)) { $0 + $1.amount }
    }

    private var expenses: Decimal {
        let range = selectedTimeframe.dateRange
        return allOperations
            .filter { $0.date >= range.startDate && $0.date <= range.endDate && $0.amount < 0 }
            .reduce(Decimal(0)) { $0 + abs($1.amount) }
    }

    private var savedAmount: Decimal { income - expenses }

    private var spendingRatio: Double {
        guard income > 0 else { return expenses > 0 ? 1.0 : 0.0 }
        return min(max(NSDecimalNumber(decimal: expenses / income).doubleValue, 0), 1)
    }

    private var previousIncome: Decimal {
        let range = selectedTimeframe.previousRange
        return allOperations
            .filter { $0.date >= range.startDate && $0.date <= range.endDate && $0.amount > 0 }
            .reduce(Decimal(0)) { $0 + $1.amount }
    }

    private var previousExpenses: Decimal {
        let range = selectedTimeframe.previousRange
        return allOperations
            .filter { $0.date >= range.startDate && $0.date <= range.endDate && $0.amount < 0 }
            .reduce(Decimal(0)) { $0 + abs($1.amount) }
    }

    private var previousSavedAmount: Decimal { previousIncome - previousExpenses }

    private var hasPreviousData: Bool {
        let range = selectedTimeframe.previousRange
        return allOperations.contains { $0.date >= range.startDate && $0.date <= range.endDate }
    }

    var body: some View {
        if !assets.isEmpty {
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Spendmeter")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 16)

                    Picker("Timeframe", selection: $selectedTimeframe) {
                        ForEach(SpendmeterTimeframe.allCases, id: \.self) { tf in
                            Text(tf.rawValue).tag(tf)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)

                    SpendmeterView(
                        value: spendingRatio,
                        savedAmount: savedAmount,
                        currencyCode: currencyCode,
                        previousSavedAmount: previousSavedAmount,
                        timeframeLabel: selectedTimeframe.previousPeriodLabel,
                        hasPreviousData: hasPreviousData
                    )
                    .frame(maxWidth: .infinity)
                }
                .padding(.top)
                .listRowInsets(EdgeInsets())
            }
        }
    }
}

// MARK: - CADisplayLink spring driver

private final class DisplayLinkProxy: NSObject {
    var onTick: ((CADisplayLink) -> Void)?
    @objc func tick(_ link: CADisplayLink) { onTick?(link) }
}

@Observable
private final class SpringDriver {
    var current: Double

    private var target: Double
    private var velocity: Double = 0
    private var displayLink: CADisplayLink?
    private let proxy = DisplayLinkProxy()

    let response: Double
    let dampingFraction: Double

    init(value: Double, response: Double = 0.8, dampingFraction: Double = 0.7) {
        current = value
        target = value
        self.response = response
        self.dampingFraction = dampingFraction
        proxy.onTick = { [weak self] link in self?.tick(link) }
    }

    /// Snap to value immediately and cancel any running animation.
    func set(_ value: Double) {
        stop()
        current = value
        target = value
        velocity = 0
    }

    /// Animate toward newTarget, reusing the running display link if one exists.
    func animate(to newTarget: Double) {
        target = newTarget
        guard displayLink == nil else { return }
        let link = CADisplayLink(target: proxy, selector: #selector(DisplayLinkProxy.tick(_:)))
        link.add(to: .main, forMode: .common)
        displayLink = link
    }

    private func tick(_ link: CADisplayLink) {
        // Cap dt to avoid large jumps after the app is backgrounded.
        let dt = min(link.targetTimestamp - link.timestamp, 1.0 / 30)
        let omega = 2 * Double.pi / response
        let disp = current - target
        let acc = -omega * omega * disp - 2 * dampingFraction * omega * velocity
        velocity += acc * dt
        current += velocity * dt

        if abs(current - target) < 0.00005 && abs(velocity) < 0.00005 {
            current = target
            stop()
        }
    }

    private func stop() {
        displayLink?.invalidate()
        displayLink = nil
    }

    deinit { stop() }
}

// MARK: - Spendmeter

struct SpendmeterView: View {
    var value: Double
    var savedAmount: Decimal
    var currencyCode: CurrencyCode
    var previousSavedAmount: Decimal = 0
    var timeframeLabel: String = ""
    var hasPreviousData: Bool = false

    @State private var valueDriver = SpringDriver(value: 0.5, response: 1.3, dampingFraction: 0.72)
    @State private var savedDriver = SpringDriver(value: 0,   response: 1.3, dampingFraction: 0.72)
    @State private var hasAppeared = false

    private let startDeg: Double = 150
    private let sweepDeg: Double = 240
    private let trackWidth: CGFloat = 34.5

    private var endDeg: Double { startDeg + sweepDeg }

    // [0.18, 0.82] keeps the capsule visibly clear of the faded arc endpoints.
    private var capsuleAngleFraction: Double {
        max(0.18, min(valueDriver.current, 0.82))
    }

    private var insightDiff: Double {
        NSDecimalNumber(decimal: savedAmount - previousSavedAmount).doubleValue
    }

    private var insightSymbol: String {
        guard abs(insightDiff) >= 0.01 else { return "equal.circle.fill" }
        return insightDiff > 0 ? "arrow.up.circle.fill" : "arrow.down.circle.fill"
    }

    private var insightColor: Color {
        guard abs(insightDiff) >= 0.01 else { return .secondary }
        return insightDiff > 0 ? .green : .red
    }

    private var insightMessage: String {
        let prevDouble = NSDecimalNumber(decimal: previousSavedAmount).doubleValue
        let diff = insightDiff
        guard abs(diff) >= 0.01 else { return "Same as \(timeframeLabel)" }
        let direction = diff > 0 ? "more" : "less"
        let absPrev = abs(prevDouble)
        if absPrev >= 0.01 {
            let pct = Int(abs(diff / absPrev) * 100)
            return "\(pct)% \(direction) saved than \(timeframeLabel)"
        }
        return "\(diff > 0 ? "More" : "Less") saved than \(timeframeLabel)"
    }

    var body: some View {
        VStack(spacing: 6) {
            let isPositive = savedDriver.current >= 0
            let absVal = abs(savedDriver.current)

            HStack(alignment: .top, spacing: 2) {
                Text(isPositive ? "+" : "-")
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                Text(String(format: "%.0f", absVal))
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .contentTransition(.numericText(countsDown: !isPositive))
                Text(currencyCode.symbol)
                    .font(.system(size: 24, weight: .semibold, design: .rounded))
                    .foregroundStyle(.secondary)
                    .padding(.top, 7)
            }
            .foregroundStyle(isPositive ? Color.primary : Color.red)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 16)

            HStack(spacing: 6) {
                Image(systemName: insightSymbol)
                    .foregroundStyle(insightColor)
                Text(insightMessage)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .animation(.easeInOut(duration: 0.2), value: insightMessage)
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 16)
            .opacity(hasPreviousData ? 1 : 0)
            .scaleEffect(hasPreviousData ? 1 : 0.88, anchor: .top)
            .animation(.spring(response: 0.45, dampingFraction: 0.72), value: hasPreviousData)

            GeometryReader { geo in
                let rx: CGFloat = min(geo.size.width * 0.44, 175)
                let ry: CGFloat = rx * 0.56
                // 8 pt above the frame bottom — gives the capsule clearance at extreme fractions
                let center = CGPoint(x: geo.size.width / 2, y: geo.size.height - 8)
                let unitCenter = UnitPoint(x: 0.5, y: (geo.size.height - 8) / geo.size.height)

                let capsuleDeg = startDeg + capsuleAngleFraction * sweepDeg
                let capsuleRad = capsuleDeg * .pi / 180
                let capsuleX = center.x + rx * CGFloat(cos(capsuleRad))
                let capsuleY = center.y + ry * CGFloat(sin(capsuleRad))

                // Capsule rotated to match the ellipse tangent at the current angle
                let tangentX = -rx * CGFloat(sin(capsuleRad))
                let tangentY = ry * CGFloat(cos(capsuleRad))
                let capsuleRotation = Angle(radians: Double(atan2(tangentY, tangentX)))

                // Depth-of-field mask: opaque at the capsule angle, transparent at far ends
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
                    endAngle: .degrees(endDeg)
                )

                ZStack {
                    // Defocused background layer
                    ellipticalArcPath(center: center, rx: rx, ry: ry)
                        .stroke(arcGradient(unitCenter: unitCenter),
                                style: StrokeStyle(lineWidth: trackWidth, lineCap: .round))
                        .blur(radius: 9)

                    // Sharp layer visible only near the capsule angle
                    ellipticalArcPath(center: center, rx: rx, ry: ry)
                        .stroke(arcGradient(unitCenter: unitCenter),
                                style: StrokeStyle(lineWidth: trackWidth, lineCap: .round))
                        .mask(Rectangle().fill(focusMask))

                    // Capsule position is driven frame-by-frame by SpringDriver via CADisplayLink,
                    // so it traces the ellipse arc rather than cutting through in a straight line.
                    Text("\(Int(valueDriver.current * 100))%")
                        .font(.callout)
                        .fontWeight(.semibold)
                        .monospacedDigit()
                        .padding(.horizontal, 14)
                        .padding(.vertical, 7)
                        .background(.ultraThinMaterial, in: Capsule())
                        .overlay(Capsule().strokeBorder(Color.primary.opacity(0.2), lineWidth: 1))
                        .rotationEffect(capsuleRotation)
                        .position(x: capsuleX, y: capsuleY)
                }
            }
            .frame(height: 145)
            .padding(.horizontal, 10)
            .clipped()
        }
        .onAppear {
            guard !hasAppeared else { return }
            hasAppeared = true
            valueDriver.set(0.5)
            savedDriver.set(0)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                valueDriver.animate(to: value)
                savedDriver.animate(to: NSDecimalNumber(decimal: savedAmount).doubleValue)
            }
        }
        .onChange(of: value) { _, newVal in
            valueDriver.animate(to: newVal)
        }
        .onChange(of: savedAmount) { _, newVal in
            savedDriver.animate(to: NSDecimalNumber(decimal: newVal).doubleValue)
        }
    }

    // Smooth elliptical arc built from cubic bezier segments
    private func ellipticalArcPath(center: CGPoint, rx: CGFloat, ry: CGFloat) -> Path {
        var path = Path()
        let segments = 6
        let segAngle = sweepDeg / Double(segments)
        for i in 0..<segments {
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

    // Left = save (green), right = spend (red), fades at both ends
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
            endAngle: .degrees(endDeg)
        )
    }
}

#Preview {
    SaveToSpendGaugeView()
}
