//
//  MockDataGenerator.swift
//  ByJo
//

#if DEBUG
import Foundation
import SwiftData

struct MockDataGenerator {
    static func generate(in context: ModelContext) {
        let calendar = Calendar.current
        let now = Date()

        func daysAgo(_ days: Int) -> Date {
            calendar.date(byAdding: .day, value: -days, to: now) ?? now
        }

        // MARK: - Categories
        let catSalary = CategoryOperation(name: "Salary")
        let catHousing = CategoryOperation(name: "Housing")
        let catGroceries = CategoryOperation(name: "Groceries")
        let catTransport = CategoryOperation(name: "Transport")
        let catDining = CategoryOperation(name: "Dining Out")
        let catEntertainment = CategoryOperation(name: "Entertainment")
        let catInvestments = CategoryOperation(name: "Investments")
        let catHealth = CategoryOperation(name: "Health")
        let catShopping = CategoryOperation(name: "Shopping")
        let catUtilities = CategoryOperation(name: "Utilities")

        [catSalary, catHousing, catGroceries, catTransport, catDining,
         catEntertainment, catInvestments, catHealth, catShopping, catUtilities]
            .forEach { context.insert($0) }

        // MARK: - Assets
        let checking = Asset(name: "Checking", type: .bankAccount, initialBalance: 2500)
        let savings = Asset(name: "Savings", type: .savingsAccount, initialBalance: 12000)
        let sp500 = Asset(name: "S&P 500 ETF", type: .etfs, initialBalance: 8000)
        let bitcoin = Asset(name: "Bitcoin", type: .crypto, initialBalance: 3500)
        let mortgage = Asset(name: "Mortgage", type: .mortgage, initialBalance: -180000)

        [checking, savings, sp500, bitcoin, mortgage].forEach { context.insert($0) }

        // MARK: - Operations

        // Current month
        let currentMonthOps: [AssetOperation] = [
            AssetOperation(name: "Monthly Salary", date: daysAgo(5), amount: 5200, asset: checking, category: catSalary),
            AssetOperation(name: "Rent", date: daysAgo(4), amount: -1400, asset: checking, category: catHousing),
            AssetOperation(name: "Groceries", date: daysAgo(4), amount: -320, asset: checking, category: catGroceries),
            AssetOperation(name: "Netflix", date: daysAgo(3), amount: -16, asset: checking, category: catEntertainment),
            AssetOperation(name: "Gym", date: daysAgo(3), amount: -49, asset: checking, category: catHealth),
            AssetOperation(name: "Transport", date: daysAgo(2), amount: -95, asset: checking, category: catTransport),
            AssetOperation(name: "Dining Out", date: daysAgo(2), amount: -145, asset: checking, category: catDining),
            AssetOperation(name: "ETF Contribution", date: daysAgo(5), amount: 500, asset: sp500, category: catInvestments),
            AssetOperation(name: "Electricity", date: daysAgo(4), amount: -85, asset: checking, category: catUtilities),
            AssetOperation(name: "Shopping", date: daysAgo(1), amount: -230, asset: checking, category: catShopping),
        ]

        // Previous month
        let prevMonthOps: [AssetOperation] = [
            AssetOperation(name: "Monthly Salary", date: daysAgo(35), amount: 5200, asset: checking, category: catSalary),
            AssetOperation(name: "Rent", date: daysAgo(34), amount: -1400, asset: checking, category: catHousing),
            AssetOperation(name: "Groceries", date: daysAgo(28), amount: -295, asset: checking, category: catGroceries),
            AssetOperation(name: "Netflix", date: daysAgo(33), amount: -16, asset: checking, category: catEntertainment),
            AssetOperation(name: "Gym", date: daysAgo(32), amount: -49, asset: checking, category: catHealth),
            AssetOperation(name: "Transport", date: daysAgo(25), amount: -78, asset: checking, category: catTransport),
            AssetOperation(name: "Dining Out", date: daysAgo(22), amount: -185, asset: checking, category: catDining),
            AssetOperation(name: "ETF Contribution", date: daysAgo(35), amount: 500, asset: sp500, category: catInvestments),
            AssetOperation(name: "Bitcoin", date: daysAgo(30), amount: 250, asset: bitcoin, category: catInvestments),
            AssetOperation(name: "Electricity", date: daysAgo(34), amount: -92, asset: checking, category: catUtilities),
        ]

        // Two months ago
        let twoMonthsAgoOps: [AssetOperation] = [
            AssetOperation(name: "Monthly Salary", date: daysAgo(65), amount: 5200, asset: checking, category: catSalary),
            AssetOperation(name: "Rent", date: daysAgo(64), amount: -1400, asset: checking, category: catHousing),
            AssetOperation(name: "Groceries", date: daysAgo(58), amount: -340, asset: checking, category: catGroceries),
            AssetOperation(name: "Transport", date: daysAgo(55), amount: -110, asset: checking, category: catTransport),
            AssetOperation(name: "Dining Out", date: daysAgo(52), amount: -160, asset: checking, category: catDining),
            AssetOperation(name: "ETF Contribution", date: daysAgo(65), amount: 500, asset: sp500, category: catInvestments),
            AssetOperation(name: "Electricity", date: daysAgo(64), amount: -78, asset: checking, category: catUtilities),
            AssetOperation(name: "Doctor Visit", date: daysAgo(60), amount: -120, asset: checking, category: catHealth),
            AssetOperation(name: "Shopping", date: daysAgo(56), amount: -195, asset: checking, category: catShopping),
        ]

        (currentMonthOps + prevMonthOps + twoMonthsAgoOps).forEach { context.insert($0) }

        // MARK: - Goals
        let emergencyFund = Goal(
            title: "Emergency Fund",
            startingAmount: 12000,
            targetAmount: 20000,
            dueDate: calendar.date(byAdding: .year, value: 1, to: now),
            asset: savings
        )

        let newLaptop = Goal(
            title: "New Laptop",
            startingAmount: 0,
            targetAmount: 3000,
            dueDate: calendar.date(byAdding: .month, value: 6, to: now),
            asset: checking
        )

        [emergencyFund, newLaptop].forEach { context.insert($0) }

        try? context.save()
    }
}
#endif
