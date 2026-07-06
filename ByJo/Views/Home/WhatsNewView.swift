//
//  WhatsNewView.swift
//  ByJo
//
//  Created by Giuseppe Cosenza on 06/07/26.
//

import SwiftUI

private struct WhatsNewFeature {
    let icon: String
    let color: Color
    let title: String
    let description: String
}

private let features: [WhatsNewFeature] = [
    WhatsNewFeature(
        icon: "house.fill",
        color: .blue,
        title: "Home Redesign",
        description: "A completely refreshed home experience with a cleaner layout and better information hierarchy."
    ),
    WhatsNewFeature(
        icon: "square.grid.2x2.fill",
        color: .teal,
        title: "Home Widgets",
        description: "Customisable in-app widgets — net worth, asset allocation, top expenses, savings rate, and more."
    ),
    WhatsNewFeature(
        icon: "book.pages.fill",
        color: .orange,
        title: "Operations Redesigned",
        description: "Recurring operations are now more powerful and solid. Enjoy a better details view and richer swap information."
    ),
    WhatsNewFeature(
        icon: "mic.fill",
        color: .purple,
        title: "App Intents",
        description: "Add operations and swaps directly via Siri and the Shortcuts app — no need to open ByJo."
    ),
    WhatsNewFeature(
        icon: "rectangle.stack.fill",
        color: .green,
        title: "Widgets",
        description: "New home screen and lock screen widgets let you track net worth, savings rate, and more at a glance."
    )
]

struct WhatsNewView: View {
    var onDismiss: () -> Void

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    header
                    featureList
                }
            }
            .toolbar {
                ToolbarItem(placement: .bottomBar) {
                    Button(action: onDismiss) {
                        Text("Continue")
                            .font(.headline)
                            .foregroundStyle(.white)
                    }
                    .buttonStyle(.borderedProminent)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                }
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(.tint.opacity(0.15))
                    .frame(width: 96, height: 96)

                Image(systemName: "sparkles")
                    .font(.system(size: 44, weight: .semibold))
                    .foregroundStyle(.tint)
            }
            .padding(.top)

            Text("What's New in ByJo")
                .font(.largeTitle.bold())
                .multilineTextAlignment(.center)

            Text("Here's everything that's new and improved.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 32)
        .padding(.bottom, 36)
    }

    // MARK: - Features

    private var featureList: some View {
        VStack(spacing: 28) {
            ForEach(features, id: \.title) { feature in
                FeatureRow(feature: feature)
            }
        }
        .padding(.horizontal, 28)
        .padding(.bottom, 28)
    }
}

// MARK: - Feature Row

private struct FeatureRow: View {
    let feature: WhatsNewFeature

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: feature.icon)
                .font(.title2.weight(.semibold))
                .foregroundStyle(.white)
                .frame(width: 56, height: 56)
                .background(
                    feature.color.gradient,
                    in: RoundedRectangle(cornerRadius: 14, style: .continuous)
                )

            VStack(alignment: .leading, spacing: 4) {
                Text(feature.title)
                    .font(.headline)

                Text(feature.description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
    }
}

#Preview {
    WhatsNewView(onDismiss: {})
}
