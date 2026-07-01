//
//  OnboardingWelcomeStep.swift
//  ByJo
//

import SwiftUI

struct OnboardingWelcomeStep: View {
    let onStart: () -> Void

    @State private var appeared = false

    var body: some View {
        VStack(spacing: 30) {
            Spacer()

            VStack(spacing: 24) {
                ZStack {
                    Circle()
                        .fill(Color.accentColor.opacity(0.12))
                        .frame(width: 120, height: 120)

                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.system(size: 52, weight: .medium))
                        .foregroundStyle(Color.accentColor)
                }
                .scaleEffect(appeared ? 1.0 : 0.6)
                .onboardingAppear(appeared, delay: 0.05)

                VStack(spacing: 12) {
                    Text("ByJo")
                        .font(.system(size: 52, weight: .bold, design: .rounded))

                    Text("Your personal finance tracker.\nBuilt for clarity, not complexity.")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
                .onboardingAppear(appeared, delay: 0.18)
            }

            Spacer()

            Button(action: onStart) {
                Text("Get Started")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 4)
            }
            .buttonStyle(.borderedProminent)
            .buttonBorderShape(.capsule)
            .controlSize(.large)
            .padding(.horizontal, 24)
            .onboardingAppear(appeared, delay: 0.30)
        }
        .onAppear { appeared = true }
    }
}
