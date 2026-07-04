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
            case .create: return "create"
            case .edit(let goal): return "edit-\(goal.id)"
            }
        }
    }

    @Environment(\.modelContext) var modelContext

    @Query var assets: [Asset]
    @Query(sort: \Goal.dueDate, order: .reverse) var goals: [Goal]

    @State var activeSheet: ActiveSheet?

    var ongoingGoals: [Goal] {
        goals.filter { !$0.isCompleted }
    }

    var completedGoals: [Goal] {
        goals
            .filter { $0.isCompleted }
            .sorted { ($0.completedDate ?? .distantPast) > ($1.completedDate ?? .distantPast) }
    }

    var body: some View {
        NavigationStack {
            List {
                if !ongoingGoals.isEmpty {
                    Section("Ongoing") {
                        ForEach(ongoingGoals) { goal in
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
                        ForEach(completedGoals) { goal in
                            GoalCompletedRowView(goal: goal)
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
                    Button {
                        activeSheet = .create
                    } label: {
                        VersionedLabel(title: "Add goal", newSystemImage: "plus", oldSystemImage: "plus.circle.fill")
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
            goal.completedDate = Date.now
            goal.completedStatus = status
        }
    }
}

#Preview {
    GoalListView()
}
