//
//  Goal.swift
//  ByJo
//
//  Created by Giuseppe Cosenza on 04/11/24.
//

import Foundation
import SwiftData

@Model
final class Goal {
    var id: UUID = UUID()
    var title: String = ""
    var startingAmount: Decimal = 0.0
    var targetAmount: Decimal = 0.0
    var dueDate: Date?
    var completedDate: Date? = nil
    var completedStatus: StatusGoal? = nil

    @Relationship var asset: Asset?

    var isCompleted: Bool { completedDate != nil }

    var isExpired: Bool {
        guard let date = dueDate else { return false }
        return Date.now > date
    }

    init(
        title: String,
        startingAmount: Decimal,
        targetAmount: Decimal,
        dueDate: Date? = nil,
        asset: Asset? = nil
    ) {
        self.title = title
        self.startingAmount = startingAmount
        self.targetAmount = targetAmount
        self.dueDate = dueDate
        self.asset = asset
    }
}

enum StatusGoal: String, Codable, CaseIterable {
    case completed = "Completed"
    case suspended = "Suspended"
}
