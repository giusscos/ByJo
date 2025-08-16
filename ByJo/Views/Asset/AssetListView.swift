//
//  AssetView.swift
//  ByJo
//
//  Created by Giuseppe Cosenza on 04/11/24.
//

import Charts
import SwiftData
import SwiftUI

struct AssetListView: View {
    enum AssetSortOrder: String, CaseIterable, Codable {
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
        case viewCategories
        
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
                case .viewCategories:
                    return "viewCategories"
            }
        }
    }
    
    @Environment(\.modelContext) var modelContext

    @AppStorage("compactNumber") var compactNumber: Bool = true
    
    @Query var assets: [Asset]
    @Query var goals: [Goal]
    
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
                        Text("No assets found 😕")
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
                            
                            Section {
                                Button {
                                    activeSheet = .createGoal
                                } label: {
                                    Label("Add goal", systemImage: "plus")
                                }
                                .disabled(assets.isEmpty)
                                
                                NavigationLink {
                                    GoalListView()
                                } label: {
                                    Label("Goals", systemImage: "list.bullet")
                                }
                                .disabled(goals.isEmpty)
                            }
                        
                            Section {
                                Button {
                                    activeSheet = .viewCategories
                                } label: {
                                    Label("Categories", systemImage: "list.bullet")
                                }
                            }
                            
                            if !assets.isEmpty {
                                Section("Filters") {
                                    Menu("By Type") {
                                        ForEach(AssetType.allCases, id: \.self) { type in
                                            Button {
                                                withAnimation {
                                                    if type != selectedType {
                                                        selectedType = type
                                                    } else {
                                                        selectedType = nil
                                                    }
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
                                        ForEach(AssetSortOrder.allCases, id: \.self) { sort in
                                            Button {
                                                withAnimation {
                                                    if sortOrder == sort {
                                                        isAscending.toggle()
                                                    } else {
                                                        sortOrder = sort
                                                        isAscending = true
                                                    }
                                                }
                                            } label: {
                                                HStack {
                                                    Text(sort.displayName)
                                                    
                                                    if sortOrder == sort {
                                                        Image(systemName: isAscending ? "arrow.up" : "arrow.down")
                                                    }
                                                }
                                            }
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
                    case .viewCategories:
                        CategoryOperationView()
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
    AssetListView()
}
