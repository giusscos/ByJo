//
//  SwapOperation.swift
//  ByJo
//
//  Created by Giuseppe Cosenza on 24/08/25.
//

import Foundation
import SwiftData

@Model
final class SwapOperation {
    var id: UUID = UUID()
    var amount: Decimal = 0
    var createdAt: Date = Date()
    
    @Relationship var assetFrom: Asset?
    @Relationship var assetTo: Asset?

    init(
        assetFrom: Asset? = nil,
        assetTo: Asset? = nil,
        amount: Decimal = 0,
    ) {
        self.id = UUID()
        self.assetFrom = assetFrom
        self.assetTo = assetTo
        self.amount = amount
        self.createdAt = Date()
    }
}
