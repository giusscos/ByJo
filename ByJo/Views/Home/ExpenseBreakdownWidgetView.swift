//
//  ExpenseBreakdownWidgetView.swift
//  ByJo
//

import Charts
import SwiftData
import SwiftUI

private struct CategorySlice: Identifiable {
    let id = UUID()
    let label: String
    let value: Double
    let amount: Decimal
    let color: Color
}

struct ExpenseBreakdownWidgetView: View {
    @AppStorage("currencyCode") var currencyCode: CurrencyCode = .usd
    @AppStorage("compactNumber") var compactNumber: Bool = true

    @Query var assets: [Asset]

    @State private var selectedRange: DateRangeOption = .month

    private let rangeOptions: [DateRangeOption] = [.month, .threeMonths, .sixMonths, .year, .all]
    private let palette: [Color] = [.red, .orange, .pink, .purple, .indigo, .blue, .green, .cyan]

    private var slices: [CategorySlice] {
        let range = selectedRange.dateRange
        let expenses = assets.flatMap { $0.operations ?? [] }
            .filter { $0.amount < 0 && $0.date >= range.startDate && $0.date <= range.endDate }

        guard !expenses.isEmpty else { return [] }

        var byCategory: [String: (label: String, total: Decimal)] = [:]
        for op in expenses {
            let key = op.category?.name ?? "Other"
            let existing = byCategory[key] ?? (label: key, total: 0)
            byCategory[key] = (label: existing.label, total: existing.total + op.amount)
        }

        let total = byCategory.values.reduce(0.0) { $0 + abs(NSDecimalNumber(decimal: $1.total).doubleValue) }
        guard total > 0 else { return [] }

        return byCategory.values
            .enumerated()
            .map { index, entry in
                let value = abs(NSDecimalNumber(decimal: entry.total).doubleValue)
                return CategorySlice(
                    label: entry.label,
                    value: value / total * 100,
                    amount: abs(entry.total),
                    color: palette[index % palette.count]
                )
            }
            .sorted { $0.value > $1.value }
    }

    var body: some View {
        if !slices.isEmpty {
            Section {
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Text("Expense breakdown")
                            .font(.headline)
                            .foregroundStyle(.secondary)

                        Spacer()

                        Picker("", selection: $selectedRange) {
                            ForEach(rangeOptions, id: \.self) { option in
                                Text(option.label).tag(option)
                            }
                        }
                        .labelsHidden()
                        .pickerStyle(.menu)
                    }

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

                                    Text(slice.amount, format: compactNumber
                                         ? .currency(code: currencyCode.rawValue).notation(.compactName)
                                         : .currency(code: currencyCode.rawValue))
                                        .font(.caption)
                                        .fontWeight(.semibold)
                                        .foregroundStyle(.secondary)
                                        .contentTransition(.numericText(value: compactNumber ? 0 : 1))
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
    ExpenseBreakdownWidgetView()
}
