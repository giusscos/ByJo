//
//  OnboardingTransactionStep.swift
//  ByJo

import SwiftUI
import UIKit

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
    @State private var amountString = ""

    private var parsedAmount: Decimal? {
        guard !amountString.isEmpty else { return nil }
        let normalized = amountString.replacingOccurrences(of: ",", with: ".")
        return Decimal(string: normalized)
    }

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
                                Text("Record an inflow or outflow for ") +
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
                            Text("Description")
                                .font(.subheadline).fontWeight(.medium)
                                .foregroundStyle(.secondary)

                            TextField(
                                operationType == .inflow ? "e.g. Monthly Salary" : "e.g. Grocery Shopping",
                                text: $name
                            )
                            .padding(14)
                            .background(RoundedRectangle(cornerRadius: 12).fill(Color(.secondarySystemBackground)))
                            .focused($focusedField, equals: .name)
                            .autocorrectionDisabled()
                            .submitLabel(.next)
                            .onSubmit { focusedField = .amount }
                        }
                        .onboardingAppear(appeared, delay: 0.24)

                        VStack(alignment: .leading, spacing: 12) {
                            Text("Amount")
                                .font(.subheadline).fontWeight(.medium)
                                .foregroundStyle(.secondary)

                            VStack(spacing: 6) {
                                ZStack {
                                    TextField("0", text: $amountString)
                                        .font(.system(size: 52, weight: .bold, design: .rounded))
                                        .multilineTextAlignment(.center)
                                        .keyboardType(.decimalPad)
                                        .focused($focusedField, equals: .amount)

                                    if !amountString.isEmpty {
                                        HStack {
                                            Spacer()
                                            Button {
                                                amountString = ""
                                            } label: {
                                                Image(systemName: "xmark.circle.fill")
                                                    .font(.callout)
                                                    .foregroundStyle(.tertiary)
                                            }
                                            .buttonStyle(.plain)
                                        }
                                    }
                                }

                                if let value = parsedAmount {
                                    Text((operationType == .outflow ? value * -1 : value).formatted(.currency(code: currencyCode.rawValue)))
                                        .font(.callout)
                                        .foregroundStyle(operationType == .outflow ? .red : .secondary)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .padding(.horizontal, 14)
                            .background(RoundedRectangle(cornerRadius: 12).fill(Color(.secondarySystemBackground)))

                            HStack(spacing: 8) {
                                Button {
                                    operationType = .inflow
                                } label: {
                                    HStack(spacing: 6) {
                                        Image(systemName: "arrow.down.circle.fill")
                                        Text(OperationType.inflow.rawValue)
                                    }
                                    .frame(maxWidth: .infinity)
                                }
                                .buttonStyle(.bordered)
                                .tint(operationType == .inflow ? .green : .secondary)

                                Button {
                                    operationType = .outflow
                                } label: {
                                    HStack(spacing: 6) {
                                        Image(systemName: "arrow.up.circle.fill")
                                        Text(OperationType.outflow.rawValue)
                                    }
                                    .frame(maxWidth: .infinity)
                                }
                                .buttonStyle(.bordered)
                                .tint(operationType == .outflow ? .red : .secondary)
                            }
                        }
                        .id("amountField")
                        .onboardingAppear(appeared, delay: 0.32)
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
                .onChange(of: amountString) { _, _ in
                    amount = parsedAmount
                }
            }
        }
        .background(KeyboardDismissOnAppear())
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
            UITextField.appearance().clearButtonMode = .never
            appeared = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { focusedField = .name }
        }
        .onDisappear { focusedField = nil }
    }
}
