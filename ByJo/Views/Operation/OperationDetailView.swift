//
//  OperationDetailView.swift
//  ByJo
//
//  Created by Giuseppe Cosenza on 05/11/24.
//

import SwiftData
import SwiftUI
import Foundation

struct OperationDetailView: View {
    enum DeleteAction {
        case none
        case current
        case linked
        case both
    }
    
    @Environment(\.modelContext) var modelContext
    @Environment(\.dismiss) var dismiss
    
    @AppStorage("currencyCode") var currencyCode: CurrencyCode = .usd
    
    @Query var operations: [AssetOperation]
    
    var operation: AssetOperation
    var linkedOperation: AssetOperation? = nil
    var asset: Asset
    
    @State var showEditSheet: Bool = false
    @State var showDeleteDialog: Bool = false
    @State var pendingDelete: DeleteAction = .none
    
    var body: some View {
        List {
            Section {
                HStack {
                    Text("Name")
                    
                    Spacer()
                    
                    Text(operation.name)
                        .foregroundStyle(.secondary)
                }

                HStack {
                    Text("Amount")
                    
                    Spacer()
                    
                    Text(operation.amount, format: .currency(code: currencyCode.rawValue))
                        .foregroundStyle(.secondary)
                }
                
                HStack {
                    Text("Asset")
                    
                    Spacer()
                    
                    Text("\(asset.name)")
                        .foregroundStyle(.secondary)
                }
                            
                HStack {
                    Text("Date")
                    
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
            
            if let linkedOperation = linkedOperation, let linkedAsset = linkedOperation.asset {
                Section("Linked Operation") {
                    HStack {
                        Text("Name")
                        
                        Spacer()
                        
                        Text(linkedOperation.name)
                            .foregroundStyle(.secondary)
                    }
                    
                    HStack {
                        Text("Amount")
                        
                        Spacer()
                        
                        Text(linkedOperation.amount, format: .currency(code: currencyCode.rawValue))
                            .foregroundStyle(.secondary)
                    }
                    
                    HStack {
                        Text("Asset")
                        
                        Spacer()
                        
                        Text(linkedAsset.name)
                            .foregroundStyle(.secondary)
                    }
                    
                    HStack {
                        Text("Date")
                        
                        Spacer()
                        
                        Text(linkedOperation.date, format: .dateTime.day().month().year().hour().minute())
                            .foregroundStyle(.secondary)
                    }
                }
            }
            
            if let category = operation.category {
                Section("Category") {
                    Text(category.name)
                        .foregroundStyle(.secondary)
                }
            }
            
            if !operation.note.isEmpty {
                Section("Note") {
                    Text(operation.note)
                        .font(.body)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle("Details")
//        .onAppear() {
//            if let swapId = operation.swapId {
//                linkedOperation = operations.first(where: { op in
//                    op.id != operation.id && op.swapId == swapId
//                })
//            }
//        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showEditSheet = true
                } label: {
                    Label("Edit", systemImage: "pencil")
                }
            }
            
            ToolbarItem(placement: .topBarTrailing) {
                Button(role: .destructive) {
                    showDeleteDialog = true
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            }
        }
        .sheet(isPresented: $showEditSheet, content: {
            if let category = operation.category {
                EditAssetOperationView(operation: operation, asset: asset, category: category)
            }
        })
        .confirmationDialog("Are you sure you want to delete?", isPresented: $showDeleteDialog) {
            if let linkedOperation = linkedOperation {
                Button("Delete current", role: .destructive) {
                    pendingDelete = .current
                    
                    modelContext.delete(operation)
                    
                    linkedOperation.swapId = nil
                    
                    pendingDelete = .none
                    
                    dismiss()
                }
                
                Button("Delete linked", role: .destructive) {
                    pendingDelete = .linked
                    
                    modelContext.delete(linkedOperation)
                    
                    operation.swapId = nil
                    
                    pendingDelete = .none
                    
                    dismiss()
                }
                
                Button("Delete both", role: .destructive) {
                    pendingDelete = .both
                    modelContext.delete(operation)
                    modelContext.delete(linkedOperation)
                    
                    pendingDelete = .none
                    
                    dismiss()
                }
            } else {
                Button("Delete", role: .destructive) {
                    pendingDelete = .current
                    modelContext.delete(operation)
                    pendingDelete = .none
                    
                    dismiss()
                }
            }
            
            Button("Cancel", role: .cancel) {
                pendingDelete = .none
            }
        }
    }
}

#Preview {
    OperationDetailView(
        operation: AssetOperation(date: .now, amount: 100.0),
        asset: Asset(name: "BuddyBank", initialBalance: 10000.0)
    )
}
