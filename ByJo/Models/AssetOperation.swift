//
//  AssetOperation.swift
//  ByJo
//
//  Created by Giuseppe Cosenza on 04/11/24.
//

import Foundation
import SwiftData

@Model
class AssetOperation {
    var id: UUID = UUID()
    var name: String = ""
    var currency: CurrencyCode = CurrencyCode.usd
    var date: Date = Date.now
    var amount: Decimal = 0
    var note: String = ""
    var frequency: RecurrenceFrequency = RecurrenceFrequency.single
    
    var asset: Asset?
    var category: CategoryOperation?
    
    init (
         name: String = "",
         currency: CurrencyCode = CurrencyCode.usd,
         date: Date = .now,
         amount: Decimal = 0,
         asset: Asset? = nil,
         category: CategoryOperation? = nil,
         note: String = "",
         frequency: RecurrenceFrequency = RecurrenceFrequency.single
    ) {
        self.id = UUID()
        self.name = name
        self.currency = currency
        self.date = date
        self.amount = amount
        self.asset = asset
        self.category = category
        self.note = note
        self.frequency = frequency
    }
}

extension AssetOperation: Hashable {
    static func == (lhs: AssetOperation, rhs: AssetOperation) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

func filterData(for range: DateRangeOption, data: [AssetOperation]) -> [AssetOperation] {
    let calendar = Calendar.current
    let now = Date()
    
    switch range {
    case .all:
        return data
    case .week:
        let startDate = calendar.date(byAdding: .day, value: -7, to: now) ?? now
        return data.filter { $0.date >= startDate }
    case .month:
        let startDate = calendar.date(byAdding: .month, value: -1, to: now) ?? now
        return data.filter { $0.date >= startDate }
    case .threeMonths:
        let startDate = calendar.date(byAdding: .month, value: -3, to: now) ?? now
        return data.filter { $0.date >= startDate }
    case .sixMonths:
        let startDate = calendar.date(byAdding: .month, value: -6, to: now) ?? now
        return data.filter { $0.date >= startDate }
    case .year:
        let startDate = calendar.date(byAdding: .year, value: -1, to: now) ?? now
        return data.filter { $0.date >= startDate }
    }
}

enum RecurrenceFrequency: String, Codable, CaseIterable {
    case single = "Single"
    case daily = "Daily"
    case weekly = "Weekly"
    case monthly = "Monthly"
    case yearly = "Yearly"
}

enum DateRangeOption: Identifiable, Hashable {
    case week
    case month
    case threeMonths
    case sixMonths
    case year
    case all
    
    var id: String { label }
    
    var label: String {
        switch self {
        case .week: return "1W"
        case .month: return "1M"
        case .threeMonths: return "3M"
        case .sixMonths: return "6M"
        case .year: return "1Y"
        case .all: return "All"
        }
    }
    
    var dateRange: (startDate: Date, endDate: Date) {
        let calendar = Calendar.current
        let now = Date()
        
        switch self {
        case .week:
            let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now))!
            let endOfWeek = calendar.date(byAdding: .day, value: 6, to: startOfWeek)!
            return (startOfWeek, endOfWeek)
            
