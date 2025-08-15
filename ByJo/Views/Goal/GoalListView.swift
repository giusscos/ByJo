//
//  GoalListView.swift
//  ByJo
//
//  Created by Giuseppe Cosenza on 23/11/24.
//

import SwiftUI
import SwiftData

struct GoalListView: View {
    enum ActiveSheet: Identifiable {
        case create
        case edit(Goal)
        
        var id: String {
            switch self {
                case .create:
                    return "create"
                case .edit(let goal):
                    return "edit-\(goal.id)"
            }
        }
    }
    
    @Environment(\.modelContext) var modelContext
    
    @Query var assets: [Asset]
    @Query(sort: \Goal.dueDate, order: .reverse) var goals: [Goal]
    @Query(sort: \CompletedGoal.completedDate, order: .reverse) var completedGoals: [CompletedGoal]
    
    @State var activeSheet: ActiveSheet?
    
    var body: some View {
        NavigationStack {
            List {
                if !goals.isEmpty {
                    Section("Ongoing") {
                        ForEach (goals) { goal in
                            if let asset = goal.asset, goal.completedGoal == nil {
                                GoalRowView(goal: goal, asset: asset)
                                    .swipeActions(edge: .trailing) {
                                        Button(role: .destructive) {
                                            modelContext.delete(goal)
                                        } label: {
                                            Label("Delete", systemImage: "trash")
                                        }
                                        
                                        Button {
                                            activeSheet = .edit(goal)
                                        } label: {
                                            Label("Edit", systemImage: "pencil")
                                        }
                                        .tint(.blue)
                                        
                                        Button {
                                            setStatusGoal(goal: goal, status: .completed)
                                        } label: {
                                            Label("Complete", systemImage: "inset.filled.circle")
                                        }
                                        .tint(Color.accentColor)
                                    }
                            }
                        }
                    }
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                }
                
                if !completedGoals.isEmpty {
                    Section("Completed") {
                        ForEach (completedGoals) { goal in
                            GoalCompletedRowView(completedGoal: goal)
                                .swipeActions(edge: .trailing) {
                                    Button(role: .destructive) {
                                        modelContext.delete(goal)
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                        }
                    }
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                }
            }
            .navigationTitle("Goals")
            .toolbar {
                ToolbarItem {
                    Button(action: {
                        activeSheet = .create
                    }) {
                        Label("Add Goal", systemImage: "plus.circle.fill")
                    }
                }
            }
            .sheet(item: $activeSheet) { sheet in
                switch sheet {
                    case .create:
                        if let asset = assets.first {
                            EditGoalView(asset: asset)
                        }
                    case .edit(let goal):
                        if let asset = goal.asset {
                            EditGoalView(goal: goal, asset: asset)
                        }
                }
            }
        }
    }
    
    private func setStatusGoal(goal: Goal, status: StatusGoal) {
        withAnimation {
            let newCompletedGoal = CompletedGoal(completedDate: Date(), status: status, goal: goal)
            
            modelContext.insert(newCompletedGoal)
            
            modelContext.delete(goal)
        }
    }
}

#Preview {
    GoalListView()
}
