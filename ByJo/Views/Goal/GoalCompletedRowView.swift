//
//  GoalCompletedRowView.swift
//  ByJo
//
//  Created by Giuseppe Cosenza on 02/08/25.
//

import SwiftUI

struct GoalCompletedRowView: View {
    var completedGoal: CompletedGoal
    
    var body: some View {
        if let goal = completedGoal.goal {
            VStack(alignment: .leading, spacing: 24) {
                HStack (alignment: .top) {
                    if let dueDate = goal.dueDate {
                        VStack (alignment: .leading, spacing: 6) {
                            Group {
                                Text("Due date: ")
                                +
                                Text(dueDate, format: .dateTime.day().month().year())
                            }
                            .foregroundStyle(.secondary)
                            .font(.caption)
                        
                            Text(goal.title)
                                .font(.title)
                                .fontWeight(.semibold)
                                .lineLimit(3)
                        }
                        
                        Spacer()
                        
                        Group {
                            if completedGoal.status == .completed {
                                if completedGoal.completedDate <= dueDate {
                                    Button("Reached") {
                                        withAnimation {
                                            completedGoal.status = .suspended
                                        }
                                    }
                                    .tint(Color.accentColor)
                                } else {
                                    Button ("Missed") {

                                    }
                                    .tint(.red)
                                }
                            } else {
                                Button("Suspended") {
                                    withAnimation {   
                                        completedGoal.status = .completed
                                    }
                                }
                                .tint(.yellow)
                            }
                        }
                        .font(.caption)
                        .buttonStyle(.bordered)
                        .buttonBorderShape(.capsule)
                    } else {
                        Text(goal.title)
                            .font(.title)
                            .fontWeight(.semibold)
                            .lineLimit(3)
                        
                        Spacer()
                        
                        Group {
                            if completedGoal.status == .completed {
                                Button("Reached") {
                                    withAnimation {
                                        completedGoal.status = .suspended
                                    }
                                }
                                .tint(Color.accentColor)
                            } else {
                                Button("Suspended") {
                                    withAnimation {
                                        completedGoal.status = .completed
                                    }
                                }
                                .tint(.yellow)
                            }
                        }
                        .font(.caption)
                        .buttonStyle(.bordered)
                        .buttonBorderShape(.capsule)
                    }
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
    GoalCompletedRowView(completedGoal: CompletedGoal(completedDate: Date(), goal: Goal(title: "Goal 1", startingAmount: 100.0, targetAmount: 200.0)))
}
