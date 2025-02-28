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
