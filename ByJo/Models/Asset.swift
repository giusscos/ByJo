//
//  Asset.swift
//  ByJo
//
//  Created by Giuseppe Cosenza on 04/11/24.
//

import SwiftUI
import SwiftData

@Model
final class Asset {
    var id: UUID = UUID()
    var name: String = ""
    var type: AssetType = AssetType.cash
    var initialBalance: Decimal = 0
    var timestamp: Date = Date()

    @Relationship(deleteRule: .cascade) var operations: [AssetOperation]?
    @Relationship(deleteRule: .cascade) var goals: [Goal]?

    init(name: String, type: AssetType = AssetType.cash, initialBalance: Decimal) {
        self.name = name
        self.type = type
        self.initialBalance = initialBalance
        self.timestamp = Date.now
    }

    func calculateCurrentBalance() -> Decimal {
        (operations ?? []).reduce(initialBalance) { $0 + $1.amount }
    }

    func calculateBalanceForDateRange(_ dateRange: DateRangeOption) -> Decimal {
        let (start, end) = dateRange.dateRange
        return initialBalance + operationsTotal(from: start, to: end)
    }

    func calculatePreviousBalanceForDateRange(_ dateRange: DateRangeOption) -> Decimal {
        let (start, end) = dateRange.previousRange
        return initialBalance + operationsTotal(from: start, to: end)
    }

    func calculateBalanceForDateRangeWithoutInitialBalance(_ dateRange: DateRangeOption) -> Decimal {
        let (start, end) = dateRange.dateRange
        return operationsTotal(from: start, to: end)
    }

    func calculatePreviousBalanceForDateRangeWithoutInitialBalance(_ dateRange: DateRangeOption) -> Decimal {
        let (start, end) = dateRange.previousRange
        return operationsTotal(from: start, to: end)
    }

    private func operationsTotal(from start: Date, to end: Date) -> Decimal {
        (operations ?? [])
            .filter { $0.date >= start && $0.date <= end }
            .reduce(0) { $0 + $1.amount }
    }
}

// UI helper used in amount-entry forms to track sign direction
enum StatusBalance: String, Codable, CaseIterable {
    case positive = "Positive"
    case negative = "Negative"

    var displayName: String {
        NSLocalizedString(rawValue, comment: "")
    }
}
