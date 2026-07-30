//
//  WalletShortcutBannerView.swift
//  ByJo
//

import SwiftUI

struct WalletShortcutBannerView: View {
    var onTap: () -> Void

    var body: some View {
        Section {
            Button(action: onTap) {
                HStack(alignment: .center, spacing: 14) {
                    Image(systemName: "wallet.pass.fill")
                        .font(.title2)
                        .foregroundStyle(.tint)
                        .frame(width: 36, height: 36)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Auto-log taps")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundStyle(.primary)

                        Text("Set up Shortcuts to log merchant and amount automatically.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Spacer(minLength: 0)

                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.tertiary)
                }
                .padding(.vertical, 8)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
    }
}

#Preview {
    List {
        WalletShortcutBannerView(onTap: {})
    }
}
