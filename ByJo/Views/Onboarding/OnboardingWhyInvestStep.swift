//
//  OnboardingWhyInvestStep.swift
//  ByJo
//

import SwiftUI

struct OnboardingWhyInvestStep: View {
    let onContinue: () -> Void

    @State private var appeared = false

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 30) {
                VStack(spacing: 24) {
                    ZStack {
                        Circle()
                            .fill(Color.green.opacity(0.12))
                            .frame(width: 100, height: 100)

                        Image(systemName: "list.bullet.clipboard.fill")
                            .font(.system(size: 44))
                            .foregroundStyle(.green)
                    }
                    .onboardingAppear(appeared, delay: 0.05)

                    VStack(spacing: 8) {
                        Text("Take Control of Your Budget")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .multilineTextAlignment(.center)

                        Text("Knowing where your money goes gives you the power to decide where it should go.")
                            .font(.body)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)
                    }
                    .onboardingAppear(appeared, delay: 0.14)
                }

                HStack(spacing: 12) {
                    StatCard(value: "~25%", label: "Of income goes\nuntracked each month", accent: .green)
                    StatCard(value: "−30%", label: "Less overspending\nwith regular tracking", accent: .green)
                }
                .padding(.horizontal, 24)
                .onboardingAppear(appeared, delay: 0.24)

                VStack(alignment: .leading, spacing: 14) {
                    FactRow(icon: "magnifyingglass.circle.fill", color: .green,
                            text: "Most people underestimate their monthly expenses by 20–30%.")
                        .onboardingAppear(appeared, delay: 0.32)

                    FactRow(icon: "chart.line.uptrend.xyaxis", color: .green,
                            text: "A simple spending log reveals patterns you'd never notice otherwise.")
                        .onboardingAppear(appeared, delay: 0.40)

                    FactRow(icon: "checkmark.seal.fill", color: .green,
                            text: "Budgeting isn't about restriction — it's about making intentional choices.")
                        .onboardingAppear(appeared, delay: 0.48)
                }
                .padding(.horizontal, 24)
            }
        }
        .scrollDismissesKeyboard(.interactively)
        .ignoresSafeArea(.keyboard)
        .toolbar {
            ToolbarItemGroup(placement: .bottomBar) {
                Spacer()
                Button(action: onContinue) {
                    Text("Let's Set Up ByJo")
                        .font(.headline)
                }
                .buttonStyle(.borderedProminent)
                .buttonBorderShape(.capsule)
                .controlSize(.large)
                Spacer()
            }
        }
        .onAppear { appeared = true }
    }
}
