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
        icon: "arrow.triangle.2.circlepath",
        color: .purple,
        title: "Update Asset Value",
        description: "Set an asset to its real value — ByJo records the adjustment as an operation with an optional note."
    ),
    WhatsNewFeature(
        icon: "chart.xyaxis.line",
        color: .green,
        title: "Balance History",
        description: "See how an asset’s value changed over time with a chart on the asset detail screen."
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
