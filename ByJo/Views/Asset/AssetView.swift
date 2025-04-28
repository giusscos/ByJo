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
    @State private var isEditMode: EditMode = .inactive
    @State private var selectedAssets = Set<Asset>()
    @State private var selectedType: AssetType?
    @State private var sortOrder: SortOrder = .name
    @State private var isAscending: Bool = true
    @State private var showingBulkDeleteAlert = false
    
    enum SortOrder {
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
        List(selection: $selectedAssets) {
            if filteredAndSortedAssets.isEmpty {
                ContentUnavailableView(
                    "No Assets Found",
                    systemImage: "exclamationmark",
                    description: Text("You need to add an asset by clicking the plus button on the top right corner")
                )
            } else {
                Section {
                    ForEach(filteredAndSortedAssets) { value in
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
                        .tag(value)
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
                        
                        Section {
                            Menu("By Type") {
                                ForEach(AssetType.allCases, id: \.self) { type in
                                    Button(type.rawValue) {
                                        selectedType = type
                                    }
                                }
                                Button("Clear Filter") {
                                    selectedType = nil
                                }
                            }
                            
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
                        } header: {
                            Text("Filters")
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
            case .editAsset(let asset):
                EditAsset(asset: asset)
            case .editGoal(let goal):
                EditGoal(goal: goal)
            }
        }
        .alert("Delete Assets", isPresented: $showingBulkDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                deleteSelectedAssets()
            }
        } message: {
            Text("Are you sure you want to delete \(selectedAssets.count) assets? This action cannot be undone.")
        }
    }
    
    private func deleteSelectedAssets() {
        for asset in selectedAssets {
            modelContext.delete(asset)
        }
        selectedAssets.removeAll()
        isEditMode = .inactive
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
