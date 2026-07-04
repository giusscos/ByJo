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
    @AppStorage("compactNumber") var compactNumber: Bool = true

    @Query(sort: \CategoryOperation.name, order: .reverse) var categories: [CategoryOperation]
    
    @State var addCategory: Bool = false
    
    var body: some View {
        List {
            ForEach(categories) { category in
                let ops = category.assetOperations ?? []
                if !ops.isEmpty {
                    let total = ops.reduce(0) { $0 + $1.amount }

                    HStack {
                        VStack(alignment: .leading) {
                            Text(category.name)
                                .font(.headline)
                                .lineLimit(1)

                            Text("\(ops.count == 1 ? "Operation" : "Operations"): \(ops.count)")
                                .foregroundStyle(.secondary)
                                .font(.caption)
                        }
                        
                        Spacer()
                        
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
                            
                            Text(abs(total), format: compactNumber ? .currency(code: currencyCode.rawValue).notation(.compactName) : .currency(code: currencyCode.rawValue))
                                .font(.title)
                                .fontWeight(.semibold)
                                .contentTransition(.numericText(value: compactNumber ? 0 : 1))
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
                    VersionedLabel(title: "Add category", newSystemImage: "plus", oldSystemImage: "plus.circle.fill")
                }
            }
            
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Section {
                        Button {
                            withAnimation {
                                withAnimation {
                                    compactNumber.toggle()
                                }
                            }
                        } label: {
                            Label(compactNumber ? "Long amount" : "Short amount", systemImage: compactNumber ? "arrow.up.left.and.arrow.down.right" : "arrow.down.right.and.arrow.up.left")
                        }
                    }
                } label: {
                    VersionedLabel(title: "Menu", newSystemImage: "ellipsis", oldSystemImage: "ellipsis.circle")
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
