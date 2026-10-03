//
//  PaywallView.swift
//  ByJo
//
//  Created by Giuseppe Cosenza on 28/07/25.
//

import StoreKit
import SwiftData
import SwiftUI

struct PaywallView: View {
    var store: Store
    @State private var showLifetimePlans: Bool = false
    @State private var trialDays: Int? = nil
    @State private var yearlyPrice: String? = nil
    @State private var savingsPercent: Int? = nil

    @AppStorage("currencyCode") private var currencyCode: CurrencyCode = .usd
    @Query private var assets: [Asset]

    private let features = [
        "Track every asset and account",
        "Set goals and watch them grow",
        "Never miss a scheduled payment",
        "Your full net worth, at a glance"
    ]

    private var netWorth: Decimal {
        assets.reduce(0) { $0 + $1.calculateCurrentBalance() }
    }

    var body: some View {
        NavigationStack {
            SubscriptionStoreView(productIDs: store.paywallProductIds) {
                VStack(spacing: 24) {
                    if assets.isEmpty {
                        appIcon
                            .padding(.top, 36)
                    } else {
                        netWorthCard
                            .padding(.top, 36)
                            .padding(.horizontal, 20)
                    }

                    header

                    VStack(alignment: .leading, spacing: 14) {
                        ForEach(features, id: \.self) { feature in
                            Label {
                                Text(LocalizedStringKey(feature))
                                    .font(.subheadline)
                            } icon: {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(Color.accentColor)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(20)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
                    .padding(.horizontal, 20)

                    Button {
                        showLifetimePlans = true
                    } label: {
                        Label("Pay once, use forever", systemImage: "infinity")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                    }
                    .tint(.accentColor)
                    .buttonStyle(.borderedProminent)
                    .buttonBorderShape(.capsule)

                    HStack(spacing: 6) {
                        Link("Terms", destination: URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!)
                            .buttonStyle(.borderless)
                        Text("·")
                            .foregroundStyle(.secondary)
                        Link("Privacy", destination: URL(string: "https://by-jo.com/privacy")!)
                            .buttonStyle(.borderless)
                    }
                    .font(.caption)
                    .padding(.bottom, 12)
                }
            }
            .subscriptionStoreControlStyle(.pagedProminentPicker, placement: .bottomBar)
            .subscriptionStoreButtonLabel(.multiline)
            .storeButton(.visible, for: .restorePurchases)
            .storeButton(.hidden, for: .cancellation)
            .storeButton(.hidden, for: .policies)
            .interactiveDismissDisabled()
            .sheet(isPresented: $showLifetimePlans) {
                PaywallLifetimeView(store: store)
                    .presentationDetents(.init([.medium]))
            }
            .task {
                trialDays = await store.eligibleTrialDays()
                yearlyPrice = await store.yearlyDisplayPrice()
                savingsPercent = await store.yearlySavingsPercent()
            }
        }
    }

    private var appIcon: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 22)
                .fill(LinearGradient(
                    colors: [Color.accentColor, Color.accentColor.opacity(0.7)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))
                .frame(width: 88, height: 88)
                .shadow(color: Color.accentColor.opacity(0.4), radius: 16, y: 6)

            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 38, weight: .semibold))
                .foregroundStyle(.white)
        }
    }

    /// Shows the data the user entered during onboarding, so the paywall unlocks
    /// something that is already theirs instead of a generic promise.
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

    @ViewBuilder
    private var savingsBadge: some View {
        if let savingsPercent {
            Text("Yearly saves \(savingsPercent)% vs weekly")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
                .background(Color.accentColor, in: Capsule())
        }
    }

    /// Spells out when the reminder fires and when billing starts, which makes
    /// starting a trial feel low-risk.
    private func trialTimeline(days: Int) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            timelineRow(
                icon: "lock.open.fill",
                title: Text("Today"),
                detail: Text("Full access to every feature"),
                isLast: false
            )
            timelineRow(
                icon: "bell.fill",
                title: Text("Day \(max(days - 1, 1))"),
                detail: Text("We'll remind you before your trial ends"),
                isLast: false
            )
            timelineRow(
                icon: "star.fill",
                title: Text("Day \(days)"),
                detail: yearlyPrice.map { Text("\($0) per year starts. Cancel anytime before.") }
                    ?? Text("Your yearly plan starts. Cancel anytime before."),
                isLast: true
            )
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    private func timelineRow(icon: String, title: Text, detail: Text, isLast: Bool) -> some View {
        HStack(alignment: .top, spacing: 14) {
            VStack(spacing: 0) {
                Image(systemName: icon)
                    .font(.footnote)
                    .foregroundStyle(.white)
                    .frame(width: 30, height: 30)
                    .background(Color.accentColor, in: Circle())
                if !isLast {
                    Rectangle()
                        .fill(Color.accentColor.opacity(0.3))
                        .frame(width: 2)
                        .frame(maxHeight: .infinity)
                }
            }
            VStack(alignment: .leading, spacing: 2) {
                title
                    .font(.subheadline)
                    .fontWeight(.semibold)
                detail
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            .padding(.bottom, isLast ? 0 : 16)
        }
        .fixedSize(horizontal: false, vertical: true)
    }

    @ViewBuilder
    private var header: some View {
        if let trialDays {
            VStack(spacing: 16) {
                Text("Try ByJo Pro free")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)

                savingsBadge

                trialTimeline(days: trialDays)
            }
            .padding(.horizontal, 20)
        } else {
            VStack(spacing: 2) {
                Text("Your Finances,")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Text("Under Control.")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundStyle(Color.accentColor)

                savingsBadge
                    .padding(.top, 12)
            }
            .multilineTextAlignment(.center)
        }
    }
}

#Preview {
    PaywallView(store: Store())
}
