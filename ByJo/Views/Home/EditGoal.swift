//
//  EditGoal.swift
//  ByJo
//
//  Created by Giuseppe Cosenza on 22/11/24.
//

import SwiftUI
import SwiftData

struct EditGoal:View {
    @Environment(\.modelContext) var modelContext
    @Environment(\.dismiss) var dismiss
    
    @Query var assets: [Asset]
    
    @Bindable var goal: Goal
    
    @State var isWithDueDate: Bool = false
    @State var date: Date = .now
    
    var body: some View {
        NavigationStack {
            List {
                TextField("Title", text: $goal.title)
                
                Picker("Asset", selection: $goal.asset) {
                    ForEach(assets) { asset in
                        Text(asset.name)
                            .tag(asset)
                    }
                }
                .pickerStyle(.menu)
                
                if let asset = goal.asset {
                
                    Text("Current Asset amount: ") + Text(asset.calculateCurrentBalance(), format: .currency(code: asset.currency.rawValue))
                    
                }
                
                if let assetGoal = goal.asset {
                    HStack {
                        Text("Target amount: ")
                        
                        TextField("Target amount", value: $goal.targetAmount, format: .currency(code: assetGoal.currency.rawValue))
                            .keyboardType(.decimalPad)
                    }
                }
                
                Button {
                    withAnimation {
                        isWithDueDate.toggle()
                    }
                } label: {
                    Label(!isWithDueDate ? "Add due date (optional)" : "Remove due date (optional)", systemImage: !isWithDueDate ? "plus" : "minus")
                }
                
                if isWithDueDate {
                    DatePicker("Due date", selection: $date, displayedComponents: .date)
                        .datePickerStyle(.compact)
                }
            }.toolbar {
                ToolbarItem (placement: .topBarLeading) {
                    Button (role: .destructive) {
                        modelContext.delete(goal)
                        
                        dismiss()
                    } label: {
                        Label("Delete", systemImage: "xmark")
                            .labelStyle(.titleOnly)
                    }
                    .foregroundColor(.red)
                }
                
                ToolbarItem (placement: .topBarTrailing) {
                    Button {
                        if isWithDueDate {
                            goal.dueDate = date
                        }
                        
                        dismiss()
                    } label: {
                        Label("Save", systemImage: "checkmark")
                            .labelStyle(.titleOnly)
                    }
                }
            }
        }
        .interactiveDismissDisabled(goal.title.isEmpty)
        .onAppear() {
            if goal.asset == nil {
                if let asset = assets.first {
                    goal.asset = asset
                }
            }
        }
    }
}

#Preview {
    EditGoal(goal: Goal(title: "", targetAmount: 0))
}
