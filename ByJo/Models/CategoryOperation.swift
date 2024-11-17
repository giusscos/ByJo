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
class CategoryOperation {
    var name: String = ""
    var id: UUID = UUID()
    
    @Relationship var assetOperation: [AssetOperation]?
    
    init(name: String) {
        self.id = UUID()
        self.name = name
    }
}
