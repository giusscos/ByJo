//
//  OperationDetailView.swift
//  ByJo
//
//  Created by Giuseppe Cosenza on 05/11/24.
//

import SwiftUI

struct OperationDetailView: View {
    var operation: AssetOperation
    
    var body: some View {
        ScrollView {
            VStack (alignment: .center) {
                Text("\(operation.amount.description) EUR")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("\(operation.name)")
                    .font(.headline)
                    .foregroundStyle(.secondary)
                
                Text(operation.date, format: .dateTime)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                if operation.note != "" {
                    VStack {
                        Text("Note: ")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        Text(operation.note)
                            .font(.body)
                            .multilineTextAlignment(.center)
                    }.padding(.vertical)
                }
            }.padding()
            .frame(maxWidth: .infinity, alignment: .center)
            
            Divider()
            
            if let asset = operation.asset {
                HStack (alignment: .center) {
                    HStack (alignment: .center, spacing: 0) {
                        Text("\(asset.name)")
                            .font(.title)
                            .fontWeight(.semibold)
                    }
                    
                    Divider()
                    
                    Text("\(asset.type.rawValue)")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                }.padding()
                .frame(maxWidth: .infinity, alignment: .center)
            }
        }
    }
}

#Preview {
    OperationDetailView(operation: AssetOperation(date: .now, amount: 100))
}
