//
//  WidgetDataBridge.swift
//  ByJo
//
//  Reads SwiftData models and writes computed widget data to the shared
//  App Group UserDefaults so the ByJoWidget extension can read it.
//

import Foundation
import WidgetKit

struct WidgetDataBridge {
    static func update(assets: [Asset], currencyCode: CurrencyCode, compactNumber: Bool) {
        guard let defaults = UserDefaults.appGroup else { return }
        let allOps = assets.flatMap { $0.operations ?? [] }
        writeNetWorth(assets: assets, currencyCode: currencyCode, compactNumber: compactNumber, to: defaults)
        writeSpendmeter(allOps: allOps, currencyCode: currencyCode, to: defaults)
        writeAssetAlloc(assets: assets, currencyCode: currencyCode, to: defaults)
        writeRecurring(allOps: allOps, currencyCode: currencyCode, to: defaults)
        writeSavingsRate(allOps: allOps, currencyCode: currencyCode, to: defaults)
        writeGoals(assets: assets, currencyCode: currencyCode, to: defaults)
        writeExpenseBreakdown(allOps: allOps, currencyCode: currencyCode, compactNumber: compactNumber, to: defaults)
        writeNetWorthHistory(assets: assets, currencyCode: currencyCode, compactNumber: compactNumber, to: defaults)
        writeSpendingTrends(allOps: allOps, currencyCode: currencyCode, compactNumber: compactNumber, to: defaults)
        writeSavingsRateTrend(allOps: allOps, to: defaults)
        WidgetCenter.shared.reloadAllTimelines()
    }

    // MARK: - Private

    private static func d(_ v: Decimal) -> Double { NSDecimalNumber(decimal: v).doubleValue }

    private static func writeNetWorth(assets: [Asset], currencyCode: CurrencyCode, compactNumber: Bool, to defaults: UserDefaults) {
        let netWorth = assets.reduce(0.0) { $0 + d($1.calculateCurrentBalance()) }
        let rows = assets.enumerated().map { idx, a in
            WNetWorthData.AssetRow(id: a.id.uuidString, name: a.name,
                                   balance: d(a.calculateCurrentBalance()), colorIndex: idx % 8)
        }
        defaults.encode(WNetWorthData(netWorth: netWorth, currencyCode: currencyCode.rawValue,
                                       compactNumber: compactNumber, assets: rows, updatedAt: Date()), forKey: .netWorth)
    }

    private static func writeSpendmeter(allOps: [AssetOperation], currencyCode: CurrencyCode, to defaults: UserDefaults) {
        let range = DateRangeOption.month.dateRange
        let inflow   = allOps.filter { $0.date >= range.startDate && $0.date <= range.endDate && $0.amount > 0 }
                             .reduce(Decimal(0)) { $0 + $1.amount }
        let outflow  = allOps.filter { $0.date >= range.startDate && $0.date <= range.endDate && $0.amount < 0 }
                             .reduce(Decimal(0)) { $0 + abs($1.amount) }
        let inc = d(inflow), exp = d(outflow)
        let ratio = inc > 0 ? min(max(exp / inc, 0), 1) : (exp > 0 ? 1.0 : 0.0)
        defaults.encode(WSpendmeterData(inflow: inc, outflow: exp, savedAmount: inc - exp,
                                         ratio: ratio, currencyCode: currencyCode.rawValue, updatedAt: Date()), forKey: .spendmeter)
    }

    private static func writeAssetAlloc(assets: [Asset], currencyCode: CurrencyCode, to defaults: UserDefaults) {
        let positive = assets.filter { d($0.calculateCurrentBalance()) > 0 }
        let total = positive.reduce(0.0) { $0 + d($1.calculateCurrentBalance()) }
        guard total > 0 else {
            defaults.encode(WAssetAllocData(slices: [], currencyCode: currencyCode.rawValue, updatedAt: Date()), forKey: .assetAlloc)
            return
        }
        let slices = positive.enumerated().map { idx, a in
            WAssetAllocData.Slice(id: a.id.uuidString, label: a.name,
                                   value: d(a.calculateCurrentBalance()) / total * 100, colorIndex: idx % 8)
        }.sorted { $0.value > $1.value }
        defaults.encode(WAssetAllocData(slices: slices, currencyCode: currencyCode.rawValue, updatedAt: Date()), forKey: .assetAlloc)
    }

