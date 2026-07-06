//
//  AssetAllocationWidgetView.swift
//  ByJo
//

import Charts
import SwiftData
import SwiftUI

private struct AssetSlice: Identifiable {
    let id = UUID()
    let label: String
    let value: Double
    let color: Color
}

struct AssetAllocationWidgetView: View {
    @AppStorage("currencyCode") var currencyCode: CurrencyCode = .usd
    @AppStorage("compactNumber") var compactNumber: Bool = true

    @Query var assets: [Asset]

    private let palette: [Color] = [.blue, .green, .orange, .purple, .cyan, .pink, .yellow, .indigo]

    private var slices: [AssetSlice] {
        let positiveAssets = assets.filter {
            NSDecimalNumber(decimal: $0.calculateCurrentBalance()).doubleValue > 0
        }
        guard !positiveAssets.isEmpty else { return [] }

        let total = positiveAssets.reduce(0.0) {
            $0 + NSDecimalNumber(decimal: $1.calculateCurrentBalance()).doubleValue
        }
        guard total > 0 else { return [] }

        return positiveAssets
            .enumerated()
            .map { index, asset in
                let value = NSDecimalNumber(decimal: asset.calculateCurrentBalance()).doubleValue
                return AssetSlice(
                    label: asset.name,
                    value: value / total * 100,
                    color: palette[index % palette.count]
                )
            }
            .sorted { $0.value > $1.value }
    }

    var body: some View {
        if !slices.isEmpty {
            Section {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Asset allocation")
                        .font(.headline)
                        .foregroundStyle(.secondary)

                    HStack(alignment: .center, spacing: 24) {
                        Chart(slices) { slice in
                            SectorMark(
                                angle: .value("Value", slice.value),
                                innerRadius: .ratio(0.55),
                                angularInset: 2
                            )
                            .foregroundStyle(slice.color)
                            .cornerRadius(4)
                        }
                        .frame(width: 110, height: 110)

                        VStack(alignment: .leading, spacing: 10) {
                            ForEach(slices.prefix(5)) { slice in
                                HStack(spacing: 8) {
                                    Circle()
                                        .fill(slice.color)
                                        .frame(width: 8, height: 8)

                                    Text(slice.label)
                                        .font(.caption)
                                        .lineLimit(1)

                                    Spacer()

                                    Text(String(format: "%.0f%%", slice.value))
                                        .font(.caption)
                                        .fontWeight(.semibold)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                }
                .padding(.vertical, 8)
            }
        }
    }
}

#Preview {
    AssetAllocationWidgetView()
}
