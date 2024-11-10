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
                    Chart(assets, id: \.id) { value in
                        BarMark(
                            x: .value("Asset", value.name),
                            y: .value("Amount", value.initialBalance)
                        )
                        .foregroundStyle(.blue.gradient)
                        .cornerRadius(4)
                    }
                    .frame(maxHeight: UIScreen.main.bounds.height / 3, alignment: .top)
                    .listRowInsets(.init(top: 10, leading: 0, bottom: 0, trailing: 0))
                    .listRowBackground(Color.clear)
                    .aspectRatio(16/9, contentMode: .fit)
                }
                
                Section {
                    ForEach(assets) { value in
                        NavigationLink {
                            AssetDetailView(asset: value)
                        } label: {
                            AssetRow(asset: value)
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
            
//            TODO: Edit button implementation
//            if (!assets.isEmpty) {
//                ToolbarItem(placement: .topBarTrailing) {
//                    EditButton()
//                }
//            }
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
