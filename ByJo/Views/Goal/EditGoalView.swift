//
//  EditGoalView.swift
//  ByJo
//
//  Created by Giuseppe Cosenza on 22/11/24.
//

import SwiftData
import SwiftUI

struct EditGoalView: View {
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
    @State private var targetAmountString: String = ""
    @State private var statusTargetAmount: StatusBalance = .positive
    @State private var date: Date = .now
    @State private var hasDueDate: Bool = false

    @State private var isGoalCompleted: StatusGoal = .completed

    private var parsedTargetAmount: Decimal? {
        guard !targetAmountString.isEmpty else { return nil }
        let normalized = targetAmountString.replacingOccurrences(of: ",", with: ".")
        return Decimal(string: normalized)
    }

    var body: some View {
        NavigationStack {
            Form {
                if let goal, goal.isCompleted {
                    Section {
                        Picker("Is Goal completed?", selection: $isGoalCompleted) {
                            ForEach(StatusGoal.allCases, id: \.self) { status in
                                Text(status.rawValue).tag(status)
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
                        .onSubmit { focusedField = .targetAmount }
                }

                Section {
                    Picker("Asset", selection: $asset) {
                        ForEach(assets) { asset in
                            Text(asset.name).tag(asset)
                        }
                    }
                    .pickerStyle(.menu)

                    Text("Current: ") + Text(asset.calculateCurrentBalance(), format: .currency(code: currencyCode.rawValue))
                }

                Section {
                    VStack(spacing: 6) {
                        ZStack {
                            TextField("0", text: $targetAmountString)
                                .font(.system(size: 52, weight: .bold, design: .rounded))
                                .multilineTextAlignment(.center)
                                .keyboardType(.decimalPad)
                                .focused($focusedField, equals: .targetAmount)
                                .submitLabel(.done)
                                .onSubmit { focusedField = .none }

                            if !targetAmountString.isEmpty {
                                HStack {
                                    Spacer()
                                    Button {
                                        targetAmountString = ""
                                    } label: {
                                        Image(systemName: "xmark.circle.fill")
                                            .font(.callout)
                                            .foregroundStyle(.tertiary)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }

                        if let value = parsedTargetAmount {
                            Text((statusTargetAmount == .negative ? value * -1 : value).formatted(.currency(code: currencyCode.rawValue)))
                                .font(.callout)
                                .foregroundStyle(statusTargetAmount == .negative ? .red : .secondary)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)

                    HStack(spacing: 8) {
                        Button {
                            statusTargetAmount = .positive
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "plus.circle.fill")
                                Text("Positive")
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        .tint(statusTargetAmount == .positive ? .green : .secondary)

                        Button {
                            statusTargetAmount = .negative
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "minus.circle.fill")
                                Text("Negative")
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        .tint(statusTargetAmount == .negative ? .red : .secondary)
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
                if let goal {
                    ToolbarItem(placement: .topBarLeading) {
                        Button(role: .destructive) {
                            deleteGoal(goal: goal)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                        .tint(.red)
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    if #available(iOS 26, *) {
                        Button(role: .confirm) {
                            save()
                        } label: {
                            Label("Save", systemImage: "checkmark")
                        }
                        .disabled(title.isEmpty || targetAmountString.isEmpty)
                    } else {
                        Button {
                            save()
                        } label: {
                            Label("Save", systemImage: "checkmark")
                        }
                        .disabled(title.isEmpty || targetAmountString.isEmpty)
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
        .onAppear {
            UITextField.appearance().clearButtonMode = .never
            focusedField = .title

            guard let goal else { return }

            title = goal.title

            if let goalAsset = goal.asset {
                self.asset = goalAsset
            }

            targetAmountString = NSDecimalNumber(decimal: abs(goal.targetAmount)).stringValue

            if goal.targetAmount < 0 {
                statusTargetAmount = .negative
            }

            if let goalDate = goal.dueDate {
                hasDueDate = true
                date = goalDate
            }

            if let status = goal.completedStatus {
                isGoalCompleted = status
            }
        }
    }

    private func deleteGoal(goal: Goal) {
        modelContext.delete(goal)
        dismiss()
    }

    private func save() {
        var amount = parsedTargetAmount ?? .zero
        if statusTargetAmount == .negative && amount > 0 {
            amount = amount * -1
        }

        if let goal {
            goal.title = title
            goal.asset = asset
            goal.targetAmount = amount
            goal.startingAmount = asset.calculateCurrentBalance()
            goal.dueDate = hasDueDate ? date : nil

            if goal.isCompleted {
                goal.completedStatus = isGoalCompleted
            }

            dismiss()
            return
        }

        let newGoal = Goal(
            title: title,
            startingAmount: asset.calculateCurrentBalance(),
            targetAmount: amount,
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
