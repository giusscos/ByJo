//
//  OnboardingWelcomeStep.swift
//  ByJo
//

import SwiftUI

/// First screen: shows what ByJo gives you (one net worth across everything you own
/// and owe) instead of describing it.
struct OnboardingWelcomeStep: View {
    let currencyCode: CurrencyCode
    let onStart: () -> Void

    @State private var appeared = false

    private struct SampleRow: Identifiable {
        let id = UUID()
        let name: LocalizedStringKey
        let icon: String
        let color: Color
        let amount: Decimal
    }

    private let rows: [SampleRow] = [
        SampleRow(name: "Savings", icon: "building.columns.fill", color: .blue, amount: 24_000),
        SampleRow(name: "Investments", icon: "chart.line.uptrend.xyaxis", color: .green, amount: 30_500),
        SampleRow(name: "Car loan", icon: "car.fill", color: .red, amount: -6_250)
    ]

    private var netWorth: Decimal { rows.reduce(0) { $0 + $1.amount } }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 32) {
                previewCard
                    .padding(.top, 48)
                    .onboardingAppear(appeared, delay: 0.05)

                VStack(spacing: 12) {
                    Text("Your whole net worth.\nPrivate.")
                        .font(.largeTitle.bold())
                        .multilineTextAlignment(.center)

                    Text("No sign-up, no bank login. Your data stays on your devices and in your own iCloud.")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 16)
                }
                .onboardingAppear(appeared, delay: 0.18)
            }
            .padding(.horizontal, 24)
        }
        .background(KeyboardDismissOnAppear())
        .safeAreaInset(edge: .bottom) {
            Button(action: onStart) {
                Text("Get Started")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
            }
            .buttonStyle(.borderedProminent)
            .buttonBorderShape(.capsule)
            .controlSize(.large)
            .padding(.horizontal, 24)
            .padding(.bottom, 8)
            .onboardingAppear(appeared, delay: 0.30)
        }
        .onAppear { appeared = true }
    }

    private var previewCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Net Worth")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
                Text(netWorth, format: .currency(code: currencyCode.rawValue).precision(.fractionLength(0)))
                    .scaledFont(size: 40, weight: .bold, design: .rounded, maxSize: 72)
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
            }

            VStack(spacing: 12) {
                ForEach(rows) { row in
                    AdaptiveStack(spacing: 12) {
                        Image(systemName: row.icon)
                            .font(.subheadline)
                            .foregroundStyle(.white)
                            .frame(width: 32, height: 32)
                            .background(row.color.gradient, in: RoundedRectangle(cornerRadius: 8))
                        Text(row.name)
                            .font(.subheadline.weight(.medium))
                        Spacer(minLength: 0)
                        Text(row.amount, format: .currency(code: currencyCode.rawValue).precision(.fractionLength(0)))
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(row.amount < 0 ? .red : .primary)
                    }
                }
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 24))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("Example of a net worth made of savings, investments and a car loan"))
    }
}

#Preview {
    OnboardingWelcomeStep(currencyCode: .usd, onStart: {})
}
