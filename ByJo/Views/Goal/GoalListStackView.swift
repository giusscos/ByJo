//
//  GoalListStackView.swift
//  ByJo
//
//  Created by Giuseppe Cosenza on 02/08/25.
//

import SwiftData
import SwiftUI

struct GoalListStackView: View {
    @AppStorage("pinnedGoalId") private var pinnedGoalId: String = ""

    @Query(filter: #Predicate<Goal> { goal in
        goal.completedDate == nil
    }, sort: \Goal.dueDate, order: .reverse) var goals: [Goal]

    private var featuredGoal: Goal? {
        if !pinnedGoalId.isEmpty,
           let pinned = goals.first(where: { $0.id.uuidString == pinnedGoalId }) {
            return pinned
        }
        // Nearest due date first, then goals without due date by first created
        return goals.sorted { lhs, rhs in
            switch (lhs.dueDate, rhs.dueDate) {
            case (let l?, let r?): return l < r
            case (nil, _?):        return false
            case (_?, nil):        return true
            case (nil, nil):       return false
            }
        }.first
    }

    var body: some View {
        if !goals.isEmpty {
            Section {
                NavigationLink {
                    GoalListView()
                } label: {
                    HStack {
                        Text("Goals")
                            .font(.headline)
                        Spacer()
                        Text("\(goals.count) active")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }

                if let goal = featuredGoal, let asset = goal.asset {
                    NavigationLink {
                        GoalDetailView(goal: goal, asset: asset)
                    } label: {
                        GoalHomeSummary(goal: goal, asset: asset)
                    }
                }
            }
        }
    }
}

private struct GoalHomeSummary: View {
    @AppStorage("currencyCode") var currency: CurrencyCode = .usd
    @AppStorage("compactNumber") var compactNumber: Bool = true

    var goal: Goal
    var asset: Asset

    var remaining: Decimal {
        max(0, goal.targetAmount - asset.calculateCurrentBalance())
    }

    var progress: Double {
        let current  = NSDecimalNumber(decimal: asset.calculateCurrentBalance()).doubleValue
        let target   = NSDecimalNumber(decimal: goal.targetAmount).doubleValue
        let starting = NSDecimalNumber(decimal: goal.startingAmount).doubleValue
        let range    = target - starting
        guard range > 0 else { return current >= target ? 1.0 : 0.0 }
        return max(0, min((current - starting) / range, 1.0))
    }

    var progressPercent: Int { Int((progress * 100).rounded()) }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                Text(goal.title)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                if goal.isExpired {
                    Label("Expired", systemImage: "clock.badge.xmark")
                        .font(.subheadline)
                        .foregroundStyle(.red)
                } else if remaining > 0 {
                    HStack(alignment: .firstTextBaseline, spacing: 6) {
                        Text(remaining, format: compactNumber
                             ? .currency(code: currency.rawValue).notation(.compactName)
                             : .currency(code: currency.rawValue))
                            .font(.system(size: 34, weight: .black, design: .rounded))
                            .foregroundStyle(.primary)
                            .contentTransition(.numericText(value: Double(truncating: remaining as NSDecimalNumber)))

                        Text("left to go")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                } else {
                    Label("Goal reached!", systemImage: "checkmark.circle.fill")
                        .font(.headline)
                        .foregroundStyle(.green)
                }
            }

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

                if let dueDate = goal.dueDate {
                    Text("·")
                        .foregroundStyle(Color.secondary.opacity(0.4))
                    Text(dueDate, format: .dateTime.month(.abbreviated).year())
                        .foregroundStyle(.secondary)
                }
            }
            .font(.caption)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    GoalListStackView()
}
