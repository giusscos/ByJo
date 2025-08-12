//
//  OperationsGroupedByCategoryListView.swift
//  ByJo
//
//  Created by Giuseppe Cosenza on 12/08/25.
//

import SwiftData
import SwiftUI

struct OperationsGroupedByCategoryListView: View {
    @AppStorage("currencyCode") var currencyCode: CurrencyCode = .usd

    @Query(sort: \CategoryOperation.name, order: .reverse) var categories: [CategoryOperation]
    
    @State var addCategory: Bool = false
    
    var body: some View {
        List {
            ForEach(categories) { category in
                if let assetOperations = category.assetOperations, assetOperations.count > 0 {
                    let total = assetOperations.reduce(0) { $0 + $1.amount }
                    
                    VStack (alignment: .leading, spacing: 16) {
                        HStack {
                            Text(category.name)
                                .font(.headline)
                                .lineLimit(1)
                            
                            Spacer()
                            
                            if let assetOperations = category.assetOperations {
                                Text("\(assetOperations.count == 1 ? "Operation" : "Operations"): \(assetOperations.count)")
                                    .foregroundStyle(.secondary)
                                    .font(.caption)
                            }
                        }
                        
                        HStack(spacing: 4) {
                            Group {
                                if total > 0 {
                                    Image(systemName: "arrow.up.circle.fill")
                                        .foregroundStyle(.green)
                                } else if total == 0 {
                                    Image(systemName: "equal.circle.fill")
                                        .foregroundStyle(.gray)
                                } else {
                                    Image(systemName: "arrow.down.circle.fill")
                                        .foregroundStyle(.red)
                                }
                            }
                            .imageScale(.large)
                            .fontWeight(.semibold)
                            
                            Text(abs(total), format: .currency(code: currencyCode.rawValue))
                                .font(.title)
                                .fontWeight(.semibold)
                        }
                    }
                }
            }
        }
        .navigationTitle("Categories overview")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    addCategory = true
                } label: {
                    Label("Add", image: "plus.circle.fill")
                }
            }
        }
        .sheet(isPresented: $addCategory) {
            CategoryOperationView()
        }
    }
}

#Preview {
    OperationsGroupedByCategoryListView()
}
