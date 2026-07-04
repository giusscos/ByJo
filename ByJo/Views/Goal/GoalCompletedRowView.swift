//
//  GoalCompletedRowView.swift
//  ByJo
//
//  Created by Giuseppe Cosenza on 02/08/25.
//

import SwiftUI

struct GoalCompletedRowView: View {
    @AppStorage("currencyCode") var currency: CurrencyCode = .usd

    var goal: Goal

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    if let dueDate = goal.dueDate {
                        Group {
                            Text("Due date: ")
                            + Text(dueDate, format: .dateTime.day().month().year())
                        }
                        .foregroundStyle(.secondary)
                        .font(.caption)
                    }

                    if let completedDate = goal.completedDate {
                        Group {
                            Text("Completed date: ")
                            + Text(completedDate, format: .dateTime.day().month().year())
                        }
                        .foregroundStyle(.secondary)
                        .font(.caption)
                    }

                    Text(goal.title)
                        .font(.title)
                        .fontWeight(.semibold)
                        .lineLimit(3)
                }

                Spacer()

                Group {
                    if goal.completedStatus == .completed {
                        if let completedDate = goal.completedDate, let dueDate = goal.dueDate, completedDate <= dueDate {
                            Button("Reached") {
                                withAnimation {
                                    goal.completedStatus = .suspended
                                }
                            }
                            .tint(Color.accentColor)
                        } else {
                            Button("Missed") {}
                                .tint(.red)
                        }
                    } else {
                        Button("Suspended") {
                            withAnimation {
                                goal.completedStatus = .completed
                            }
                        }
                        .tint(.yellow)
                    }
                }
                .font(.caption)
                .buttonStyle(.bordered)
                .buttonBorderShape(.capsule)
            }

            if let asset = goal.asset {
                VStack {
                    HStack(alignment: .firstTextBaseline) {
                        VStack(alignment: .leading) {
                            Text("From")
                                .font(.caption)
                                .foregroundStyle(.secondary)

                            Text(goal.startingAmount, format: .currency(code: currency.rawValue))
                                .font(.headline)
                        }

                        Spacer()

                        Text(asset.name)
                            .font(.headline)

                        Spacer()

                        VStack(alignment: .trailing) {
                            Text("Target")
                                .font(.caption)
                                .foregroundStyle(.secondary)

                            Text(goal.targetAmount, format: .currency(code: currency.rawValue))
                                .font(.headline)
                        }
                    }
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(.rect(cornerRadius: 12))
        .shadow(color: .black.opacity(0.12), radius: 6, y: 4)
    }
}

#Preview {
    let goal = Goal(title: "Goal 1", startingAmount: 100.0, targetAmount: 200.0)
    goal.completedDate = Date()
    goal.completedStatus = .completed
    return GoalCompletedRowView(goal: goal)
}
