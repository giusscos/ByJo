//
//  OnboardingCurrencyStep.swift
//  ByJo

import SwiftUI

struct OnboardingCurrencyStep: View {
    @Binding var currencyCode: CurrencyCode
    let onContinue: () -> Void

    @State private var appeared = false

    private let popularCurrencies: [CurrencyCode] = [
        .usd, .eur, .gbp, .jpy, .cad, .aud,
        .chf, .cny, .inr, .brl, .mxn, .krw,
        .sek, .sgd, .hkd, .nzd, .tryy, .pln
    ]

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 24) {
                VStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(Color.accentColor.opacity(0.12))
                            .frame(width: 100, height: 100)

                        Image(systemName: "dollarsign.circle.fill")
                            .font(.system(size: 44))
                            .foregroundStyle(Color.accentColor)
                    }
                    .onboardingAppear(appeared, delay: 0.05)

                    VStack(spacing: 8) {
                        Text("Choose Your Currency")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .multilineTextAlignment(.center)

                        Text("Select how amounts are displayed. You can change this anytime.")
                            .font(.body)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                    }
                    .onboardingAppear(appeared, delay: 0.14)
                }
                .padding(.top, 16)

                LazyVGrid(
                    columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())],
                    spacing: 12
                ) {
                    ForEach(popularCurrencies, id: \.self) { currency in
                        Button {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                currencyCode = currency
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                                onContinue()
                            }
                        } label: {
                            VStack(spacing: 4) {
                                Text(currency.symbol)
                                    .font(.title2)
                                    .fontWeight(.semibold)
                                Text(currency.rawValue)
                                    .font(.caption)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(currencyCode == currency ? Color.accentColor : Color(.secondarySystemBackground))
                            )
                            .foregroundColor(currencyCode == currency ? .white : .primary)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 24)
                .onboardingAppear(appeared, delay: 0.24)
            }
        }
        .background(KeyboardDismissOnAppear())
        .onAppear { appeared = true }
    }
}
