//
//  PaywallView.swift
//  ByJo
//
//  Created by Giuseppe Cosenza on 28/07/25.
//

import StoreKit
import SwiftUI

struct PaywallView: View {
    var store: Store
    @State private var showLifetimePlans: Bool = false

    private let features = [
        "Track every asset and account",
        "Set goals and watch them grow",
        "Never miss a scheduled payment",
        "Your full net worth, at a glance"
    ]

    var body: some View {
        NavigationStack {
            SubscriptionStoreView(groupID: store.groupId) {
                VStack(spacing: 24) {
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
                    .padding(.top, 36)

                    VStack(spacing: 2) {
                        Text("Your Finances,")
                            .font(.largeTitle)
                            .fontWeight(.bold)

                        Text("Under Control.")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundStyle(Color.accentColor)
                    }
                    .multilineTextAlignment(.center)

                    VStack(alignment: .leading, spacing: 14) {
                        ForEach(features, id: \.self) { feature in
                            Label {
                                Text(feature)
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
                        Link("Privacy", destination: URL(string: "https://giusscos.it/privacy")!)
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
        }
    }
}

#Preview {
    PaywallView(store: Store())
}
