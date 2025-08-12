//
//  RecurringOperationWidgetView.swift
//  ByJo
//
//  Created by Giuseppe Cosenza on 09/08/25.
//

import SwiftData
import SwiftUI

struct RecurringOperationWidgetView: View {
    @Query(sort: \AssetOperation.date, order: .reverse) var operations: [AssetOperation]

    var body: some View {
        if let recurringOperation = operations.first(where: { operation in
            operation.frequency != .single
        }), let asset = recurringOperation.asset {
            Section {
                VStack (alignment: .leading, spacing: 24) {
                    NavigationLink {
                        RecurringOperationListView()
                    } label: {
                        Text("Recurring operation")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                    }
                    
                    VStack (alignment: .leading) {
                        Text(recurringOperation.name)
                            .font(.title3)
                            .fontWeight(.semibold)
                            .lineLimit(1)
                        
                        HStack (alignment: .lastTextBaseline) {
                            HStack (spacing: 4) {
                                Group {
                                    if recurringOperation.amount > 0 {
                                        Image(systemName: "arrow.up.circle.fill")
                                            .foregroundStyle(.green)
                                    } else if recurringOperation.amount == 0 {
                                        Image(systemName: "equal.circle.fill")
                                            .foregroundStyle(.gray)
                                    } else {
                                        Image(systemName: "arrow.down.circle.fill")
                                            .foregroundStyle(.red)
                                    }
                                    
                                }
                                .imageScale(.large)
                                .fontWeight(.semibold)
                                
                                Text(abs(recurringOperation.amount), format: .currency(code: asset.currency.rawValue))
                                    .font(.title)
                                    .fontWeight(.semibold)
                            }
                            
                            Spacer()
                            
                            if let nextPaymentDate = recurringOperation.frequency.nextPaymentDate(from: recurringOperation.date) {
                                Text(nextPaymentDate, format: .dateTime.day().month(.abbreviated).year(.twoDigits).hour().minute())
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
        }
    }
}

#Preview {
    RecurringOperationWidgetView()
}
