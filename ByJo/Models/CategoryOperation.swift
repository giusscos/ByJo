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

    @Relationship(deleteRule: .nullify) var assetOperations: [AssetOperation]?

    init(name: String) {
        self.name = name
    }
}
