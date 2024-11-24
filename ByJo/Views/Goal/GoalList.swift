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
    
    @State var selectedGaol: Goal?
    
    var body: some View {
        List {
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
                                selectedGaol = goal
                            } label: {
                                Label("Edit", systemImage: "pencil")
                            }
                            .tint(.blue)
                        }
                }
            }
        }
        .sheet(item: $selectedGaol) { goal in
            EditGoal(goal: goal)
        }
    }
}

#Preview {
    GoalList()
}
