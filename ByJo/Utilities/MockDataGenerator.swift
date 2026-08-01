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

        func daysAgo(_ n: Int) -> Date {
            calendar.date(byAdding: .day, value: -n, to: now) ?? now
        }

        func pastMonthDate(monthsBack: Int, day: Int) -> Date {
            var comps = calendar.dateComponents([.year, .month], from: now)
            comps.month = (comps.month ?? 1) - monthsBack
            comps.day = day
            return calendar.date(from: comps) ?? now
        }

        // MARK: - Categories (with budgets for Budget Progress widget)

        let catSalary        = CategoryOperation(name: "Salary")
        let catHousing       = CategoryOperation(name: "Housing")
        let catGroceries     = CategoryOperation(name: "Groceries")
        let catTransport     = CategoryOperation(name: "Transport")
        let catDining        = CategoryOperation(name: "Dining Out")
        let catEntertainment = CategoryOperation(name: "Entertainment")
        let catInvestments   = CategoryOperation(name: "Investments")
        let catHealth        = CategoryOperation(name: "Health")
        let catShopping      = CategoryOperation(name: "Shopping")
        let catUtilities     = CategoryOperation(name: "Utilities")
        let catLoans         = CategoryOperation(name: "Loan Payments")

        catHousing.monthlyBudget       = 1500
        catGroceries.monthlyBudget     = 500
        catTransport.monthlyBudget     = 150
        catDining.monthlyBudget        = 200
        catEntertainment.monthlyBudget = 100
        catHealth.monthlyBudget        = 150
        catShopping.monthlyBudget      = 300
        catUtilities.monthlyBudget     = 200

        [catSalary, catHousing, catGroceries, catTransport, catDining,
         catEntertainment, catInvestments, catHealth, catShopping, catUtilities, catLoans]
            .forEach { context.insert($0) }

        // MARK: - Assets

        let checking    = Asset(name: "Checking",     type: .bankAccount,      initialBalance: 2500)
        let savings     = Asset(name: "Savings",      type: .savingsAccount,   initialBalance: 12000)
        let sp500       = Asset(name: "S&P 500 ETF",  type: .etfs,             initialBalance: 8000)
        let bitcoin     = Asset(name: "Bitcoin",      type: .crypto,           initialBalance: 3500)
        let home        = Asset(name: "Home",         type: .primaryResidence, initialBalance: 350000)
        let mortgage    = Asset(name: "Mortgage",     type: .mortgage,         initialBalance: -180000)
        let studentLoan = Asset(name: "Student Loan", type: .studentLoan,      initialBalance: -22000)
        let autoLoan    = Asset(name: "Auto Loan",    type: .autoLoan,         initialBalance: -14500)

        [checking, savings, sp500, bitcoin, home, mortgage, studentLoan, autoLoan]
            .forEach { context.insert($0) }

        // MARK: - Recurring operations (feeds Recurring, Net Worth Forecast, Debt Payoff widgets)

        let recurringOps: [AssetOperation] = [
            AssetOperation(name: "Monthly Salary",       date: daysAgo(5), amount:  5200,  asset: checking,    category: catSalary,        frequency: .monthly, seriesId: UUID()),
            AssetOperation(name: "Rent",                 date: daysAgo(4), amount: -1400,  asset: checking,    category: catHousing,       frequency: .monthly, seriesId: UUID()),
            AssetOperation(name: "Netflix",              date: daysAgo(3), amount:   -16,  asset: checking,    category: catEntertainment, frequency: .monthly, seriesId: UUID()),
            AssetOperation(name: "Spotify",              date: daysAgo(3), amount:   -10,  asset: checking,    category: catEntertainment, frequency: .monthly, seriesId: UUID()),
            AssetOperation(name: "Gym",                  date: daysAgo(3), amount:   -49,  asset: checking,    category: catHealth,        frequency: .monthly, seriesId: UUID()),
            AssetOperation(name: "ETF Contribution",     date: daysAgo(5), amount:   500,  asset: sp500,       category: catInvestments,   frequency: .monthly, seriesId: UUID()),
            AssetOperation(name: "Mortgage Payment",     date: daysAgo(4), amount:  1200,  asset: mortgage,    category: catLoans,         frequency: .monthly, seriesId: UUID()),
            AssetOperation(name: "Student Loan Payment", date: daysAgo(4), amount:   350,  asset: studentLoan, category: catLoans,         frequency: .monthly, seriesId: UUID()),
            AssetOperation(name: "Auto Loan Payment",    date: daysAgo(4), amount:   450,  asset: autoLoan,    category: catLoans,         frequency: .monthly, seriesId: UUID()),
        ]
        recurringOps.forEach { context.insert($0) }

        // MARK: - Current month single ops (feeds Budget Progress widget spending)

        let currentSingles: [AssetOperation] = [
            AssetOperation(name: "Groceries",     date: daysAgo(4), amount: -320, asset: checking, category: catGroceries),
            AssetOperation(name: "Supermarket",   date: daysAgo(1), amount:  -87, asset: checking, category: catGroceries),
            AssetOperation(name: "Transport",     date: daysAgo(2), amount:  -95, asset: checking, category: catTransport),
            AssetOperation(name: "Dining Out",    date: daysAgo(2), amount: -145, asset: checking, category: catDining),
            AssetOperation(name: "Electricity",   date: daysAgo(4), amount:  -85, asset: checking, category: catUtilities),
            AssetOperation(name: "Shopping",      date: daysAgo(1), amount: -230, asset: checking, category: catShopping),
            AssetOperation(name: "Bitcoin Buy",   date: daysAgo(3), amount:  300, asset: bitcoin,  category: catInvestments),
            AssetOperation(name: "Doctor Visit",  date: daysAgo(6), amount: -120, asset: checking, category: catHealth),
        ]
        currentSingles.forEach { context.insert($0) }

        // MARK: - Historical ops (5 months back for chart widgets)

        let historicalMonths: [(monthsBack: Int, groceries: Decimal, transport: Decimal, dining: Decimal, electricity: Decimal, shopping: Decimal)] = [
            (monthsBack: 1, groceries: -295, transport:  -78, dining: -185, electricity:  -92, shopping: -180),
            (monthsBack: 2, groceries: -340, transport: -110, dining: -160, electricity:  -78, shopping: -195),
            (monthsBack: 3, groceries: -310, transport:  -90, dining: -210, electricity:  -99, shopping: -150),
            (monthsBack: 4, groceries: -280, transport: -105, dining: -175, electricity:  -83, shopping: -220),
            (monthsBack: 5, groceries: -325, transport:  -88, dining: -195, electricity:  -91, shopping: -170),
        ]

        for m in historicalMonths {
            let ops: [AssetOperation] = [
                AssetOperation(name: "Monthly Salary",       date: pastMonthDate(monthsBack: m.monthsBack, day: 1),  amount:  5200,          asset: checking,    category: catSalary),
                AssetOperation(name: "Rent",                 date: pastMonthDate(monthsBack: m.monthsBack, day: 2),  amount: -1400,          asset: checking,    category: catHousing),
                AssetOperation(name: "Groceries",            date: pastMonthDate(monthsBack: m.monthsBack, day: 8),  amount:  m.groceries,   asset: checking,    category: catGroceries),
                AssetOperation(name: "Netflix",              date: pastMonthDate(monthsBack: m.monthsBack, day: 3),  amount:   -16,          asset: checking,    category: catEntertainment),
                AssetOperation(name: "Spotify",              date: pastMonthDate(monthsBack: m.monthsBack, day: 3),  amount:   -10,          asset: checking,    category: catEntertainment),
                AssetOperation(name: "Gym",                  date: pastMonthDate(monthsBack: m.monthsBack, day: 3),  amount:   -49,          asset: checking,    category: catHealth),
                AssetOperation(name: "Transport",            date: pastMonthDate(monthsBack: m.monthsBack, day: 10), amount:  m.transport,   asset: checking,    category: catTransport),
                AssetOperation(name: "Dining Out",           date: pastMonthDate(monthsBack: m.monthsBack, day: 15), amount:  m.dining,      asset: checking,    category: catDining),
                AssetOperation(name: "ETF Contribution",     date: pastMonthDate(monthsBack: m.monthsBack, day: 1),  amount:   500,          asset: sp500,       category: catInvestments),
                AssetOperation(name: "Electricity",          date: pastMonthDate(monthsBack: m.monthsBack, day: 4),  amount:  m.electricity, asset: checking,    category: catUtilities),
                AssetOperation(name: "Shopping",             date: pastMonthDate(monthsBack: m.monthsBack, day: 20), amount:  m.shopping,    asset: checking,    category: catShopping),
                AssetOperation(name: "Mortgage Payment",     date: pastMonthDate(monthsBack: m.monthsBack, day: 2),  amount:  1200,          asset: mortgage,    category: catLoans),
                AssetOperation(name: "Student Loan Payment", date: pastMonthDate(monthsBack: m.monthsBack, day: 2),  amount:   350,          asset: studentLoan, category: catLoans),
                AssetOperation(name: "Auto Loan Payment",    date: pastMonthDate(monthsBack: m.monthsBack, day: 2),  amount:   450,          asset: autoLoan,    category: catLoans),
            ]
            ops.forEach { context.insert($0) }
        }

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

        let vacationFund = Goal(
            title: "Vacation Fund",
            startingAmount: 0,
            targetAmount: 5000,
            dueDate: calendar.date(byAdding: .month, value: 10, to: now),
            asset: savings
        )

        [emergencyFund, newLaptop, vacationFund].forEach { context.insert($0) }

        try? context.save()
    }
}
#endif
