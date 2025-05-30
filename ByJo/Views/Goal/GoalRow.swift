//
//  GoalRow.swift
//  ByJo
//
//  Created by Giuseppe Cosenza on 23/11/24.
//

import SwiftUI
import SwiftData

struct GoalRow: View {
    var goal: Goal
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text(goal.title)
                    .font(.title)
                    .bold()
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                if let dueDate = goal.dueDate {
                    HStack (spacing: 4){
                        Text("Due date: ")
                        
                        Text(dueDate, format: .dateTime.day().month().year())
                    }
                    .foregroundStyle(.secondary)
                    .font(.caption)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                }
            }
            
            if let asset = goal.asset {
                Text(asset.name)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                HStack {
                    VStack (alignment: .leading) {
                        Text("Current")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        Text(asset.calculateCurrentBalance(), format: .currency(code: asset.currency.rawValue))
                            .font(.headline)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    
                    VStack (alignment: .trailing) {
                        Text("Target")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        Text(goal.targetAmount, format: .currency(code: asset.currency.rawValue))
                            .font(.headline)
                            .frame(maxWidth: .infinity, alignment: .trailing)
                    }
                }
                .padding(.vertical, 8)
            }
        }
        .overlay {
            if goal.isExpired && !goal.isCompleted {
                Label("Expired", systemImage: "exclamationmark")
                    .foregroundStyle(.white)
                    .font(.headline)
                    .padding()
                    .background(Color.red)
                    .clipShape(Capsule())
            }
            
            if let asset = goal.asset {
                if asset.calculateCurrentBalance() >= goal.targetAmount {
                    Button {
                        withAnimation {
                            goal.isCompleted = true
                        }
                    } label: {
                        if goal.isCompleted {
                            if let dueDate = goal.dueDate, Date.now > dueDate {
                                Label("Completed Late", systemImage: "checkmark.circle.fill")
                                    .contentTransition(.symbolEffect(.replace))
                                    .foregroundStyle(.white)
                                    .font(.headline)
                                    .padding()
                                    .background(Color.orange)
                                    .clipShape(Capsule())
                            } else {
                                Label("Completed", systemImage: "checkmark.circle.fill")
                                    .contentTransition(.symbolEffect(.replace))
                                    .foregroundStyle(.white)
                                    .font(.headline)
                                    .padding()
                                    .background(Color.green)
                                    .clipShape(Capsule())
                            }
                        } else {
                            Label("Complete", systemImage: "checkmark.circle")
                                .contentTransition(.symbolEffect(.replace))
                                .foregroundStyle(.white)
                                .font(.headline)
                                .padding()
                                .background(Color.blue)
                                .clipShape(Capsule())
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

#Preview {
    GoalRow(goal: Goal(title: "", targetAmount: 0))
}
