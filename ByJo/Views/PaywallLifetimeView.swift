//
//  PaywallLifetimeView.swift
//  ByJo
//
//  Created by Giuseppe Cosenza on 28/07/25.
//

import StoreKit
import SwiftUI

struct PaywallLifetimeView: View {
    @Environment(\.dismiss) private var dismiss
    var store: Store

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 8) {
                Image(systemName: "infinity.circle.fill")
                    .font(.system(size: 44))
                    .foregroundStyle(.green)

                Text("Lifetime Access")
                    .font(.title2)
                    .fontWeight(.bold)

                Text("Pay once. No renewals, no limits. Yours forever.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            .padding(.top, 28)
            .padding(.bottom, 8)

            StoreView(ids: store.productLifetimeIds) { _ in
                Image("paywall-lifetime")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 60, height: 60)
                    .clipShape(.rect(cornerRadius: 12))
            }
            .padding(.vertical)
            .padding(.horizontal, 8)
            .productViewStyle(.compact)
            .storeButton(.visible, for: .restorePurchases)
            .storeButton(.hidden, for: .cancellation)
            .onChange(of: store.purchasedProducts) { _, products in
                if !products.isEmpty { dismiss() }
            }
        }
        .presentationDragIndicator(.visible)
    }
}

#Preview {
    PaywallLifetimeView(store: Store())
}