    private static func writeRecurring(allOps: [AssetOperation], currencyCode: CurrencyCode, to defaults: UserDefaults) {
        var seen = Set<String>()
        var items: [WRecurringData.Item] = []
        for op in allOps.filter({ $0.frequency != .single }).sorted(by: { $0.date > $1.date }) {
            let key = "\(op.name)|\(op.asset?.id.uuidString ?? "")|\(op.frequency.rawValue)"
            guard !seen.contains(key), let next = op.frequency.nextPaymentDate(from: op.date) else { continue }
            seen.insert(key)
            items.append(WRecurringData.Item(id: op.id.uuidString, name: op.name, amount: d(abs(op.amount)),
                                              nextDate: next, frequencyLabel: op.frequency.rawValue,
                                              assetName: op.asset?.name ?? "", isInflow: op.amount > 0))
        }
        items.sort { $0.nextDate < $1.nextDate }
        defaults.encode(WRecurringData(items: items, currencyCode: currencyCode.rawValue, updatedAt: Date()), forKey: .recurring)
    }

    private static func writeSavingsRate(allOps: [AssetOperation], currencyCode: CurrencyCode, to defaults: UserDefaults) {
        let range = DateRangeOption.month.dateRange
        let inflow   = allOps.filter { $0.date >= range.startDate && $0.date <= range.endDate && $0.amount > 0 }
                             .reduce(Decimal(0)) { $0 + $1.amount }
        let outflow  = allOps.filter { $0.date >= range.startDate && $0.date <= range.endDate && $0.amount < 0 }
                             .reduce(Decimal(0)) { $0 + abs($1.amount) }
        let inc = d(inflow), exp = d(outflow)
        let rate = inc > 0 ? max(0, (inc - exp) / inc) : 0
        defaults.encode(WSavingsRateData(rate: rate, inflow: inc, outflow: exp,
                                          currencyCode: currencyCode.rawValue, updatedAt: Date()), forKey: .savingsRate)
    }

    private static func writeGoals(assets: [Asset], currencyCode: CurrencyCode, to defaults: UserDefaults) {
        let goals = assets.flatMap { a in
            (a.goals ?? []).compactMap { g -> WGoalData.GoalItem? in
                guard !g.isCompleted else { return nil }
                let current = d(a.calculateCurrentBalance()), target = d(g.targetAmount), start = d(g.startingAmount)
                let range = target - start
                let progress = range > 0 ? min(max((current - start) / range, 0), 1) : 0
                return WGoalData.GoalItem(id: g.id.uuidString, title: g.title, currentAmount: current,
                                          targetAmount: target, startingAmount: start,
                                          assetName: a.name, dueDate: g.dueDate, progress: progress)
            }
        }
        defaults.encode(WGoalData(goals: goals, currencyCode: currencyCode.rawValue, updatedAt: Date()), forKey: .goals)
    }

    private static func writeExpenseBreakdown(allOps: [AssetOperation], currencyCode: CurrencyCode, compactNumber: Bool, to defaults: UserDefaults) {
        let range = DateRangeOption.month.dateRange
        let expenses = allOps.filter { $0.amount < 0 && $0.date >= range.startDate && $0.date <= range.endDate }
        guard !expenses.isEmpty else {
            defaults.encode(WExpenseBreakdownData(slices: [], currencyCode: currencyCode.rawValue,
                                                   compactNumber: compactNumber, updatedAt: Date()), forKey: .expenseBreakdown)
            return
        }
        var byCategory: [String: Decimal] = [:]
        for op in expenses {
            let key = op.category?.name ?? "Other"
            byCategory[key, default: 0] += op.amount
        }
        let total = byCategory.values.reduce(0.0) { $0 + abs(d($1)) }
        guard total > 0 else {
            defaults.encode(WExpenseBreakdownData(slices: [], currencyCode: currencyCode.rawValue,
                                                   compactNumber: compactNumber, updatedAt: Date()), forKey: .expenseBreakdown)
            return
        }
        let slices = byCategory
            .map { (label: $0.key, amount: abs(d($0.value))) }
            .sorted { $0.amount > $1.amount }
            .enumerated()
            .map { idx, entry in
                WExpenseBreakdownData.Slice(
                    id: entry.label, label: entry.label,
                    value: entry.amount / total * 100, amount: entry.amount, colorIndex: idx % 8
                )
            }
        defaults.encode(WExpenseBreakdownData(slices: slices, currencyCode: currencyCode.rawValue,
                                               compactNumber: compactNumber, updatedAt: Date()), forKey: .expenseBreakdown)
    }

