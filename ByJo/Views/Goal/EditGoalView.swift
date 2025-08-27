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
    
    @AppStorage("currencyCode") var currencyCode: CurrencyCode = .usd
    
    @Query var assets: [Asset]
    
    var goal: Goal?
    
    @State private var title: String = ""
    @State var asset: Asset
    @State private var targetAmount: Decimal?
    @State private var statusTargetAmount: StatusBalance = .positive
    @State private var date: Date = .now
    @State private var hasDueDate: Bool = false
    
    @State private var isGoalCompleted: StatusGoal = .completed
    
    var nilBalance: Bool {
        targetAmount == nil || targetAmount == .zero
    }
    
    var body: some View {
        NavigationStack {
            Form {
                if let goal = goal, let _ = goal.completedGoal {
                    Section {
                        Picker("Is Goal completed?", selection: $isGoalCompleted) {
                            ForEach(StatusGoal.allCases, id: \.self) { status in
                                Text("\(status.rawValue)")
                                    .tag(status)
                            }
                        }
                        .pickerStyle(.segmented)
                    }
                }
                
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
                    Picker("Status target amount", selection: $statusTargetAmount) {
                        ForEach(StatusBalance.allCases, id: \.self) { status in
                            Text(status.rawValue)
                        }
                    }
                    .pickerStyle(.segmented)
                    .disabled(targetAmount == nil)
                    .onChange(of: statusTargetAmount) { oldValue, newValue in
                        if let amountValue = targetAmount {
                            if amountValue > 0, newValue == .negative {
                                targetAmount = amountValue * -1
                            } else {
                                targetAmount = abs(amountValue)
                            }
                        }
                    }
                    
                    Text("Current: ") + Text(asset.calculateCurrentBalance(), format: .currency(code: currencyCode.rawValue))
                                 
                    HStack (spacing: 6) {
                        Text(currencyCode.symbol)
                            .foregroundStyle(nilBalance ? .secondary : .primary)
                            .opacity(nilBalance ? 0.5 : 1)
                        
                        TextField("Target amount", value: $targetAmount, format: .number.precision(.fractionLength(2)))
                            .keyboardType(.decimalPad)
                            .focused($focusedField, equals: .targetAmount)
                            .submitLabel(.done)
                            .onSubmit {
                                focusedField = .none
                            }
                    }
                }
                .listRowSeparator(.hidden)
                
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
                    if #available(iOS 26, *) {
                        Button (role: .confirm) {
                            save()
                        } label: {
                            Label("Save", systemImage: "checkmark")
                        }
                        .disabled(title.isEmpty || targetAmount == nil)
                    } else {
                        Button {
                            save()
                        } label: {
                            Label("Save", systemImage: "checkmark")
                        }
                        .disabled(title.isEmpty || targetAmount == nil)
                    }
                }
                
                ToolbarItem(placement: .keyboard) {
                    Button {
                        focusedField = .none
                    } label: {
                        Label("Hide keyboard", systemImage: "keyboard.chevron.compact.down")
                    }
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
                
                if goal.targetAmount < 0 {
                    statusTargetAmount = .negative
                }
                
                if let goalDate = goal.dueDate {
                    hasDueDate = true
                    date = goalDate
                }
                
                if let completedGoal = goal.completedGoal {
                    isGoalCompleted = completedGoal.status
                }
                
                return
            }
        }
    }
    
    private func deleteGoal(goal: Goal) {
        modelContext.delete(goal)
        
        dismiss()
    }
    
    private func save() {
        if let amountValue = targetAmount {
            if amountValue < 0, statusTargetAmount == .positive {
                targetAmount = abs(amountValue)
            } else if amountValue > 0, statusTargetAmount == .negative {
                targetAmount = amountValue * -1
            }
        }
        
        if let goal = goal {
            goal.title = title
            goal.asset = asset
            goal.targetAmount = targetAmount ?? .zero
            goal.startingAmount = asset.calculateCurrentBalance()
            
            goal.dueDate = hasDueDate ? date : nil
            
            if let completedGoal = goal.completedGoal {
                completedGoal.status = isGoalCompleted
            }
            
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
