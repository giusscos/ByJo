//
//  AssetView.swift
//  ByJo
//
//  Created by Giuseppe Cosenza on 04/11/24.
//

import Charts
import SwiftData
import SwiftUI

struct AssetView: View {
    enum AssetSortOrder {
        case name
        case balance
        case type
        
        var displayName: String {
            switch self {
                case .name: return "Name"
                case .balance: return "Balance"
                case .type: return "Type"
            }
        }
    }
    
    enum AssetSheetType: Identifiable {
        case create
        case edit(Asset)
        case editGoal(Goal)
        
        var id: String {
            switch self {
                case .create:
                    return "create"
                case .edit(let asset):
                    return "edit_\(asset.id)"
                case .editGoal(let goal):
                    return "editGoal_\(goal.id)"
            }
        }
    }
    
    @Environment(\.modelContext) var modelContext

    @Query var assets: [Asset]
    
    @State private var isEditMode: EditMode = .inactive
    
    @State private var activeSheet: AssetSheetType? = nil
    @State private var sortOrder: AssetSortOrder = .name
    @State private var isAscending: Bool = true
    @State private var selectedType: AssetType?
    
    @State private var selectedAssets = Set<Asset>()
    @State private var showingBulkDeleteAlert = false
    
    var filteredAndSortedAssets: [Asset] {
        var filteredAssets = assets
        
        if let type = selectedType {
            filteredAssets = filteredAssets.filter { $0.type == type }
        }
        
        let sortedAssets: [Asset]
        switch sortOrder {
        case .name:
            sortedAssets = filteredAssets.sorted { isAscending ? $0.name < $1.name : $0.name > $1.name }
        case .balance:
            sortedAssets = filteredAssets.sorted { isAscending ? $0.calculateCurrentBalance() < $1.calculateCurrentBalance() : $0.calculateCurrentBalance() > $1.calculateCurrentBalance() }
        case .type:
            sortedAssets = filteredAssets.sorted { isAscending ? $0.type.rawValue < $1.type.rawValue : $0.type.rawValue > $1.type.rawValue }
        }
        
        return sortedAssets
    }
    
    var body: some View {
        NavigationStack {
            List(selection: $selectedAssets) {
                if filteredAndSortedAssets.isEmpty {
                    ContentUnavailableView(
                        "No Assets Found",
                        systemImage: "exclamationmark",
                        description: Text("You need to add an asset by clicking the plus button on the top right corner")
                    )
                } else {
                    Section {
                        ForEach(filteredAndSortedAssets) { asset in
                            NavigationLink {
                                AssetDetailView(asset: asset)
                            } label: {
                                AssetRowView(asset: asset)
                            }
                            .swipeActions (edge: .trailing) {
                                Button (role: .destructive) {
                                    modelContext.delete(asset)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                                
                                Button {
                                    activeSheet = .edit(asset)
                                } label: {
                                    Label("Edit", systemImage: "pencil")
                                }
                                .tint(.blue)
                            }
                        }
                    } header: {
                        HStack {
                            Text("\(filteredAndSortedAssets.count) assets")
                                .foregroundStyle(.secondary)
                            
                            Spacer()
                            
                            if let type = selectedType {
                                Text("Filtered by: \(type.rawValue)")
                                    .foregroundStyle(.secondary)
                            }
                            
                            Text("Sorted by: \(sortOrder.displayName) \(isAscending ? "↑" : "↓")")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("Assets")
            .toolbar {
                if !assets.isEmpty {
                    ToolbarItem(placement: .topBarLeading) {
                        EditButton()
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        activeSheet = .create
                    } label: {
                        Label("Add asset", systemImage: "plus.circle.fill")
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    if isEditMode == .active {
                        Button(role: .destructive) {
                            showingBulkDeleteAlert = true
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                        .disabled(selectedAssets.isEmpty)
                    } else {
                        Menu {
                            Button {
                                
                            } label: {
                                Label("Add goal", systemImage: "plus")
                            }
                            
                            NavigationLink {
                                GoalList()
                            } label: {
                                Label("Goals", systemImage: "list.bullet")
                            }
                            
                            Section("Filters") {
                                Menu("By Type") {
                                    ForEach(AssetType.allCases, id: \.self) { type in
                                        Button {
                                            if type != selectedType {
                                                selectedType = type
                                            } else {
                                                selectedType = nil
                                            }
                                        } label: {
                                            HStack {
                                                Text(type.rawValue)
                                                
                                                if type == selectedType {
                                                    Image(systemName: "checkmark")
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                            
                            Section("Sorters") {
                                Menu("Sort By") {
                                    Button {
                                        sortOrder = .name
                                    } label: {
                                        HStack {
                                            Text("Name")
                                            
                                            if sortOrder == .name {
                                                Image(systemName: isAscending ? "arrow.up" : "arrow.down")
                                            }
                                        }
                                    }
                                    
                                    Button {
                                        sortOrder = .balance
                                    } label: {
                                        HStack {
                                            Text("Balance")
                                            
                                            if sortOrder == .balance {
                                                Image(systemName: isAscending ? "arrow.up" : "arrow.down")
                                            }
                                        }
                                    }
                                    
                                    Button {
                                        sortOrder = .type
                                    } label: {
                                        HStack {
                                            Text("Type")
                                            
                                            if sortOrder == .type {
                                                Image(systemName: isAscending ? "arrow.up" : "arrow.down")
                                            }
                                        }
                                    }
                                    
                                    Divider()
                                    
                                    Button {
                                        isAscending.toggle()
                                    } label: {
                                        HStack {
                                            Text(isAscending ? "Ascending" : "Descending")
                                            Image(systemName: isAscending ? "arrow.up" : "arrow.down")
                                        }
                                    }
                                }
                            }
                        } label: {
                            Label("Menu", systemImage: "ellipsis.circle")
                        }
                    }
                }
            }
            .environment(\.editMode, $isEditMode)
            .sheet(item: $activeSheet) { sheet in
                switch sheet {
                    case .create:
                        EditAssetView()
                    case .edit(let asset):
                        EditAssetView(asset: asset)
                    case .editGoal(let goal):
                        EditGoal(goal: goal)
                }
            }
            .confirmationDialog("Delete Assets", isPresented: $showingBulkDeleteAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    deleteSelectedAssets()
                }
            }
        }
    }
    
    private func deleteSelectedAssets() {
        for asset in selectedAssets {
            modelContext.delete(asset)
        }
        
        selectedAssets.removeAll()
        
        isEditMode = .inactive
    }
}

#Preview {
    AssetView()
}
