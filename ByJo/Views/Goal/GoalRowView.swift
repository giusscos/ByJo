//
//  GoalRowView.swift
//  ByJo
//
//  Created by Giuseppe Cosenza on 23/11/24.
//

import SwiftData
import SwiftUI

struct GoalRowView: View {
    @Environment(\.modelContext) var modelContext

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

    @State private var showEditGoal: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
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
                        .font(.title3)
                        .fontWeight(.bold)
                        .lineLimit(2)
                }

                Spacer()

                Menu {
                    Button {
                        setStatusGoal(status: .completed)
                    } label: {
                        Label("Mark completed", systemImage: "inset.filled.circle")
                    }

                    Button {
                        setStatusGoal(status: .suspended)
                    } label: {
                        Label("Suspend", systemImage: "inset.filled.circle.dashed")
                    }

                    Divider()

                    Button {
                        showEditGoal = true
                    } label: {
                        Label("Edit", systemImage: "pencil")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle.fill")
                        .symbolRenderingMode(.hierarchical)
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer(minLength: 12)

            // Hero number
            if remaining > 0 {
                VStack(alignment: .leading, spacing: 2) {
                    Text(remaining, format: compactNumber
                         ? .currency(code: currency.rawValue).notation(.compactName)
                         : .currency(code: currency.rawValue))
                        .font(.system(size: 34, weight: .black, design: .rounded))
                        .foregroundStyle(goal.isExpired ? .red : .primary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)

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

            Spacer(minLength: 12)

            // Footer: from · % · to + due date
            HStack {
                HStack(spacing: 3) {
                    Text(goal.startingAmount, format: compactNumber
                         ? .currency(code: currency.rawValue).notation(.compactName)
                         : .currency(code: currency.rawValue))
                        .foregroundStyle(.secondary)

                    Text("·")
                        .foregroundStyle(Color.secondary.opacity(0.5))

                    Text("\(progressPercent)%")
                        .fontWeight(.semibold)

                    Text("·")
                        .foregroundStyle(Color.secondary.opacity(0.5))

                    Text(goal.targetAmount, format: compactNumber
                         ? .currency(code: currency.rawValue).notation(.compactName)
                         : .currency(code: currency.rawValue))
                        .foregroundStyle(.secondary)
                }
                .font(.caption)

                Spacer()

                if let dueDate = goal.dueDate {
                    HStack(spacing: 3) {
                        Image(systemName: "calendar")
                        Text(dueDate, format: .dateTime.month(.abbreviated).year())
                    }
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(.rect(cornerRadius: 16))
        .shadow(color: .black.opacity(0.1), radius: 8, y: 4)
        .sheet(isPresented: $showEditGoal) {
            EditGoalView(goal: goal, asset: asset)
        }
    }

    private func setStatusGoal(status: StatusGoal) {
        withAnimation {
            goal.completedDate = Date.now
            goal.completedStatus = status
        }
    }
}

#Preview {
    GoalRowView(
        goal: Goal(title: "Buy the brand new iPhone 17", startingAmount: 100.0, targetAmount: 999.99, dueDate: .now),
        asset: Asset(name: "BuddyBank", initialBalance: 100.0)
    )
}
