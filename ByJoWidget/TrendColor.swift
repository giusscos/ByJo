//
//  TrendColor.swift
//  ByJo (shared by the app and the widget extension)
//

import SwiftUI

/// Colors for money going up or down: the net worth line, month-over-month changes, balance history,
/// value adjustments, goal progress, and inflow (up) vs. outflow (down) arrows and amounts.
///
/// Mainland China and Taiwan show a rise in red and a fall in green (红涨绿跌), the reverse of
/// most markets; Hong Kong uses the usual green-up colors. The region decides, not the language,
/// so a Taiwanese user with English UI still sees red for a rise.
///
/// Not for states or warnings: negative balances (debts), over-budget, expired goals, the savings-rate
/// thresholds, the spending gauge and destructive buttons keep their green/red everywhere.
extension Color {
    /// Regions that show a rise in red.
    static let redRiseRegions: Set<String> = ["CN", "TW"]

    static var risesInRed: Bool {
        guard let region = Locale.current.region?.identifier else { return false }
        return redRiseRegions.contains(region)
    }

    /// The color of a rise in the current region.
    static var rise: Color { risesInRed ? .red : .green }

    /// The color of a fall in the current region.
    static var fall: Color { risesInRed ? .green : .red }

    /// `rise` when `up` is true, otherwise `fall`.
    static func trend(up: Bool) -> Color { up ? rise : fall }
}
