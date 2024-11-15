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
    
    @Relationship var asset: Asset?
    @Relationship var category: CategoryOperation?
    
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
    
    func filterData(for range: DateRangeOption, data: [AssetOperation]) -> [AssetOperation] {
        let calendar = Calendar.current
        let now = Date()
        let filteredData: [AssetOperation]
        
        switch range {
        case .threeDay:
            if let startOfWeek = calendar.date(byAdding: .day, value: -3, to: now) {
                filteredData = data.filter { $0.date >= startOfWeek }
            } else {
                filteredData = data
            }
        case .week:
            if let startOfWeek = calendar.date(byAdding: .day, value: -7, to: now) {
                filteredData = data.filter { $0.date >= startOfWeek }
            } else {
                filteredData = data
            }
        case .month:
            if let startOfMonth = calendar.date(byAdding: .month, value: -1, to: now) {
                filteredData = data.filter { $0.date >= startOfMonth }
            } else {
                filteredData = data
            }
        case .threeMonth:
            if let startOfMonth = calendar.date(byAdding: .month, value: -3, to: now) {
                filteredData = data.filter { $0.date >= startOfMonth }
            } else {
                filteredData = data
            }
        case .ytd:
            let startOfYear = calendar.date(from: calendar.dateComponents([.year], from: now))!
            filteredData = data.filter { $0.date >= startOfYear }
        case .year:
            if let startOfYear = calendar.date(byAdding: .year, value: -1, to: now) {
                filteredData = data.filter { $0.date >= startOfYear }
            } else {
                filteredData = data
            }
        case .threeYear:
            if let startOfYear = calendar.date(byAdding: .year, value: -3, to: now) {
                filteredData = data.filter { $0.date >= startOfYear }
            } else {
                filteredData = data
            }
        }
        
        return filteredData
    }

}

enum RecurrenceFrequency: String, Codable, CaseIterable {
    case single = "Single"
    case daily = "Daily"
    case weekly = "Weekly"
    case monthly = "Monthly"
    case yearly = "Yearly"
}

enum DateRangeOption: String, CaseIterable, Identifiable {
    case threeDay = "3D"
    case week = "1W"
    case month = "1M"
    case threeMonth = "3M"
    case ytd = "YTD"
    case year = "1Y"
    case threeYear = "3Y"
    
    var id: String { rawValue }
}
