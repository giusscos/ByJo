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
        case .goals:            return "Goals"
        case .monthSummary:     return "Monthly Summary"
        case .spendmeter:       return "Spendmeter"
        case .recurring:        return "Recurring"
        case .category:         return "Top Category"
        case .savingsRate:      return "Savings Rate"
        case .topExpenses:      return "Top Expenses"
        case .assetAllocation:  return "Asset Allocation"
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
