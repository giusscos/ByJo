//
//  ProLockedCard.swift
//  ByJo
//

import SwiftUI

/// Shows a Home card blurred behind a lock with its title, as a preview of a Pro feature.
/// Tapping it calls `onUnlock`, which opens the paywall.
private struct ProLockedCard: ViewModifier {
    let title: String
    let onUnlock: () -> Void

    func body(content: Content) -> some View {
        content
            .blur(radius: 7)
            .allowsHitTesting(false)
            .accessibilityHidden(true)
            .overlay {
                Button(action: onUnlock) {
                    VStack(spacing: 6) {
                        Label(title, systemImage: "lock.fill")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.primary)
                        Text(verbatim: "ByJo Pro")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(Color.accentColor, in: Capsule())
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(Text(title))
                .accessibilityHint(Text("Unlock ByJo Pro"))
            }
    }
}

extension View {
    /// Blurs a Home card and turns it into a button that opens the paywall.
    func proLockedCard(title: String, onUnlock: @escaping () -> Void) -> some View {
        modifier(ProLockedCard(title: title, onUnlock: onUnlock))
    }
}
