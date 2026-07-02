//
//  OnboardingTransactionStep.swift
//  ByJo
//

import SwiftUI

struct OnboardingTransactionStep: View {
    enum FocusField: Hashable { case name, amount }

    @Binding var name: String
    @Binding var amount: Decimal?
    @Binding var operationType: OperationType
    let assetName: String
    let currencyCode: CurrencyCode
    let onContinue: () -> Void
    let onSkip: () -> Void

    @FocusState private var focusedField: FocusField?
    @State private var appeared = false

    var body: some View {
        ScrollView(showsIndicators: false) {
            ScrollViewReader { proxy in
                VStack(spacing: 24) {
                    VStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(Color.accentColor.opacity(0.12))
                                .frame(width: 100, height: 100)

                            Image(systemName: "arrow.up.arrow.down.circle.fill")
                                .font(.system(size: 44))
                                .foregroundStyle(Color.accentColor)
                        }
                        .onboardingAppear(appeared, delay: 0.05)

                        VStack(spacing: 8) {
                            Text("Log a Transaction")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .multilineTextAlignment(.center)

                            Group {
                                Text("Record an income or expense for ") +
                                Text(assetName.isEmpty ? "your asset" : assetName).fontWeight(.semibold) +
                                Text(".")
                            }
                            .font(.body)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                        }
                        .onboardingAppear(appeared, delay: 0.14)
                    }
                    .padding(.top, 16)

                    VStack(spacing: 16) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Type")
                                .font(.subheadline).fontWeight(.medium)
                                .foregroundStyle(.secondary)

                            Picker("Type", selection: $operationType) {
                                ForEach(OperationType.allCases, id: \.self) { Text($0.rawValue) }
                            }
                            .pickerStyle(.segmented)
                            .onChange(of: operationType) { _, newValue in
                                if let a = amount { amount = newValue == .expense ? (a > 0 ? a * -1 : a) : abs(a) }
                            }
                        }
                        .onboardingAppear(appeared, delay: 0.24)

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Description")
                                .font(.subheadline).fontWeight(.medium)
                                .foregroundStyle(.secondary)

                            TextField(
                                operationType == .income ? "e.g. Monthly Salary" : "e.g. Grocery Shopping",
                                text: $name
                            )
                            .padding(14)
                            .background(RoundedRectangle(cornerRadius: 12).fill(Color(.secondarySystemBackground)))
                            .focused($focusedField, equals: .name)
                            .autocorrectionDisabled()
                            .submitLabel(.next)
                            .onSubmit { focusedField = .amount }
                        }
                        .onboardingAppear(appeared, delay: 0.32)

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Amount")
                                .font(.subheadline).fontWeight(.medium)
                                .foregroundStyle(.secondary)

                            HStack(spacing: 8) {
                                Text(currencyCode.symbol)
                                    .foregroundStyle(amount == nil ? .secondary : .primary)

                                TextField("0.00", value: $amount, format: .number.precision(.fractionLength(2)))
                                    .keyboardType(.decimalPad)
                                    .focused($focusedField, equals: .amount)
                            }
                            .padding(14)
                            .background(RoundedRectangle(cornerRadius: 12).fill(Color(.secondarySystemBackground)))
                        }
                        .id("amountField")
                        .onboardingAppear(appeared, delay: 0.40)
                    }
                    .padding(.horizontal, 24)
                }
                .onChange(of: focusedField) { _, newValue in
                    if newValue == .amount {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            proxy.scrollTo("amountField", anchor: .bottom)
                        }
                    }
                }
            }
        }
        .background(KeyboardDismissOnAppear())
        .scrollDismissesKeyboard(.interactively)
        .ignoresSafeArea(.keyboard)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: onSkip) {
                    Text("Skip")
                        .foregroundStyle(.secondary)
                }
            }

            ToolbarItem(placement: .topBarTrailing) {
                Button("Save", action: onContinue)
                    .buttonStyle(.borderedProminent)
                    .buttonBorderShape(.capsule)
            }

            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button { focusedField = nil } label: {
                    Label("Dismiss keyboard", systemImage: "keyboard.chevron.compact.down")
                        .font(.subheadline.weight(.semibold))
                }
            }
        }
        .onAppear {
            appeared = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { focusedField = .name }
        }
        .onDisappear { focusedField = nil }
    }
}
