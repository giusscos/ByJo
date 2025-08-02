//
//  GoalRowView.swift
//  ByJo
//
//  Created by Giuseppe Cosenza on 23/11/24.
//

import SwiftData
import SwiftUI

struct GoalRowView: View {
    @Environment(\.modelContext) var modelContext
    
    var goal: Goal
    var asset: Asset
    
    var progress: Double {
        let current = (asset.calculateCurrentBalance()
                       as NSDecimalNumber).doubleValue
        let target = (goal.targetAmount as NSDecimalNumber).doubleValue
        return target > 0 ? current / target : 0
    }
    
    @State var showEditGoal: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            HStack (alignment: .top, spacing: 6) {
                VStack (alignment: .leading, spacing: 6) {
                    if let dueDate = goal.dueDate {
                        Group {
                            Text("Due date: ")
                            +
                            Text(dueDate, format: .dateTime.day().month().year())
                        }
                        .foregroundStyle(.secondary)
                        .font(.caption)
                    }
                    
                    Text(goal.title)
                        .font(.title)
                        .fontWeight(.semibold)
                        .lineLimit(3)
                }
                
                Spacer()
                
                Menu {
                    Button {
                        setStatusGoal(status: .completed)
                    } label: {
                        Label("Set as completed", systemImage: "inset.filled.circle")
                    }
                    
                    Button {
                        setStatusGoal(status: .suspended)
                    } label: {
                        Label("Set as suspended", systemImage: "inset.filled.circle.dashed")
                    }
                    
                    Button {
                        showEditGoal = true
                    } label: {
                        Label("Edit goal", systemImage: "pencil")
                        
                    }
                } label: {
                    Text("Handle")
                        .font(.caption)
                        .fontWeight(.semibold)
                }
                .tint(.accent)
                .buttonBorderShape(.capsule)
                .buttonStyle(.bordered)
            }
            
            VStack {
                HStack (alignment: .firstTextBaseline) {
                    VStack (alignment: .leading) {
                        Text("From")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        Text(goal.startingAmount, format: .currency(code: asset.currency.rawValue))
                            .font(.headline)
                    }
                    
                    Spacer()
                    
                    Text(asset.name)
                        .font(.headline)
                    
                    Spacer()
                    
                    VStack (alignment: .trailing) {
                        Text("Target")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        Text(goal.targetAmount, format: .currency(code: asset.currency.rawValue))
                            .font(.headline)
                    }
                }
                
                ProgressView(value: progress, total: 1)
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(.rect(cornerRadius: 12))
        .shadow(color: .black.opacity(0.12), radius: 6, y: 4)
        .sheet(isPresented: $showEditGoal) {
            EditGoalView(goal: goal, asset: asset)
        }
    }
    
    private func setStatusGoal(status: StatusGoal) {
        withAnimation {
            let newCompletedGoal = CompletedGoal(completedDate: Date(), status: status, goal: goal)
            
            modelContext.insert(newCompletedGoal)
        }
    }
}

#Preview {
    GoalRowView(
        goal: Goal(title: "Buy the brand new iPhone 17", startingAmount: 100.0, targetAmount: 999.99, dueDate: .now),
        asset: Asset(name: "BuddyBank", initialBalance: 100.0)
    )
}
