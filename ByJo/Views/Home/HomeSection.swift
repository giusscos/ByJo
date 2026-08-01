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
    case expenseBreakdown
    case netWorthHistory
    case spendingTrends
    case savingsRateTrend
    case budgetProgress
    case debtPayoff

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
        case .expenseBreakdown: return NSLocalizedString("Expense Breakdown", comment: "")
        case .netWorthHistory:  return NSLocalizedString("Net Worth History", comment: "")
        case .spendingTrends:   return NSLocalizedString("Spending Trends", comment: "")
        case .savingsRateTrend: return NSLocalizedString("Savings Rate Trend", comment: "")
        case .budgetProgress:   return NSLocalizedString("Budget Progress", comment: "")
        case .debtPayoff:       return NSLocalizedString("Debt Payoff", comment: "")
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
        case .expenseBreakdown: return "chart.pie.fill"
        case .netWorthHistory:  return "chart.line.uptrend.xyaxis"
        case .spendingTrends:   return "chart.bar.fill"
        case .savingsRateTrend: return "chart.xyaxis.line"
        case .budgetProgress:   return "chart.bar"
        case .debtPayoff:       return "creditcard.fill"
        }
    }

    static let defaultOrderString: String = allCases.map(\.rawValue).joined(separator: ",")
}
