//
//  GoalRowView.swift
//  ByJo
//
//  Created by Giuseppe Cosenza on 23/11/24.
//

import SwiftData
import SwiftUI

struct GoalRowView: View {
    @AppStorage("currencyCode") var currency: CurrencyCode = .usd
    @AppStorage("compactNumber") var compactNumber: Bool = true

    var goal: Goal
    var asset: Asset

    var progress: Double {
        let current  = NSDecimalNumber(decimal: asset.calculateCurrentBalance()).doubleValue
        let target   = NSDecimalNumber(decimal: goal.targetAmount).doubleValue
        let starting = NSDecimalNumber(decimal: goal.startingAmount).doubleValue
        let range    = target - starting
        guard range > 0 else { return current >= target ? 1.0 : 0.0 }
        return max(0, min((current - starting) / range, 1.0))
    }

    var remaining: Decimal {
        max(0, goal.targetAmount - asset.calculateCurrentBalance())
    }

    var progressPercent: Int {
        Int((progress * 100).rounded())
    }

    var daysLeft: Int? {
        guard let due = goal.dueDate, !goal.isExpired else { return nil }
        return Calendar.current.dateComponents([.day], from: .now, to: due).day
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack(spacing: 6) {
                Text(asset.name)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)

                if goal.isExpired {
                    Text("Expired")
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 2)
                        .background(Color.red, in: Capsule())
                } else if let days = daysLeft, days <= 7 {
                    Text(days == 0 ? "Today" : "\(days)d left")
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 2)
                        .background(Color.orange, in: Capsule())
                }
            }

            Text(goal.title)
                .font(.title2)
                .fontWeight(.semibold)
                .lineLimit(2)

            // Hero number
            if goal.isExpired {
                Label("Expired", systemImage: "clock.badge.xmark")
                    .font(.subheadline)
                    .foregroundStyle(.red)
            } else if remaining > 0 {
                HStack(alignment: .lastTextBaseline, spacing: 6) {
                    Text(remaining, format: compactNumber
                         ? .currency(code: currency.rawValue).notation(.compactName)
                         : .currency(code: currency.rawValue))
                        .font(.title)
                        .fontWeight(.bold)
                        .contentTransition(.numericText(value: Double(truncating: remaining as NSDecimalNumber)))

                    Text("left to go")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } else {
                Label("Goal reached!", systemImage: "checkmark.circle.fill")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundStyle(.green)
            }

            // Progress bar
            ProgressView(value: progress)
                .tint(goal.isExpired ? .red : (remaining == 0 ? .green : .accentColor))

            // Footer: from · % · to + due date
            HStack(spacing: 3) {
                Text(goal.startingAmount, format: compactNumber
                     ? .currency(code: currency.rawValue).notation(.compactName)
                     : .currency(code: currency.rawValue))
                    .foregroundStyle(.secondary)

                Text("·")
                    .foregroundStyle(Color.secondary.opacity(0.4))

                Text("\(progressPercent)%")
                    .fontWeight(.semibold)

                Text("·")
                    .foregroundStyle(Color.secondary.opacity(0.4))

                Text(goal.targetAmount, format: compactNumber
                     ? .currency(code: currency.rawValue).notation(.compactName)
                     : .currency(code: currency.rawValue))
                    .foregroundStyle(.secondary)

                Spacer()

                if let dueDate = goal.dueDate {
                    HStack(spacing: 3) {
                        Image(systemName: "calendar")
                        Text(dueDate, format: .dateTime.month(.abbreviated).year())
                    }
                    .foregroundStyle(.secondary)
                }
            }
            .font(.caption)
        }
    }
}

#Preview {
    GoalRowView(
        goal: Goal(title: "Buy the brand new iPhone 17", startingAmount: 100.0, targetAmount: 999.99, dueDate: .now),
        asset: Asset(name: "BuddyBank", initialBalance: 100.0)
    )
}
