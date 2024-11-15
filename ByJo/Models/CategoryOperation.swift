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
    var id: UUID = UUID()
    var name: String = ""
    
    @Relationship var assetOperation: AssetOperation?
    
    init(id: UUID = UUID(), name: String) {
        self.id = id
        self.name = name
    }
}
