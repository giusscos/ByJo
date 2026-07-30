//
//  OperationSplit.swift
//  ByJo
//

import Foundation
import SwiftData

@Model
final class OperationSplit {
    var id: UUID = UUID()
    var amount: Decimal = 0
    var category: CategoryOperation?
    var operation: AssetOperation?

    init(amount: Decimal = 0, category: CategoryOperation? = nil) {
        self.amount = amount
        self.category = category
    }
}
