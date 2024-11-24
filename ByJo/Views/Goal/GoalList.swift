//
//  GoalList.swift
//  ByJo
//
//  Created by Giuseppe Cosenza on 23/11/24.
//

import SwiftUI
import SwiftData

struct GoalList: View {
    @Environment(\.modelContext) var modelContext
    
    @Query(sort: \Goal.dueDate, order: .reverse) var goals: [Goal]
    
    @State var selectedGoal: Goal?
    
    var body: some View {
        List {
            if goals.isEmpty {
                ContentUnavailableView(
                    "No Goals Found",
                    systemImage: "exclamationmark",
                    description: Text("You need to add a goal tapping the plus button on the top right corner")
                )
            } else {
                ForEach (goals) { goal in
                    Section {
                        GoalRow(goal: goal)
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    modelContext.delete(goal)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                                
                                Button {
                                    selectedGoal = goal
                                } label: {
                                    Label("Edit", systemImage: "pencil")
                                }
                                .tint(.blue)
                            }
                    }
                }
            }
        }
        .toolbar {
            ToolbarItem {
                Button(action: {
                    addGoal()
                }) {
                    Label("Add Goal", systemImage: "plus")
                }
            }
        }
        .sheet(item: $selectedGoal) { goal in
            EditGoal(goal: goal)
        }
    }
    
    func addGoal() {
        let goal = Goal(title: "", targetAmount: 0)
        selectedGoal = goal
        modelContext.insert(goal)
    }
}

#Preview {
    GoalList()
}
