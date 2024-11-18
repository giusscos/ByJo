//
//  AssetView.swift
//  ByJo
//
//  Created by Giuseppe Cosenza on 04/11/24.
//

import SwiftUI
import SwiftData
import Charts

struct AssetView: View {
    @Environment(\.modelContext) var modelContext
    
    @Query var assets: [Asset]
    
    @State var selectedAsset: Asset?
        
    @State var calculateOperations: Bool = false

    var body: some View {
        List {
            if assets.isEmpty {
                ContentUnavailableView(
                    "No Assets Found",
                    systemImage: "exclamationmark",
                    description: Text("You need to add an asset by clicking the plus button on the top right corner")
                )
            } else {                
                Section {
                    ForEach(assets) { value in
                        NavigationLink {
                            AssetDetailView(asset: value)
                        } label: {
                            HStack (alignment: .center) {
                                VStack (alignment: .leading, spacing: 0) {
                                    Text(value.name)
                                        .font(.title3)
                                        .fontWeight(.semibold)
                                        .lineLimit(1)
                                    
                                    Text(value.type.rawValue)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                        .fontWeight(.semibold)
                                }.frame(maxWidth: .infinity, alignment: .leading)
                                
                                Text(value.calculateCurrentBalance(), format: .currency(code: value.currency.rawValue))
                                    .font(.title2)
                                    .fontWeight(.semibold)
                            }
                        }
                        .swipeActions (edge: .trailing) {
                            Button (role: .destructive) {
                                modelContext.delete(value)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                            
                            Button {
                                selectedAsset = value
                            } label: {
                                Label("Edit", systemImage: "pencil")
                            }.tint(.blue)
                        }
                    }
                }
            }
        }
        .navigationTitle("Assets")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    addAsset()
                } label: {
                    Label("Add asset", systemImage: "plus")
                }
            }
        }
        .sheet(item: $selectedAsset) { value in
            EditAsset(asset: value)
                .presentationDragIndicator(.visible)
        }
    }
    
    func addAsset() {
        let asset = Asset(name: "", type: .cash, initialBalance: 0)
        selectedAsset = asset
        modelContext.insert(asset)
    }
}

#Preview {
    NavigationStack {
        AssetView()
    }
}
