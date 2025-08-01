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
    
    @Relationship var asset: Asset?
    @Relationship var completedGoal: CompletedGoal?
    
    var isExpired: Bool {
        if let date = dueDate {
            return Date() > date
        }
        
        return false
    }
    
    init(title: String, startingAmount: Decimal, targetAmount: Decimal, dueDate: Date? = nil, asset: Asset? = nil, completedGoal: CompletedGoal? = nil) {
        self.id = UUID()
        self.title = title
        self.startingAmount = startingAmount
        self.targetAmount = targetAmount
        self.dueDate = dueDate
        self.asset = asset
        self.completedGoal = completedGoal
    }
}

@Model
final class CompletedGoal {
    var id: UUID = UUID()
    var completedDate: Date = Date()
    
    @Relationship var goal: Goal?
    
    init(id: UUID, completedDate: Date, goal: Goal?) {
        self.id = id
        self.completedDate = completedDate
        self.goal = goal
    }
}
