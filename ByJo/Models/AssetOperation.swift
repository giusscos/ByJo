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
    var type: AssetOperationType = AssetOperationType.transaction
    var amount: Decimal = 0
    var note: String = ""
    var frequency: RecurrenceFrequency = RecurrenceFrequency.single
    
    @Relationship var asset: Asset?
    @Relationship var category: CategoryOperation?
    
    init(name: String = "", currency: CurrencyCode = CurrencyCode.usd, date: Date, type: AssetOperationType, amount: Decimal, asset: Asset? = nil, category: CategoryOperation? = nil, note: String = "", frequency: RecurrenceFrequency = RecurrenceFrequency.single) {
        self.id = UUID()
        self.name = name
        self.currency = currency
        self.date = date
        self.type = type
        self.amount = amount
        self.asset = asset
        self.note = note
        self.frequency = frequency
    }
}

enum AssetOperationType: String, Codable, CaseIterable {
    case transaction = "Transaction"
    case transfer = "Transfer"
}

enum RecurrenceFrequency: String, Codable, CaseIterable {
    case single = "Single"
    case daily = "Daily"
    case weekly = "Weekly"
    case monthly = "Monthly"
    case yearly = "Yearly"
}
