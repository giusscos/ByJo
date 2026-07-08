//
//  OnboardingAssetStep.swift
//  ByJo

import SwiftUI
import UIKit

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
    @State private var balanceString = ""

    private var parsedBalance: Decimal? {
        guard !balanceString.isEmpty else { return nil }
        let normalized = balanceString.replacingOccurrences(of: ",", with: ".")
        return Decimal(string: normalized)
    }

    private var isDisabled: Bool { name.isEmpty || balanceString.isEmpty }

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
                                    Button(assetType.displayName) { type = assetType }
                                }
                            } label: {
                                HStack {
                                    Text(type.displayName).foregroundColor(.primary)
                                    Spacer()
                                    Image(systemName: "chevron.up.chevron.down")
                                        .foregroundStyle(.secondary).font(.caption)
                                }
                                .padding(14)
                                .background(RoundedRectangle(cornerRadius: 12).fill(Color(.secondarySystemBackground)))
                            }
                        }
                        .onboardingAppear(appeared, delay: 0.32)

                        VStack(alignment: .leading, spacing: 12) {
                            Text("Current Balance")
                                .font(.subheadline).fontWeight(.medium)
                                .foregroundStyle(.secondary)

                            VStack(spacing: 6) {
                                ZStack {
                                    TextField("0", text: $balanceString)
                                        .font(.system(size: 52, weight: .bold, design: .rounded))
                                        .multilineTextAlignment(.center)
                                        .keyboardType(.decimalPad)
                                        .focused($focusedField, equals: .balance)

                                    if !balanceString.isEmpty {
                                        HStack {
                                            Spacer()
                                            Button {
                                                balanceString = ""
                                            } label: {
                                                Image(systemName: "xmark.circle.fill")
                                                    .font(.callout)
                                                    .foregroundStyle(.tertiary)
                                            }
                                            .buttonStyle(.plain)
                                        }
                                    }
                                }

                                if let value = parsedBalance {
                                    Text((statusBalance == .negative ? value * -1 : value).formatted(.currency(code: currencyCode.rawValue)))
                                        .font(.callout)
                                        .foregroundStyle(statusBalance == .negative ? .red : .secondary)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .padding(.horizontal, 14)
                            .background(RoundedRectangle(cornerRadius: 12).fill(Color(.secondarySystemBackground)))

                            HStack(spacing: 8) {
                                Button {
                                    statusBalance = .positive
                                } label: {
                                    HStack(spacing: 6) {
                                        Image(systemName: "plus.circle.fill")
                                        Text("Positive")
                                    }
                                    .frame(maxWidth: .infinity)
                                }
                                .buttonStyle(.bordered)
                                .tint(statusBalance == .positive ? .green : .secondary)

                                Button {
                                    statusBalance = .negative
                                } label: {
                                    HStack(spacing: 6) {
                                        Image(systemName: "minus.circle.fill")
                                        Text("Negative")
                                    }
                                    .frame(maxWidth: .infinity)
                                }
                                .buttonStyle(.bordered)
                                .tint(statusBalance == .negative ? .red : .secondary)
                            }
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
                .onChange(of: balanceString) { _, _ in
                    balance = parsedBalance
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
            UITextField.appearance().clearButtonMode = .never
            appeared = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { focusedField = .name }
        }
        .onDisappear { focusedField = nil }
    }
}
