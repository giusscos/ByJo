//
//  OperationDetailView.swift
//  ByJo
//
//  Created by Giuseppe Cosenza on 05/11/24.
//

import SwiftData
import SwiftUI

struct OperationDetailView: View {
    @Environment(\.modelContext) var modelContext
    
    @AppStorage("currencyCode") var currency: CurrencyCode = .usd
    
    var operation: AssetOperation
    var asset: Asset
    
    @State var showEditSheet: Bool = false
    
    var body: some View {
        List {
            Section {
                HStack {
                    Text("Amount")
                    
                    Spacer()
                    
                    Text(operation.amount, format: .currency(code: currency.rawValue))
                        .foregroundStyle(.secondary)
                }
                
                HStack {
                    Text("Asset")
                    
                    Spacer()
                    
                    Text("\(asset.name)")
                        .foregroundStyle(.secondary)
                }
                            
                HStack {
                    Text("Added on")
                    
                    Spacer()
                    
                    Text(operation.date, format: .dateTime.day().month().year().hour().minute())
                        .foregroundStyle(.secondary)
                }
                
                if let nextPaymentDate = operation.frequency.nextPaymentDate(from: operation.date) {
                    HStack {
                        Text("Next payment date")
                        
                        Spacer()
                        
                        Text(nextPaymentDate, format: .dateTime.day().month(.abbreviated).year(.twoDigits).hour().minute())
                            .foregroundStyle(.secondary)
                    }
                }
            }
            
            if !operation.note.isEmpty {
                Section {
                    VStack (alignment: .leading) {
                        Text("Note")
                        
                        Text(operation.note)
                            .font(.body)
                            .multilineTextAlignment(.center)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .navigationTitle(operation.name)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showEditSheet = true
                } label: {
                    Label("Edit", systemImage: "pencil")
                }
            }
        }
        .sheet(isPresented: $showEditSheet, content: {
            if let category = operation.category {
                EditAssetOperationView(operation: operation, asset: asset, category: category)
            }
        })
    }
}

#Preview {
    OperationDetailView(
        operation: AssetOperation(date: .now, amount: 100.0),
        asset: Asset(name: "BuddyBank", initialBalance: 10000.0)
    )
}
