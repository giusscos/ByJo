//
//  PaywallView.swift
//  ByJo
//
//  Created by Giuseppe Cosenza on 28/07/25.
//

import StoreKit
import SwiftUI

/// ByJo Pro plans, shown when a free user reaches a Pro feature or opens
/// "Upgrade to ByJo Pro". Always closable: the free plan keeps working.
struct PaywallView: View {
    /// What brought the user here; sets the headline.
    enum Context {
        case upgrade
        case assetLimit
        case goals
        case recurring
        case importExport
        case charts
        case customizeHome
    }

    var store: Store
    var context: Context = .upgrade
    /// Closes the sheet once Pro unlocks. Off when the paywall stands in for an editor
    /// that should appear in its place after the purchase.
    var dismissOnUnlock: Bool = true

    @Environment(\.dismiss) private var dismiss
    @State private var selectedPlanID: String = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    header

                    if store.isLoading && store.yearlyProduct == nil {
                        ProgressView()
                            .padding()
                    } else if store.yearlyProduct == nil && store.weeklyProduct == nil && store.lifetimeProduct == nil {
                        Text("Plans are unavailable right now. Check your connection and try again.")
                            .font(.callout)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    } else {
                        PlanPicker(store: store, selectedID: $selectedPlanID)
                    }

                    ProFeatureList()
                        .padding(16)
                        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 16))
                }
                .padding(20)
            }
            .safeAreaInset(edge: .bottom, spacing: 0) {
                VStack(spacing: 12) {
                    PlanPurchaseButton(store: store, selectedID: selectedPlanID)
                    PaywallLegalFooter(store: store)
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 8)
                .background { BottomBarFade() }
            }
            .navigationTitle("ByJo Pro")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
            .onAppear {
                if selectedPlanID.isEmpty { selectedPlanID = store.yearlyProductId }
            }
            .onChange(of: store.isPro) { _, isPro in
                if isPro && dismissOnUnlock { dismiss() }
            }
        }
    }

    private var header: some View {
        VStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 40, weight: .semibold))
                .foregroundStyle(Color.accentColor)
                .frame(width: 80, height: 80)
                .background(Color.accentColor.opacity(0.12), in: Circle())

            Text(headline)
                .font(.title2.bold())
                .multilineTextAlignment(.center)

            Text(subheadline)
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }

    private var icon: String {
        switch context {
        case .upgrade: "star.fill"
        case .assetLimit: "infinity"
        case .goals: "target"
        case .recurring: "repeat"
        case .importExport: "arrow.up.arrow.down.square.fill"
        case .charts: "chart.line.uptrend.xyaxis"
        case .customizeHome: "slider.horizontal.3"
        }
    }

    private var headline: LocalizedStringKey {
        switch context {
        case .upgrade: "Unlock ByJo Pro"
        case .assetLimit: "Track Every Account"
        case .goals: "Set Goals with Pro"
        case .recurring: "Recurring Operations with Pro"
        case .importExport: "Export & Import with Pro"
        case .charts: "See the Whole Picture"
        case .customizeHome: "Make Home Yours"
        }
    }

    private var subheadline: LocalizedStringKey {
        switch context {
        case .upgrade:
            "Your whole financial picture, private and in one place."
        case .assetLimit:
            "The free plan covers \(Store.freeAssetLimit) assets. Pro adds as many as you need."
        case .goals:
            "Give any asset a target and a date, and watch your progress."
        case .recurring:
            "Schedule bills and income, and get a reminder before each one."
        case .importExport:
            "Bring your data in from a spreadsheet, or take it with you anytime."
        case .charts:
            "Net worth history, spending trends, asset allocation and more, right on Home."
        case .customizeHome:
            "Reorder and hide Home sections to match how you think about money."
        }
    }
}

#Preview {
    PaywallView(store: Store())
}
