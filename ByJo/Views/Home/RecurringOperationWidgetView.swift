//
//  RecurringOperationWidgetView.swift
//  ByJo
//
//  Created by Giuseppe Cosenza on 09/08/25.
//

import SwiftData
import SwiftUI

struct RecurringOperationWidgetView: View {
    @Environment(\.modelContext) var modelContext
    @AppStorage("currencyCode") var currencyCode: CurrencyCode = .usd
    @AppStorage("compactNumber") var compactNumber: Bool = true

    @Query(sort: \AssetOperation.date, order: .reverse) var operations: [AssetOperation]

    @State private var toAddOperations: [AssetOperation] = []
    @State private var showPreviewSheet = false

    var body: some View {
        if let recurringOperation = operations.first(where: { $0.frequency != .single }) {
            Section {
                VStack(alignment: .leading, spacing: 24) {
                    NavigationLink {
                        RecurringOperationListView()
                    } label: {
                        Text("Recurring operation")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                    }

                    VStack(alignment: .leading) {
                        Text(recurringOperation.name)
                            .font(.title3)
                            .fontWeight(.semibold)
                            .lineLimit(1)

                        HStack(alignment: .lastTextBaseline) {
                            HStack(spacing: 4) {
                                Group {
                                    if recurringOperation.amount > 0 {
                                        Image(systemName: "arrow.up.circle.fill")
                                            .foregroundStyle(.green)
                                    } else if recurringOperation.amount == 0 {
                                        Image(systemName: "equal.circle.fill")
                                            .foregroundStyle(.gray)
                                    } else {
                                        Image(systemName: "arrow.down.circle.fill")
                                            .foregroundStyle(.red)
                                    }
                                }
                                .imageScale(.large)
                                .fontWeight(.semibold)

                                Text(abs(recurringOperation.amount), format: compactNumber ? .currency(code: currencyCode.rawValue).notation(.compactName) : .currency(code: currencyCode.rawValue))
                                    .font(.title)
                                    .fontWeight(.semibold)
                                    .contentTransition(.numericText(value: compactNumber ? 0 : 1))
                            }

                            Spacer()

                            if let nextPaymentDate = recurringOperation.frequency.nextPaymentDate(from: recurringOperation.date) {
                                Text(nextPaymentDate, format: .dateTime.day().month(.abbreviated).year(.twoDigits).hour().minute())
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
            .onAppear {
                processRecurringOperations()
            }
            .sheet(isPresented: $showPreviewSheet) {
                RecurringOperationsPreviewSheet(operations: toAddOperations) {
                    insertPendingOperations()
                }
            }
        }
    }

    // Assigns a shared seriesId to legacy recurring operations that predate V2,
    // grouping them by name + asset + frequency so they form a proper series.
    private func repairLegacySeriesIds() {
        let legacy = operations.filter { $0.frequency != .single && $0.seriesId == nil }
        guard !legacy.isEmpty else { return }

        var groups: [String: UUID] = [:]
        for op in legacy {
            let key = "\(op.name)|\(op.asset?.id.uuidString ?? "nil")|\(op.frequency.rawValue)"
            if let existingId = groups[key] {
                op.seriesId = existingId
            } else {
                let newId = UUID()
                groups[key] = newId
                op.seriesId = newId
            }
        }
    }

    private func processRecurringOperations() {
        repairLegacySeriesIds()
        toAddOperations.removeAll()

        let calendar = Calendar.current
        let recurringOperations = operations.filter { $0.frequency != .single }

        for operation in recurringOperations {
            guard let category = operation.category, let seriesId = operation.seriesId else { continue }

            var nextDate = operation.frequency.nextPaymentDate(from: operation.date)

            while let dueDate = nextDate, dueDate <= Date() {
                let dueDateDay = calendar.startOfDay(for: dueDate)

                let alreadyExists = operations.contains {
                    $0.seriesId == seriesId &&
                    calendar.startOfDay(for: $0.date) == dueDateDay
                }

                let alreadyQueued = toAddOperations.contains {
                    $0.seriesId == seriesId &&
                    calendar.startOfDay(for: $0.date) == dueDateDay
                }

                if !alreadyExists && !alreadyQueued {
                    toAddOperations.append(AssetOperation(
                        name: operation.name,
                        date: dueDate,
                        amount: operation.amount,
                        asset: operation.asset,
                        category: category,
                        note: operation.note,
                        frequency: operation.frequency,
                        seriesId: seriesId
                    ))
                }

                nextDate = operation.frequency.nextPaymentDate(from: dueDate)
            }
        }

        if !toAddOperations.isEmpty {
            showPreviewSheet = true
        }
    }

    private func insertPendingOperations() {
        var latestPerSeries: [UUID: AssetOperation] = [:]

        for operation in toAddOperations {
            modelContext.insert(operation)
            if let seriesId = operation.seriesId {
                let current = latestPerSeries[seriesId]
                if current == nil || operation.date > current!.date {
                    latestPerSeries[seriesId] = operation
                }
            }
        }

        // Refresh the notification window for each affected series
        for (seriesId, latest) in latestPerSeries {
            scheduleRecurringNotifications(
                seriesId: seriesId,
                name: latest.name,
                amount: latest.amount,
                startingFrom: latest.date,
                frequency: latest.frequency,
                currencyCode: currencyCode
            )
        }

        toAddOperations.removeAll()
    }
}

private struct RecurringOperationsPreviewSheet: View {
    @Environment(\.dismiss) var dismiss
    @AppStorage("currencyCode") var currencyCode: CurrencyCode = .usd
    @AppStorage("compactNumber") var compactNumber: Bool = true

    let operations: [AssetOperation]
    let onConfirm: () -> Void

    var body: some View {
        NavigationStack {
            List {
                ForEach(operations) { operation in
                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(operation.name)
                                .font(.body)
                                .fontWeight(.semibold)

                            HStack(spacing: 6) {
                                if let assetName = operation.asset?.name {
                                    Text(assetName)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)

                                    Text("·")
                                        .font(.caption)
                                        .foregroundStyle(.tertiary)
                                }

                                Text(operation.date, format: .dateTime.day().month(.abbreviated).year())
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }

                        Spacer()

                        Text(operation.amount, format: compactNumber ? .currency(code: currencyCode.rawValue).notation(.compactName) : .currency(code: currencyCode.rawValue))
                            .font(.body)
                            .fontWeight(.semibold)
                            .foregroundStyle(operation.amount >= 0 ? .green : .red)
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("\(operations.count) pending \(operations.count == 1 ? "operation" : "operations")")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add All") {
                        onConfirm()
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
}

#Preview {
    RecurringOperationWidgetView()
}
