//
//  GoalRowView.swift
//  ByJo
//
//  Created by Giuseppe Cosenza on 23/11/24.
//

import SwiftUI
import SwiftData

struct GoalRowView: View {
    var goal: Goal
    var asset: Asset
    
    var progress: Double {
        let current = (asset.calculateCurrentBalance()
                       as NSDecimalNumber).doubleValue
        let target = (goal.targetAmount as NSDecimalNumber).doubleValue
        return target > 0 ? current / target : 0
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            VStack (alignment: .leading, spacing: 6) {
                HStack {
                    if let dueDate = goal.dueDate {
                        Group {
                            Text("Due date: ")
                            +
                            Text(dueDate, format: .dateTime.day().month().year())
                        }
                        .foregroundStyle(.secondary)
                        .font(.caption)
                    }
                    
                    Spacer()
                    
                    Menu {
                        Button {
                            
                        } label: {
                            Label("Set as completed", systemImage: "inset.filled.circle")
                        }
                        
                        Button {
                            
                        } label: {
                            Label("Set as suspended", systemImage: "inset.filled.circle.dashed")
                        }
                        
                        Button {
                            
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
                
                Text(goal.title)
                    .font(.title)
                    .fontWeight(.semibold)
                    .lineLimit(3)
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
    }
}

struct CompletedGoalRowView: View {
    var completedGoal: CompletedGoal
        
    var body: some View {
        if let goal = completedGoal.goal {
            VStack(alignment: .leading, spacing: 24) {
                VStack (alignment: .leading, spacing: 6) {
                    if let dueDate = goal.dueDate {
                        HStack (spacing: 0){
                            Text("Due date: ")
                            +
                            Text(dueDate, format: .dateTime.day().month().year())
                            
                            if completedGoal.completedDate <= dueDate {
                                Spacer()
                                
                                Text("Reached")
                                    .padding(.vertical, 4)
                                    .padding(.horizontal, 8)
                                    .font(.headline)
                                    .foregroundStyle(.white)
                                    .background(Color.accentColor)
                                    .clipShape(.capsule)
                            } else {
                                Spacer()
                                
                                Text("Missed")
                                    .padding(.vertical, 4)
                                    .padding(.horizontal, 8)
                                    .font(.headline)
                                    .foregroundStyle(.white)
                                    .background(Color.yellow)
                                    .clipShape(.capsule)
                            }
                        }
                        .foregroundStyle(.secondary)
                        .font(.caption)
                    }

                    Text(goal.title)
                        .font(.title)
                        .fontWeight(.semibold)
                        .lineLimit(3)
                }
                
                if let asset = goal.asset {
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
                    }
                }
            }
            .padding()
            .background(.ultraThinMaterial)
            .clipShape(.rect(cornerRadius: 12))
            .shadow(color: .black.opacity(0.12), radius: 6, y: 4)
        }
    }
}

#Preview {
    GoalRowView(
        goal: Goal(title: "Buy the brand new iPhone 17", startingAmount: 100.0, targetAmount: 999.99, dueDate: .now),
        asset: Asset(name: "BuddyBank", initialBalance: 100.0))
}
