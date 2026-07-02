//
//  OnboardingWhySaveStep.swift
//  ByJo
//

import SwiftUI

struct OnboardingWhySaveStep: View {
    let onContinue: () -> Void

    @State private var appeared = false

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 32) {
                VStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(Color.blue.opacity(0.12))
                            .frame(width: 100, height: 100)

                        Image(systemName: "chart.bar.fill")
                            .font(.system(size: 44))
                            .foregroundStyle(.blue)
                    }
                    .onboardingAppear(appeared, delay: 0.05)

                    VStack(spacing: 8) {
                        Text("Know Your Net Worth")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .multilineTextAlignment(.center)

                        Text("Your net worth — assets minus liabilities — is the clearest snapshot of your financial health.")
                            .font(.body)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)
                    }
                    .onboardingAppear(appeared, delay: 0.14)
                }
                .padding(.top, 56)

                HStack(spacing: 12) {
                    StatCard(value: "1 in 3", label: "People don't know\ntheir net worth", accent: .blue)
                    StatCard(value: "3×", label: "More likely to hit\ngoals when tracking", accent: .blue)
                }
                .padding(.horizontal, 24)
                .onboardingAppear(appeared, delay: 0.24)

                VStack(alignment: .leading, spacing: 14) {
                    FactRow(icon: "eye.fill", color: .blue,
                            text: "You can't improve what you don't measure — tracking is the first step.")
                        .onboardingAppear(appeared, delay: 0.32)

                    FactRow(icon: "arrow.up.right.circle.fill", color: .blue,
                            text: "Seeing your net worth grow month over month is the best motivation to keep going.")
                        .onboardingAppear(appeared, delay: 0.40)

                    FactRow(icon: "bell.badge.fill", color: .blue,
                            text: "Spotting a downward trend early lets you act before it becomes a bigger problem.")
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
                    Text("Next")
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
