//
//  Goal.swift
//  ByJo
//
//  Created by Giuseppe Cosenza on 04/11/24.
//

import Foundation
import SwiftData

@Model
class Goal {
    var id: UUID = UUID()
    var title: String = ""
    var targetAmount: Decimal = 0
    var dueDate: Date?
    var completed: Bool = false
    
    @Relationship var asset: Asset?
    
    var progress: Decimal {
        targetAmount / (asset?.calculateCurrentBalance() ?? 0)
    }
    
    var isExpired: Bool {
        if let date = dueDate {
            return Date() > date
        } else { return false }
    }
    
    init(title: String, targetAmount: Decimal, dueDate: Date? = nil, asset: Asset? = nil) {
        self.id = UUID()
        self.title = title
        self.targetAmount = targetAmount
        self.dueDate = dueDate
        self.asset = asset
    }
}
