//
//  GoalDetailView.swift
//  ByJo
//

import SwiftData
import SwiftUI

struct GoalDetailView: View {
    @Environment(\.modelContext) var modelContext
    @Environment(\.dismiss) var dismiss

    @AppStorage("currencyCode") var currency: CurrencyCode = .usd
    @AppStorage("compactNumber") var compactNumber: Bool = true
    @AppStorage("pinnedGoalId") var pinnedGoalId: String = ""

    var goal: Goal
    var asset: Asset

    @State private var showEdit = false

    // MARK: - Progress

    var currentBalance: Decimal { asset.calculateCurrentBalance() }

    var remaining: Decimal { max(0, goal.targetAmount - currentBalance) }

    var netProgress: Decimal { currentBalance - goal.startingAmount }

    var progress: Double {
        let current  = NSDecimalNumber(decimal: currentBalance).doubleValue
        let target   = NSDecimalNumber(decimal: goal.targetAmount).doubleValue
        let starting = NSDecimalNumber(decimal: goal.startingAmount).doubleValue
        let range    = target - starting
        guard range > 0 else { return current >= target ? 1.0 : 0.0 }
        return max(0, min((current - starting) / range, 1.0))
    }

    var progressPercent: Int { Int((progress * 100).rounded()) }

    var isPinned: Bool { pinnedGoalId == goal.id.uuidString }

    // MARK: - Pace (last 90 days net change on the asset)

    var monthlyPace: Decimal? {
        let ops = asset.operations ?? []
        let cutoff = Calendar.current.date(byAdding: .day, value: -90, to: .now) ?? .now
        let recent = ops.filter { $0.date >= cutoff && $0.date <= .now }
        guard !recent.isEmpty else { return nil }
        let total = recent.reduce(Decimal(0)) { $0 + $1.amount }
        return total / 3
    }

    var estimatedCompletionDate: Date? {
        guard let pace = monthlyPace, pace > 0, remaining > 0 else { return nil }
        let months = NSDecimalNumber(decimal: remaining / pace).doubleValue
        return Calendar.current.date(byAdding: .day, value: Int(months * 30.44), to: .now)
    }

    // MARK: - Required savings to meet due date

    var daysUntilDue: Int? {
        guard let due = goal.dueDate else { return nil }
        let d = Calendar.current.dateComponents([.day], from: .now, to: due).day ?? 0
        return d > 0 ? d : nil
    }

    var requiredMonthly: Decimal? {
        guard let days = daysUntilDue, remaining > 0 else { return nil }
        let months = Decimal(days) / 30
        return remaining / months
    }

    var requiredWeekly: Decimal? {
        guard let days = daysUntilDue, remaining > 0 else { return nil }
        let weeks = Decimal(days) / 7
        return remaining / weeks
    }

    var requiredDaily: Decimal? {
        guard let days = daysUntilDue, remaining > 0 else { return nil }
        return remaining / Decimal(days)
    }

    // MARK: - Body

