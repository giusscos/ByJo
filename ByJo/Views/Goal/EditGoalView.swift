//
//  EditGoalView.swift
//  ByJo
//
//  Created by Giuseppe Cosenza on 22/11/24.
//

import SwiftData
import SwiftUI

struct EditGoalView:View {
    enum FocusField: Hashable {
        case title
        case targetAmount
    }
    
    @FocusState private var focusedField: FocusField?
    
    @Environment(\.modelContext) var modelContext
    @Environment(\.dismiss) var dismiss
    
    @Query var assets: [Asset]
    
    var goal: Goal?
    
    @State private var title: String = ""
    @State var asset: Asset
    @State private var targetAmount: Decimal?
    @State private var date: Date = .now
    @State private var hasDueDate: Bool = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Title", text: $title)
                        .autocorrectionDisabled()
                        .focused($focusedField, equals: .title)
                        .submitLabel(.next)
                        .onSubmit {
                            focusedField = .targetAmount
                        }
                }
                
                Section {
                    Picker("Asset", selection: $asset) {
                        ForEach(assets) { asset in
                            Text(asset.name)
                                .tag(asset)
                        }
                    }
                    .pickerStyle(.menu)
                }
                
                Section {
                    Text("Current Asset amount: ") + Text(asset.calculateCurrentBalance(), format: .currency(code: asset.currency.rawValue))
                                            
                    TextField("Target amount", value: $targetAmount, format: .number)
                        .keyboardType(.decimalPad)
                        .focused($focusedField, equals: .targetAmount)
                        .submitLabel(.done)
                        .onSubmit {
                            focusedField = .none
                        }
                }
                Section {
                    Toggle("Due date", isOn: $hasDueDate.animation())
                    
                    if hasDueDate {
                        DatePicker("Due date", selection: $date, displayedComponents: .date)
                            .datePickerStyle(.compact)
                    }
                }
            }
            .navigationTitle(goal == nil ? "Create goal" : "Edit goal")
            .toolbar {
                if let goal = goal {
                    ToolbarItem (placement: .topBarLeading) {
                        Button(role: .destructive) {
                            deleteGoal(goal: goal)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                        .tint(.red)
                    }
                }
                
                ToolbarItem (placement: .topBarTrailing) {
                    Button {
                        saveGoal()
                    } label: {
                        Label("Save", systemImage: "checkmark")
                    }
                    .disabled(title.isEmpty)
                }
            }
        }
        .onAppear() {
            if let goal = goal {
                title = goal.title
                
                if let asset = goal.asset {
                    self.asset = asset
                }
                
                targetAmount = goal.targetAmount
                
                if let goalDate = goal.dueDate {
                    hasDueDate = true
                    date = goalDate
                }
                return
            }
        }
    }
    
    private func deleteGoal(goal: Goal) {
        modelContext.delete(goal)
        
        dismiss()
    }
    
    private func saveGoal() {
        if let goal = goal {
            goal.title = title
            goal.asset = asset
            goal.targetAmount = targetAmount ?? .zero
            goal.startingAmount = asset.calculateCurrentBalance()
            
            goal.dueDate = hasDueDate ? date : nil
            
            dismiss()
            
            return
        }
        
        let newGoal = Goal(
            title: title,
            startingAmount: asset.calculateCurrentBalance(),
            targetAmount: targetAmount ?? 0.0,
            dueDate: hasDueDate ? date : nil,
            asset: asset
        )
        
        modelContext.insert(newGoal)
        
        dismiss()
    }
}

#Preview {
    EditGoalView(
        goal: Goal(title: "", startingAmount: 100.0, targetAmount: 0.0),
        asset: Asset(name: "BuddyBank", initialBalance: 1000.0)
    )
}
