//
//  CategoryOperation.swift
//  ByJo
//
//  Created by Giuseppe Cosenza on 08/11/24.
//

import Foundation
import SwiftUI
import SwiftData

@Model
final class CategoryOperation {
    var id: UUID = UUID()
    var name: String = ""
    var monthlyBudget: Decimal = 0

    @Relationship(deleteRule: .nullify, inverse: \AssetOperation.category) var assetOperations: [AssetOperation]?
    @Relationship(deleteRule: .nullify, inverse: \OperationSplit.category) var splits: [OperationSplit]?

    init(name: String) {
        self.name = name
    }
}
