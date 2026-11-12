//
//  SavingsRateWidgetView.swift
//  ByJo
//

import SwiftData
import SwiftUI

struct SavingsRateWidgetView: View {
    @Query var assets: [Asset]
    @Environment(\.colorSchemeContrast) private var colorSchemeContrast

    private var allOperations: [AssetOperation] {
        assets.flatMap { $0.operations ?? [] }
    }

    private var inflow: Decimal {
        let range = DateRangeOption.month.dateRange
        return allOperations
            .filter { $0.date >= range.startDate && $0.date <= range.endDate && $0.amount > 0 }
            .reduce(Decimal(0)) { $0 + $1.amount }
    }

    private var outflow: Decimal {
        let range = DateRangeOption.month.dateRange
        return allOperations
            .filter { $0.date >= range.startDate && $0.date <= range.endDate && $0.amount < 0 }
            .reduce(Decimal(0)) { $0 + abs($1.amount) }
    }

    private var savingsRate: Double {
        guard inflow > 0 else { return 0 }
        return max(0, NSDecimalNumber(decimal: (inflow - outflow) / inflow).doubleValue)
    }

    private var savingsRatePercent: Int {
        Int((savingsRate * 100).rounded())
    }

    private var rateColor: Color {
        if savingsRate >= 0.20 { return .green }
        if savingsRate >= 0.10 { return .yellow }
        return .red
    }

    /// Yellow text is hard to read on a light card; with Increase Contrast the number uses the
    /// primary color and the bar and legend keep the rating color.
    private var numberColor: Color {
        colorSchemeContrast == .increased && rateColor == .yellow ? .primary : rateColor
    }

    private var hasData: Bool {
        inflow > 0
    }

    var body: some View {
        if !assets.isEmpty {
            Section {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Savings Rate")
                        .font(.headline)
                        .foregroundStyle(.secondary)

                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text(hasData ? "\(savingsRatePercent)" : "—")
                            .scaledFont(size: 52, weight: .black, design: .rounded, maxSize: 96)
                            .foregroundStyle(hasData ? numberColor : Color.secondary)
                            .contentTransition(.numericText(value: Double(savingsRatePercent)))

                        if hasData {
                            Text("%")
                                .scaledFont(size: 28, weight: .bold, design: .rounded, maxSize: 52)
                                .foregroundStyle(numberColor)
                                .padding(.bottom, 6)
                        }
                    }

                    GeometryReader { geo in
                        let progress = hasData ? savingsRate : 0.0
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(Color.secondary.opacity(0.15))
                                .frame(height: 8)

                            Capsule()
                                .fill(rateColor)
                                .frame(width: max(0, geo.size.width * progress), height: 8)
                                .motionAnimation(.spring(response: 0.8, dampingFraction: 0.75), value: progress)
                        }
                    }
                    .frame(height: 8)
                    .accessibilityHidden(true)

                    AdaptiveStack {
                        Label { Text("≥20% great") } icon: { Image(systemName: "circle.fill").foregroundStyle(.green) }
                        Spacer(minLength: 0)
                        Label { Text("10–20% ok") } icon: { Image(systemName: "circle.fill").foregroundStyle(.yellow) }
                        Spacer(minLength: 0)
                        Label { Text("<10% low") } icon: { Image(systemName: "circle.fill").foregroundStyle(.red) }
                    }
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .accessibilityHidden(true)
                }
                .padding(.vertical, 8)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(Text("Savings Rate"))
                .accessibilityValue(Text(verbatim: hasData ? "\(savingsRate.formatted(.percent.precision(.fractionLength(0)))), \(NSLocalizedString(savingsRate >= 0.20 ? "≥20% great" : savingsRate >= 0.10 ? "10–20% ok" : "<10% low", comment: ""))" : "—"))
            }
        }
    }
}

#Preview {
    SavingsRateWidgetView()
}