        case .month:
            let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: now))!
            let endOfMonth = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: startOfMonth)!
            return (startOfMonth, endOfMonth)
            
        case .threeMonths:
            let startOfQuarter = calendar.date(from: DateComponents(year: calendar.component(.year, from: now), month: ((calendar.component(.month, from: now) - 1) / 3) * 3 + 1))!
            let endOfQuarter = calendar.date(byAdding: DateComponents(month: 3, day: -1), to: startOfQuarter)!
            return (startOfQuarter, endOfQuarter)
            
        case .sixMonths:
            let startOfHalfYear = calendar.date(from: DateComponents(year: calendar.component(.year, from: now), month: ((calendar.component(.month, from: now) - 1) / 6) * 6 + 1))!
            let endOfHalfYear = calendar.date(byAdding: DateComponents(month: 6, day: -1), to: startOfHalfYear)!
            return (startOfHalfYear, endOfHalfYear)
            
        case .year:
            let startOfYear = calendar.date(from: calendar.dateComponents([.year], from: now))!
            let endOfYear = calendar.date(byAdding: DateComponents(year: 1, day: -1), to: startOfYear)!
            return (startOfYear, endOfYear)
            
        case .all:
            return (Date.distantPast, Date.distantFuture)
        }
    }
    
    var previousRange: (startDate: Date, endDate: Date) {
        let calendar = Calendar.current
        let now = Date()
        
        switch self {
        case .week:
            let startOfCurrentWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now))!
            let startOfPreviousWeek = calendar.date(byAdding: .day, value: -7, to: startOfCurrentWeek)!
            let endOfPreviousWeek = calendar.date(byAdding: .day, value: 6, to: startOfPreviousWeek)!
            return (startOfPreviousWeek, endOfPreviousWeek)
            
        case .month:
            let startOfCurrentMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: now))!
            let startOfPreviousMonth = calendar.date(byAdding: .month, value: -1, to: startOfCurrentMonth)!
            let endOfPreviousMonth = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: startOfPreviousMonth)!
            return (startOfPreviousMonth, endOfPreviousMonth)
            
        case .threeMonths:
            let currentQuarter = (calendar.component(.month, from: now) - 1) / 3
            let startOfCurrentQuarter = calendar.date(from: DateComponents(year: calendar.component(.year, from: now), month: currentQuarter * 3 + 1))!
            let startOfPreviousQuarter = calendar.date(byAdding: .month, value: -3, to: startOfCurrentQuarter)!
            let endOfPreviousQuarter = calendar.date(byAdding: DateComponents(month: 3, day: -1), to: startOfPreviousQuarter)!
            return (startOfPreviousQuarter, endOfPreviousQuarter)
            
        case .sixMonths:
            let currentHalfYear = (calendar.component(.month, from: now) - 1) / 6
            let startOfCurrentHalfYear = calendar.date(from: DateComponents(year: calendar.component(.year, from: now), month: currentHalfYear * 6 + 1))!
            let startOfPreviousHalfYear = calendar.date(byAdding: .month, value: -6, to: startOfCurrentHalfYear)!
            let endOfPreviousHalfYear = calendar.date(byAdding: DateComponents(month: 6, day: -1), to: startOfPreviousHalfYear)!
            return (startOfPreviousHalfYear, endOfPreviousHalfYear)
            
        case .year:
            let startOfCurrentYear = calendar.date(from: calendar.dateComponents([.year], from: now))!
            let startOfPreviousYear = calendar.date(byAdding: .year, value: -1, to: startOfCurrentYear)!
            let endOfPreviousYear = calendar.date(byAdding: DateComponents(year: 1, day: -1), to: startOfPreviousYear)!
            return (startOfPreviousYear, endOfPreviousYear)
            
        case .all:
            return (Date.distantPast, Date.distantFuture)
        }
    }
    
    static func availableRanges(for operations: [AssetOperation], maxOptions: Int = 6) -> [DateRangeOption] {
        guard !operations.isEmpty else { return [.all] }
        
        let calendar = Calendar.current
        let now = Date()
        let oldestDate = operations.map { $0.date }.min() ?? now
        let timeSpan = calendar.dateComponents([.day], from: oldestDate, to: now).day ?? 0
        
        var ranges: [DateRangeOption] = [.all]
        
        if timeSpan >= 7 { ranges.append(.week) }
        if timeSpan >= 30 { ranges.append(.month) }
        if timeSpan >= 90 { ranges.append(.threeMonths) }
        if timeSpan >= 180 { ranges.append(.sixMonths) }
        if timeSpan >= 365 { ranges.append(.year) }
        
        // Ensure we don't exceed maxOptions
        if ranges.count > maxOptions {
            ranges = Array(ranges.prefix(maxOptions))
        }
        
        return ranges
    }
}
