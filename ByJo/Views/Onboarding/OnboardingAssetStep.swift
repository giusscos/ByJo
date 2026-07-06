//
//  OnboardingAssetStep.swift
//  ByJo
//

import SwiftUI

struct OnboardingAssetStep: View {
    enum FocusField: Hashable { case name, balance }

    @Binding var name: String
    @Binding var type: AssetType
    @Binding var balance: Decimal?
    @Binding var statusBalance: StatusBalance
    let currencyCode: CurrencyCode
    let onContinue: () -> Void

    @FocusState private var focusedField: FocusField?
    @State private var appeared = false

    private var isDisabled: Bool { name.isEmpty || balance == nil }

    var body: some View {
        ScrollView(showsIndicators: false) {
            ScrollViewReader { proxy in
                VStack(spacing: 30) {
                    VStack(spacing: 24) {
                        ZStack {
                            Circle()
                                .fill(Color.accentColor.opacity(0.12))
                                .frame(width: 100, height: 100)

                            Image(systemName: "briefcase.fill")
                                .font(.system(size: 44))
                                .foregroundStyle(Color.accentColor)
                        }
                        .onboardingAppear(appeared, delay: 0.05)

                        VStack(spacing: 8) {
                            Text("Add Your First Asset")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .multilineTextAlignment(.center)

                            Text("Track a bank account, savings, investments, or anything of value.")
                                .font(.body)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 32)
                        }
                        .onboardingAppear(appeared, delay: 0.14)
                    }

                    VStack(spacing: 16) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Name")
                                .font(.subheadline).fontWeight(.medium)
                                .foregroundStyle(.secondary)

                            TextField("e.g. My Bank Account", text: $name)
                                .padding(14)
                                .background(RoundedRectangle(cornerRadius: 12).fill(Color(.secondarySystemBackground)))
                                .focused($focusedField, equals: .name)
                                .autocorrectionDisabled()
                                .submitLabel(.next)
                                .onSubmit { focusedField = .balance }
                        }
                        .onboardingAppear(appeared, delay: 0.24)

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Type")
                                .font(.subheadline).fontWeight(.medium)
                                .foregroundStyle(.secondary)

                            Menu {
                                ForEach(AssetType.allCases, id: \.self) { assetType in
                                    Button(assetType.rawValue) { type = assetType }
                                }
                            } label: {
                                HStack {
                                    Text(type.rawValue).foregroundColor(.primary)
                                    Spacer()
                                    Image(systemName: "chevron.up.chevron.down")
                                        .foregroundStyle(.secondary).font(.caption)
                                }
                                .padding(14)
                                .background(RoundedRectangle(cornerRadius: 12).fill(Color(.secondarySystemBackground)))
                            }
                        }
                        .onboardingAppear(appeared, delay: 0.32)

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Current Balance")
                                .font(.subheadline).fontWeight(.medium)
                                .foregroundStyle(.secondary)

                            Picker("Balance status", selection: $statusBalance) {
                                ForEach(StatusBalance.allCases, id: \.self) { Text($0.rawValue) }
                            }
                            .pickerStyle(.segmented)
                            .disabled(balance == nil)
                            .onChange(of: statusBalance) { _, newValue in
                                if let b = balance {
                                    balance = newValue == .negative ? (b > 0 ? b * -1 : b) : abs(b)
                                }
                            }

                            HStack(spacing: 8) {
                                Text(currencyCode.symbol)
                                    .foregroundStyle(balance == nil ? .secondary : .primary)

                                TextField("0.00", value: $balance, format: .number.precision(.fractionLength(2)))
                                    .keyboardType(.decimalPad)
                                    .focused($focusedField, equals: .balance)
                            }
                            .padding(14)
                            .background(RoundedRectangle(cornerRadius: 12).fill(Color(.secondarySystemBackground)))
                        }
                        .id("balanceField")
                        .onboardingAppear(appeared, delay: 0.40)
                    }
                    .padding(.horizontal, 24)
                }
                .onChange(of: focusedField) { _, newValue in
                    if newValue == .balance {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            proxy.scrollTo("balanceField", anchor: .bottom)
                        }
                    }
                }
            }
        }
        .background(KeyboardDismissOnAppear())
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Save", action: onContinue)
                    .buttonStyle(.borderedProminent)
                    .buttonBorderShape(.capsule)
                    .disabled(isDisabled)
            }
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button { focusedField = nil } label: {
                    Label("Compact keyboard", systemImage: "keyboard.chevron.compact.down")
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