    private static func writeNetWorthHistory(assets: [Asset], currencyCode: CurrencyCode, compactNumber: Bool, to defaults: UserDefaults) {
        let current = assets.reduce(0.0) { $0 + d($1.calculateCurrentBalance()) }
        guard !assets.isEmpty else {
            defaults.encode(WNetWorthHistoryData(points: [], currentNetWorth: 0, delta: 0,
                                                  currencyCode: currencyCode.rawValue, compactNumber: compactNumber,
                                                  updatedAt: Date()), forKey: .netWorthHistory)
            return
        }

        let calendar = Calendar.current
        let now = Date()
        let start = DateRangeOption.month.dateRange.startDate

        func netWorthAt(_ date: Date) -> Double {
            assets.reduce(0.0) { sum, asset in
                let balance = asset.initialBalance + (asset.operations ?? [])
                    .filter { $0.date <= date }
                    .reduce(Decimal(0)) { $0 + $1.amount }
                return sum + d(balance)
            }
        }

        var points: [WNetWorthHistoryData.Point] = []
        if start < now {
            let totalDays = calendar.dateComponents([.day], from: start, to: now).day ?? 0
            let stepDays = totalDays <= 31 ? 1 : 3
            var currentDate = start
            while currentDate <= now {
                points.append(.init(id: "\(currentDate.timeIntervalSince1970)", date: currentDate, value: netWorthAt(currentDate)))
                guard let next = calendar.date(byAdding: .day, value: stepDays, to: currentDate), next <= now else { break }
                currentDate = next
            }
            points.append(.init(id: "\(now.timeIntervalSince1970)", date: now, value: current))
        } else {
            points = [.init(id: "now", date: now, value: current)]
        }

        let delta = (points.first?.value).map { current - $0 } ?? 0
        defaults.encode(WNetWorthHistoryData(points: points, currentNetWorth: current, delta: delta,
                                              currencyCode: currencyCode.rawValue, compactNumber: compactNumber,
                                              updatedAt: Date()), forKey: .netWorthHistory)
    }

    private static func writeSpendingTrends(allOps: [AssetOperation], currencyCode: CurrencyCode, compactNumber: Bool, to defaults: UserDefaults) {
        let calendar = Calendar.current
        let now = Date()
        let lookback = 6
        let buckets: [WSpendingTrendsData.Bucket] = (0..<lookback).compactMap { offset in
            let monthsAgo = -(lookback - 1 - offset)
            guard let monthDate = calendar.date(byAdding: .month, value: monthsAgo, to: now),
                  let start = calendar.date(from: calendar.dateComponents([.year, .month], from: monthDate)),
                  let end = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: start)
            else { return nil }
            let total = allOps
                .filter { $0.amount < 0 && $0.date >= start && $0.date <= end }
                .reduce(0.0) { $0 + abs(d($1.amount)) }
            return .init(id: "\(start.timeIntervalSince1970)", month: start, amount: total)
        }
        defaults.encode(WSpendingTrendsData(buckets: buckets, currencyCode: currencyCode.rawValue,
                                             compactNumber: compactNumber, updatedAt: Date()), forKey: .spendingTrends)
    }

    private static func writeSavingsRateTrend(allOps: [AssetOperation], to defaults: UserDefaults) {
        let calendar = Calendar.current
        let now = Date()
        let points: [WSavingsRateTrendData.Point] = (0..<6).compactMap { offset in
            let monthsAgo = -(5 - offset)
            guard let monthDate = calendar.date(byAdding: .month, value: monthsAgo, to: now),
                  let start = calendar.date(from: calendar.dateComponents([.year, .month], from: monthDate)),
                  let end = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: start)
            else { return nil }
            let ops = allOps.filter { $0.date >= start && $0.date <= end }
            let inflow = ops.filter { $0.amount > 0 }.reduce(Decimal(0)) { $0 + $1.amount }
            let outflow = ops.filter { $0.amount < 0 }.reduce(Decimal(0)) { $0 + abs($1.amount) }
            guard inflow > 0 else { return nil }
            let rate = max(0.0, min(1.0, d((inflow - outflow) / inflow)))
            return .init(id: "\(start.timeIntervalSince1970)", month: start, rate: rate)
        }
        defaults.encode(WSavingsRateTrendData(points: points, updatedAt: Date()), forKey: .savingsRateTrend)
    }
}
