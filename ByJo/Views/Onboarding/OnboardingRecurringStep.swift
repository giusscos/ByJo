//
//  OnboardingRecurringStep.swift
//  ByJo
//

import SwiftUI
import UserNotifications

struct OnboardingRecurringStep: View {
    enum FocusField: Hashable { case name, amount }

    @Binding var name: String
    @Binding var amount: Decimal?
    @Binding var operationType: OperationType
    @Binding var frequency: RecurrenceFrequency
    let assetName: String
    let currencyCode: CurrencyCode
    let onContinue: () -> Void
    let onSkip: () -> Void

    @FocusState private var focusedField: FocusField?
    @State private var notificationStatus: UNAuthorizationStatus = .notDetermined
    @State private var appeared = false

    private let recurringFrequencies = RecurrenceFrequency.allCases.filter { $0 != .single }

    var body: some View {
        ScrollView(showsIndicators: false) {
            ScrollViewReader { proxy in
                VStack(spacing: 24) {
                    VStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(Color.accentColor.opacity(0.12))
                                .frame(width: 100, height: 100)

                            Image(systemName: "clock.arrow.circlepath")
                                .font(.system(size: 44))
                                .foregroundStyle(Color.accentColor)
                        }
                        .onboardingAppear(appeared, delay: 0.05)

                        VStack(spacing: 8) {
                            Text("Set Up a Recurring Payment")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .multilineTextAlignment(.center)

                            Group {
                                Text("Automate a salary, subscription, or bill for ") +
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
                                ForEach(OperationType.allCases, id: \.self) { Text($0.displayName) }
                            }
                            .pickerStyle(.segmented)
                            .onChange(of: operationType) { _, newValue in
                                if let a = amount { amount = newValue == .outflow ? (a > 0 ? a * -1 : a) : abs(a) }
                            }
                        }
                        .onboardingAppear(appeared, delay: 0.24)

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Description")
                                .font(.subheadline).fontWeight(.medium)
                                .foregroundStyle(.secondary)

                            TextField(
                                operationType == .inflow ? "e.g. Monthly Salary" : "e.g. Netflix",
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

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Repeats")
                                .font(.subheadline).fontWeight(.medium)
                                .foregroundStyle(.secondary)

                            Menu {
                                ForEach(recurringFrequencies, id: \.self) { freq in
                                    Button(freq.displayName) { frequency = freq }
                                }
                            } label: {
                                HStack {
                                    Text(frequency.displayName).foregroundColor(.primary)
                                    Spacer()
                                    Image(systemName: "chevron.up.chevron.down")
                                        .foregroundStyle(.secondary).font(.caption)
                                }
                                .padding(14)
                                .background(RoundedRectangle(cornerRadius: 12).fill(Color(.secondarySystemBackground)))
                            }
                        }
                        .onboardingAppear(appeared, delay: 0.48)

                        notificationBanner
                            .onboardingAppear(appeared, delay: 0.56)
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
        .toolbar {
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
            checkNotificationStatus()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { focusedField = .name }
        }
        .onDisappear { focusedField = nil }
    }

    @ViewBuilder
    private var notificationBanner: some View {
        switch notificationStatus {
        case .notDetermined:
            HStack(spacing: 12) {
                Image(systemName: "bell.badge.fill")
                    .font(.title3)
                    .foregroundStyle(Color.accentColor)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Enable Reminders")
                        .font(.subheadline).fontWeight(.semibold)
                    Text("Get notified when recurring payments are due.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Button("Allow") { requestNotificationPermission() }
                    .font(.subheadline).fontWeight(.semibold)
                    .buttonStyle(.borderedProminent)
                    .buttonBorderShape(.capsule)
                    .controlSize(.small)
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.accentColor.opacity(0.08))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.accentColor.opacity(0.2), lineWidth: 1))
            )

        case .authorized:
            HStack(spacing: 10) {
                Image(systemName: "bell.fill").foregroundStyle(.green)
                Text("Reminders enabled").font(.subheadline).foregroundStyle(.secondary)
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: 12).fill(Color.green.opacity(0.08)))

        default:
            EmptyView()
        }
    }

    private func checkNotificationStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async { notificationStatus = settings.authorizationStatus }
        }
    }

    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, _ in
            DispatchQueue.main.async { notificationStatus = granted ? .authorized : .denied }
        }
    }
}
