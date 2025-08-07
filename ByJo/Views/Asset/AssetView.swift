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
        case createAsset
        case editAsset(Asset)
        case createGoal
        case editGoal(Goal)
        
        var id: String {
            switch self {
                case .createAsset:
                    return "createAsset"
                case .editAsset(let asset):
                    return "editAsset-\(asset.id)"
                case .createGoal:
                    return "createGoal"
                case .editGoal(let goal):
                    return "editGoal-\(goal.id)"
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
                    VStack {
                        Text("No asset found 😕")
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        Text("Start adding assets")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                        
                        Button {
                            activeSheet = .createAsset
                        } label: {
                            Text("Add asset")
                                .font(.headline)
                        }
                        .tint(.accent)
                        .buttonBorderShape(.capsule)
                        .buttonStyle(.bordered)
                    }
                    .frame(maxWidth: .infinity)
                } else {
                    Section {
                        ForEach(filteredAndSortedAssets) { asset in
                            NavigationLink {
                                AssetDetailView(asset: asset)
                            } label: {
                                AssetRowView(asset: asset)
                            }
                            .tag(asset)
                            .swipeActions (edge: .trailing) {
                                Button (role: .destructive) {
                                    modelContext.delete(asset)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                                
                                Button {
                                    activeSheet = .editAsset(asset)
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
                        withAnimation {
                            EditButton()
                        }
                    }
                }
                
                if isEditMode == .inactive {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            activeSheet = .createAsset
                        } label: {
                            Label("Add", systemImage: "plus.circle.fill")
                        }
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    if isEditMode == .active {
                        Button(role: .destructive) {
                            showingBulkDeleteAlert = true
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                        .tint(.red)
                        .disabled(selectedAssets.isEmpty)
                    } else {
                        Menu {
                            Button {
                                activeSheet = .createGoal
                            } label: {
                                Label("Add goal", systemImage: "plus")
                            }
                            
                            NavigationLink {
                                GoalListView()
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
                    case .createAsset:
                        EditAssetView()
                    case .editAsset(let asset):
                        EditAssetView(asset: asset)
                    case .createGoal:
                        if let asset = assets.first {
                            EditGoalView(asset: asset)
                        }
                    case .editGoal(let goal):
                        if let asset = goal.asset {
                            EditGoalView(goal: goal, asset: asset)
                        }
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
