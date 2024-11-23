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
    
    var body: some View {
        List {
            ForEach (goals) { goal in
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
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        HStack {
                            VStack (alignment: .leading) {
                                Text(asset.calculateCurrentBalance(), format: .currency(code: asset.currency.rawValue))
                                    .font(.headline)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                
                                Text("Current ☝️")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            
                            VStack (alignment: .trailing) {
                                Text(goal.targetAmount, format: .currency(code: asset.currency.rawValue))
                                    .font(.headline)
                                    .frame(maxWidth: .infinity, alignment: .trailing)
                                
                                Text("☝️ Target")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.top, 8)
                    }
                }
                .overlay {
                    if goal.isExpired {
                        RoundedRectangle(cornerRadius: 10)
                            .foregroundStyle(.white.opacity(0.7))
                            .overlay {
                                Label("Expired", systemImage: "exclamationmark.triangle.fill")
                                    .foregroundStyle(.red)
                                    .fontWeight(.semibold)
                                    .font(.title)
                                    .shadow(radius: 10, x: 0, y: 4)
                            }
                    }
                }
                .swipeActions(edge: .trailing) {
                    Button(role: .destructive) {
                        modelContext.delete(goal)
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                    
                    Button {
//                        activeSheet = .editOperation(goal)
                    } label: {
                        Label("Edit", systemImage: "pencil")
                    }
                    .tint(.blue)
                }
            }
        }
    }
}

#Preview {
    GoalList()
}
