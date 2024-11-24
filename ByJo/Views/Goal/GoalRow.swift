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
                if !goal.title.isEmpty {
                    Text(goal.title)
                        .font(.title)
                        .bold()
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                
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
                .padding(.top, 8)
            }
        }
        .overlay {
            if goal.isExpired {
                Label("Expired", systemImage: "exclamationmark.triangle.fill")
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
                            goal.isCompleted.toggle()
                        }
                    } label: {
                        Label(goal.isCompleted ? "Completed" : "Complete", systemImage: goal.isCompleted ? "checkmark.circle.fill" : "checkmark.circle")
                            .contentTransition(.symbolEffect(.replace))
                            .foregroundStyle(.white)
                            .font(.headline)
                            .padding()
                            .background(goal.isCompleted ? .green : .blue)
                            .clipShape(Capsule())
                    }
                }
            }
        }
    }
}

#Preview {
    GoalRow(goal: Goal(title: "", targetAmount: 0))
}
