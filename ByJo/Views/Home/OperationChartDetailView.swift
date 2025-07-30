//
//  OperationChartDetailView.swift
//  ByJo
//
//  Created by Giuseppe Cosenza on 15/11/24.
//

import SwiftUI
import SwiftData
import Charts

struct OperationChartDetailView: View {
    @Query(sort: \AssetOperation.date, order: .reverse) var operations: [AssetOperation]
    @Query var assets: [Asset]
    
    @State private var dateRange: DateRangeOption = .all
    
    var body: some View {
        VStack {
            
        }
    }
}
    
#Preview {
    OperationChartDetailView()
}
