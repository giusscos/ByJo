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
}
