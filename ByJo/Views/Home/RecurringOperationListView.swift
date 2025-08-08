//
//  RecurringOperationListView.swift
//  ByJo
//
//  Created by Giuseppe Cosenza on 08/08/25.
//

import SwiftData
import SwiftUI

struct RecurringOperationListView: View {
    @Query var operations: [AssetOperation]
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(operations.filter({ operation in
                    operation.frequency != .single
                })) { operation in
                    if let asset = operation.asset {
                        OperationRow(operation: operation, asset: asset)
                    }
                }
            }
            .navigationTitle("Recurring Operations")
        }
    }
}

#Preview {
    RecurringOperationListView()
}