    var body: some View {
        List {
            // MARK: Progress
            Section {
                // Circular progress ring
                VStack(spacing: 20) {
                    ZStack {
                        Circle()
                            .stroke(Color.accentColor.opacity(0.12), lineWidth: 18)
                            .frame(width: 160, height: 160)

                        Circle()
                            .trim(from: 0, to: CGFloat(progress))
                            .stroke(
                                LinearGradient(
                                    colors: progress >= 1 ? [.green, .mint] : [.accentColor, .purple],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                style: StrokeStyle(lineWidth: 18, lineCap: .round)
                            )
                            .frame(width: 160, height: 160)
                            .rotationEffect(.degrees(-90))
                            .animation(.spring(duration: 1.2, bounce: 0.2), value: progress)

                        VStack(spacing: 2) {
                            Text("\(progressPercent)%")
                                .font(.system(size: 44, weight: .black, design: .rounded))
                                .foregroundStyle(progress >= 1 ? .green : .primary)
                                .contentTransition(.numericText())
                            Text(asset.name)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                    }

                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Started")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(goal.startingAmount, format: .currency(code: currency.rawValue))
                                .font(.headline)
                                .fontWeight(.bold)
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("Target")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(goal.targetAmount, format: .currency(code: currency.rawValue))
                                .font(.headline)
                                .fontWeight(.bold)
                        }
                    }
                }
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity)

                // Stat rows
                if remaining > 0 {
                    HStack {
                        Label("Remaining", systemImage: "target")
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(remaining, format: .currency(code: currency.rawValue))
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(goal.isExpired ? .red : .primary)
                    }

                    HStack {
                        Label("Saved so far", systemImage: "arrow.up.circle")
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(netProgress, format: .currency(code: currency.rawValue))
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(netProgress >= 0 ? .green : .red)
                    }
                } else {
                    HStack {
                        Label("Goal reached!", systemImage: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                        Spacer()
                        Text(currentBalance, format: .currency(code: currency.rawValue))
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(.secondary)
                    }
                }

                if let dueDate = goal.dueDate {
                    HStack {
                        Label("Due date", systemImage: "calendar")
                            .foregroundStyle(.secondary)
                        Spacer()
                        if goal.isExpired {
                            Text("Expired")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundStyle(.white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 5)
                                .background(Color.red)
                                .clipShape(Capsule())
                        } else {
                            Text(dueDate, format: .dateTime.day().month(.wide).year())
                                .font(.subheadline)
                                .fontWeight(.semibold)
                        }
                    }
                }
            } header: {
                Text("Progress")
            }

            // MARK: Projections
            if let pace = monthlyPace {
                Section {
                    HStack {
                        Label("Monthly pace", systemImage: "chart.line.uptrend.xyaxis")
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(pace, format: .currency(code: currency.rawValue))
                            .fontWeight(.semibold)
                            .foregroundStyle(pace > 0 ? Color.primary : Color.red)
                    }

                    if pace > 0 && remaining > 0 {
                        if let eta = estimatedCompletionDate {
                            HStack {
                                Label("Estimated completion", systemImage: "flag.checkered")
                                    .foregroundStyle(.secondary)
                                Spacer()
                                Text(eta, format: .dateTime.month(.wide).year())
                                    .fontWeight(.semibold)
                            }
                        }

                        if let due = goal.dueDate, let eta = estimatedCompletionDate {
                            let onTrack = eta <= due
                            HStack {
                                Label(onTrack ? "On track" : "Behind schedule", systemImage: onTrack ? "checkmark.seal.fill" : "exclamationmark.triangle.fill")
                                    .foregroundStyle(onTrack ? Color.green : Color.orange)
                                Spacer()
                                if !onTrack {
                                    Text("Need more savings")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    } else if pace <= 0 && remaining > 0 {
                        Label("Balance not growing — add income to this asset", systemImage: "exclamationmark.triangle.fill")
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }
                } header: {
                    Text("Projections")
                } footer: {
                    Text("Based on your last 90 days of activity on \(asset.name).")
                }
            }

            // MARK: Required savings
            if goal.dueDate != nil && remaining > 0 {
                Section {
                    if let daily = requiredDaily {
                        HStack {
                            Label("Per day", systemImage: "sun.max")
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text(daily, format: compactNumber
                                 ? .currency(code: currency.rawValue).notation(.compactName)
                                 : .currency(code: currency.rawValue))
                                .fontWeight(.semibold)
                        }
                    }

                    if let weekly = requiredWeekly {
                        HStack {
                            Label("Per week", systemImage: "calendar.badge.clock")
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text(weekly, format: compactNumber
                                 ? .currency(code: currency.rawValue).notation(.compactName)
                                 : .currency(code: currency.rawValue))
                                .fontWeight(.semibold)
                        }
                    }

                    if let monthly = requiredMonthly {
                        HStack {
                            Label("Per month", systemImage: "calendar")
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text(monthly, format: compactNumber
                                 ? .currency(code: currency.rawValue).notation(.compactName)
                                 : .currency(code: currency.rawValue))
                                .fontWeight(.semibold)
                        }
                    }
                } header: {
                    Text("Required savings")
                } footer: {
                    if let days = daysUntilDue {
                        Text("To reach your target in \(days) days.")
                    }
                }
            }

            // MARK: Manage
            Section("Manage") {
                Button {
                    withAnimation {
                        pinnedGoalId = isPinned ? "" : goal.id.uuidString
                    }
                } label: {
                    Label(isPinned ? "Unpin from home" : "Pin to home", systemImage: isPinned ? "pin.slash" : "pin")
                }

                if goal.isCompleted {
                    Button {
                        resumeGoal()
                    } label: {
                        Label("Resume", systemImage: "arrow.clockwise.circle")
                    }
                } else {
                    Button {
                        setStatus(.suspended)
                    } label: {
                        Label("Suspend", systemImage: "inset.filled.circle.dashed")
                    }
                }
            }
        }
        .navigationTitle(goal.title)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showEdit = true
                } label: {
                    Label("Edit", systemImage: "pencil")
                }
            }
            
            if !goal.isCompleted {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        setStatus(.completed)
                    } label: {
                        Label("Mark as completed", systemImage: "inset.filled.circle")
                    }
                    .buttonStyle(.borderedProminent)
                    .buttonBorderShape(.circle)
                }
            }
        }
        .sheet(isPresented: $showEdit) {
            EditGoalView(goal: goal, asset: asset)
        }
    }

    private func setStatus(_ status: StatusGoal) {
        withAnimation {
            goal.completedDate = .now
            goal.completedStatus = status
        }
        dismiss()
    }

    private func resumeGoal() {
        withAnimation {
            goal.completedDate = nil
            goal.completedStatus = nil
        }
    }
}

#Preview {
    NavigationStack {
        GoalDetailView(
            goal: Goal(title: "New Dad Phone", startingAmount: 200, targetAmount: 700, dueDate: Calendar.current.date(byAdding: .month, value: 6, to: .now)),
            asset: Asset(name: "BuddyBank", initialBalance: 200)
        )
    }
}
