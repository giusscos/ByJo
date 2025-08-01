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
    
    @State var activeSheet: ActiveSheet?
    
    var body: some View {
        List {
            if goals.isEmpty {
                ContentUnavailableView(
                    "No Goals Found",
                    systemImage: "exclamationmark",
                    description: Text("You need to add a goal tapping the plus button on the top right corner")
                )
            } else {
                Section {
                    ForEach (goals) { goal in
                        if let asset = goal.asset {
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
                                }
                        }
                    }
                }
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

#Preview {
    GoalListView()
}
