//
//  OnboardingPlansStep.swift
//  ByJo
//

import SwiftData
import SwiftUI

/// Last onboarding screen: the net worth the user just set up, ByJo Pro's plans, and a
/// way to keep going on the free plan.
struct OnboardingPlansStep: View {
    var store: Store
    let onContinueFree: () -> Void

    @AppStorage("currencyCode") private var currencyCode: CurrencyCode = .usd
    @Query private var assets: [Asset]
    @State private var selectedPlanID = ""

    private var netWorth: Decimal {
        assets.reduce(0) { $0 + $1.calculateCurrentBalance() }
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 24) {
                if !assets.isEmpty {
                    netWorthCard
                }

                VStack(spacing: 8) {
                    Text("ByJo Pro")
                        .font(.largeTitle.bold())
                    Text("Every account, goal and widget, with no limits.")
                        .font(.body)
                        .foregroundStyle(.secondary)
                }
                .multilineTextAlignment(.center)

                if store.yearlyProduct != nil || store.weeklyProduct != nil || store.lifetimeProduct != nil {
                    PlanPicker(store: store, selectedID: $selectedPlanID)
                } else if store.isLoading {
                    ProgressView()
                }

                ProFeatureList()
                    .padding(16)
                    .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 16))
            }
            .padding(24)
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            VStack(spacing: 12) {
                PlanPurchaseButton(store: store, selectedID: selectedPlanID)

                Button(action: onContinueFree) {
                    Text("Continue for free")
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderless)

                PaywallLegalFooter(store: store)
            }
            .padding(.horizontal, 24)
            .padding(.top, 12)
            .padding(.bottom, 8)
            .background { BottomBarFade() }
        }
        .navigationBarBackButtonHidden(true)
        .onAppear {
            if selectedPlanID.isEmpty { selectedPlanID = store.yearlyProductId }
        }
    }

    /// Shows what the user already built, so the plans unlock something that is theirs.
    private var netWorthCard: some View {
        VStack(spacing: 6) {
            Label("Your net worth is ready", systemImage: "checkmark.seal.fill")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(Color.accentColor)

            Text(netWorth, format: .currency(code: currencyCode.rawValue))
                .font(.system(size: 40, weight: .bold, design: .rounded))
                .minimumScaleFactor(0.5)
                .lineLimit(1)

            Text("Tracked assets: \(assets.count)")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .padding(.horizontal, 16)
        .background(
            LinearGradient(
                colors: [Color.accentColor.opacity(0.18), Color.accentColor.opacity(0.06)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 20)
        )
    }
}

#Preview {
    NavigationStack {
        OnboardingPlansStep(store: Store(), onContinueFree: {})
    }
    .modelContainer(for: Asset.self, inMemory: true)
}
