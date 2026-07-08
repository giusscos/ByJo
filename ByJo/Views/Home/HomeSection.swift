//
//  HomeSection.swift
//  ByJo
//

import Foundation

enum HomeSection: String, CaseIterable, Identifiable {
    case goals
    case monthSummary
    case spendmeter
    case recurring
    case category
    case savingsRate
    case topExpenses
    case assetAllocation

    var id: String { rawValue }

    var title: String {
        switch self {
        case .goals:            return NSLocalizedString("Goals", comment: "")
        case .monthSummary:     return NSLocalizedString("Monthly Summary", comment: "")
        case .spendmeter:       return NSLocalizedString("Spendmeter", comment: "")
        case .recurring:        return NSLocalizedString("Recurring", comment: "")
        case .category:         return NSLocalizedString("Top Category", comment: "")
        case .savingsRate:      return NSLocalizedString("Savings Rate", comment: "")
        case .topExpenses:      return NSLocalizedString("Top Expenses", comment: "")
        case .assetAllocation:  return NSLocalizedString("Asset Allocation", comment: "")
        }
    }

    var icon: String {
        switch self {
        case .goals:            return "target"
        case .monthSummary:     return "calendar"
        case .spendmeter:       return "gauge.with.needle"
        case .recurring:        return "arrow.clockwise"
        case .category:         return "tag"
        case .savingsRate:      return "percent"
        case .topExpenses:      return "arrow.down.circle"
        case .assetAllocation:  return "chart.pie"
        }
    }

    static let defaultOrderString: String = allCases.map(\.rawValue).joined(separator: ",")
}
