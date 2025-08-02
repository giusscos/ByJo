//
//  AssetDetailView.swift
//  ByJo
//
//  Created by Giuseppe Cosenza on 04/11/24.
//

import Charts
import SwiftData
import SwiftUI

struct AssetDetailView: View {
    enum ActiveSheet: Identifiable {
        case editAsset
        case createOperation
        case editOperation(AssetOperation)
        case createGoal
        case editGoal(Goal)
        case viewGoal
        
        var id: String {
            switch self {
                case .editAsset:
                    return "editAsset"
                case .createOperation:
                    return "createOperation"
                case .editOperation(let operation):
                    return "editOperation-\(operation.id)"
                case .createGoal:
                    return "creteGoal"
                case .editGoal(let goal):
                    return "editGoal-\(goal.id)"
                case .viewGoal:
                    return "viewGoal"
            }
        }
    }
    
    @Environment(\.modelContext) var modelContext
    
    var asset: Asset

    @Query(sort: \AssetOperation.date, order: .reverse) var operations: [AssetOperation]
    @Query var categories: [CategoryOperation]
    
    @State private var activeSheet: ActiveSheet?
        
    var body: some View {
        NavigationStack {
            List {
                if let goals = asset.goals {
                    GoalListStack(goals: goals, asset: asset)
                }
                
                if let operations = asset.operations {
                    Section {
                        ForEach(operations) { operation in
                            NavigationLink {
                                OperationDetailView(operation: operation, asset: asset)
                            } label: {
                                AssetOperationRow(operation: operation, asset: asset)
                            }
                            .swipeActions (edge: .trailing) {
                                Button (role: .destructive) {
                                    modelContext.delete(operation)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                                
                                Button {
                                    activeSheet = .editOperation(operation)
                                } label: {
                                    Label("Edit", systemImage: "pencil")
                                }
                                .tint(.blue)
                            }
                        }
                    }
                }
            }
            .navigationTitle(asset.name)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        activeSheet = .createOperation
                    } label: {
                        Label("Add operation", systemImage: "plus.circle.fill")
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Section {
                            Button {
                                activeSheet = .editAsset
                            } label: {
                                Label("Edit asset", systemImage: "pencil")
                            }
                        }
                        
                        Divider()
                        
                        Section {
                            Button {
                                activeSheet = .createGoal
                            } label: {
                                Label("Add goal", systemImage: "plus")
                            }
                            
                            Button {
                                activeSheet = .viewGoal
                            } label: {
                                Label("Goal list", systemImage: "list.bullet")
                            }
                        }
                        
                        Divider()
                        
                        // TODO: filters and sorters
                    } label: {
                        Label("Menu", systemImage: "ellipsis.circle")
                    }
                }
            }
            .sheet(item: $activeSheet) { sheet in
                switch sheet {
                    case .editAsset:
                        EditAssetView(asset: asset)
                    case .createGoal:
                        EditGoalView(asset: asset)
                    case .editGoal(let goal):
                        EditGoalView(goal: goal, asset: asset)
                    case .createOperation:
                        if let category = categories.first {
                            EditAssetOperationView(asset: asset, category: category)
                        }
                    case .editOperation(let operation):
                        if let category = categories.first {
                            EditAssetOperationView(operation: operation, asset: asset, category: category)
                        }
                    case .viewGoal:
                        GoalListView()
                }
            }
        }
    }
}

struct GoalListStack: View {
    var goals: [Goal]
    var asset: Asset
    
    @State private var xOffsets: [Double] = [0.0]
    @State private var zIndexes: [Double] = [0.0]
    @State private var rotates: [Double] = [0.0]
    
    var body: some View {
        Section {
            GeometryReader { geometry in
                let screenWidth = geometry.size.width
                
                ZStack(alignment: .top) {
                    ForEach(Array(goals.enumerated()), id: \.offset) { index, goal in
                        if xOffsets.count == goals.count, zIndexes.count == goals.count {
                            GoalRowView(goal: goal, asset: asset)
                                .offset(x: xOffsets[index])
                                .rotationEffect(Angle(degrees: rotates[index]))
                                .zIndex(zIndexes[index])
                                .gesture(
                                    DragGesture()
                                        .onChanged { value in
                                            xOffsets[index] = value.translation.width
                                        }
                                        .onEnded { value in
                                            let threshold = screenWidth * 0.5
                                            
                                            if xOffsets[index] >= threshold || xOffsets[index] <= -threshold {
                                                withAnimation {
                                                    zIndexes[index] = zIndexes[index] - 1
                                                    xOffsets[index] = .zero
                                                    rotates[index] = .random(in: -4...4)
                                                }
                                            }
                                            
                                            withAnimation {
                                                xOffsets[index] = .zero
                                            }
                                        }
                                )
                        }
                    }
                }
                .padding()
            }
            .frame(height: 250)
        }
        .listRowSeparator(.hidden)
        .listRowBackground(Color.clear)
        .listRowInsets(.init(top: 0, leading: 0, bottom: 0, trailing: 0))
        .onAppear() {
            let goalsCount = goals.count
            
            let startingArray = Array(repeating: 0.0, count: goalsCount)
            
            xOffsets = startingArray
            zIndexes = startingArray

            for _ in goals {
                rotates.append(.random(in: -4...4))
            }
        }
        .onDisappear() {
            let goalsCount = goals.count
            
            let startingArray = Array(repeating: 0.0, count: goalsCount)
            
            zIndexes = startingArray
        }
    }
}

#Preview {
    AssetDetailView(asset: Asset(name: "Cash", initialBalance: 0))
}
