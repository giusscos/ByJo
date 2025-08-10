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
    var name: String = ""
    var id: UUID = UUID()
    
    @Relationship var assetOperations: [AssetOperation]?
    
    init(name: String) {
        self.id = UUID()
        self.name = name
    }
}
