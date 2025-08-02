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
                if let dueDate = goal.dueDate {
                    HStack (spacing: 0){
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
        .background(.thinMaterial)
        .clipShape(.rect(cornerRadius: 12))
        .shadow(color: .black.opacity(0.12), radius: 8, y: 4)
    }
}

#Preview {
    GoalRowView(
        goal: Goal(title: "Buy the brand new iPhone 17", startingAmount: 100.0, targetAmount: 999.99, dueDate: .now),
        asset: Asset(name: "BuddyBank", initialBalance: 100.0))
}
