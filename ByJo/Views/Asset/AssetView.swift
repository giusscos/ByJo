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
    
    @State var activeSheet: SheetType? = nil
    
    enum SheetType: Identifiable {
        case editAsset(Asset)
        case editGoal(Goal)
        
        var id: String {
            switch self {
            case .editAsset(let asset):
                return "editAsset_\(asset.id)"
            case .editGoal(let goal):
                return "editGoal_\(goal.id)"
            }
        }
    }
    
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
                                activeSheet = .editAsset(value)
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
                Menu {
                    Button {
                        addAsset()
                    } label: {
                        Label("Add asset", systemImage: "plus")
                    }
                    
                    Button {
                        addGoal()
                    } label: {
                        Label("Add goal", systemImage: "plus")
                    }
                    
                    NavigationLink {
                        GoalList()
                    } label: {
                        Label("Goals", systemImage: "list.bullet")
                    }
                } label: {
                    Label("Menu", systemImage: "ellipsis.circle")
                }
            }
        }
        .sheet(item: $activeSheet) { sheet in
            switch sheet {
            case .editAsset(let asset):
                EditAsset(asset: asset)
            case .editGoal(let goal):
                EditGoal(goal: goal)
            }
        }
    }
    
    func addAsset() {
        let asset = Asset(name: "", type: .cash, initialBalance: 0)
        activeSheet = .editAsset(asset)
        modelContext.insert(asset)
    }
    
    func addGoal() {
        let goal = Goal(title: "", targetAmount: 0)
        activeSheet = .editGoal(goal)
        modelContext.insert(goal)
    }
}

#Preview {
    NavigationStack {
        AssetView()
    }
}
