//
//  OperationDetailView.swift
//  ByJo
//
//  Created by Giuseppe Cosenza on 05/11/24.
//

import SwiftData
import SwiftUI
import Foundation

struct OperationDetailView: View {
    enum DeleteAction {
        case none
        case current
        case linked
        case both
    }

    @Environment(\.modelContext) var modelContext
    @Environment(\.dismiss) var dismiss

    @AppStorage("currencyCode") var currencyCode: CurrencyCode = .usd

    @Query var operations: [AssetOperation]

    var operation: AssetOperation
    var linkedOperation: AssetOperation? = nil

    @State var showEditSheet: Bool = false
    @State var showDeleteDialog: Bool = false
    @State var showStopDialog: Bool = false
    @State var pendingDelete: DeleteAction = .none

    private var isInflow: Bool { operation.amount >= 0 }
    private var accentColor: Color { isInflow ? .green : .red }

    private var seriesHistory: [AssetOperation] {
        guard operation.frequency != .single else { return [] }
        if let seriesId = operation.seriesId {
            return operations.filter {
                $0.id != operation.id && $0.seriesId == seriesId
            }.sorted { $0.date > $1.date }
        }
        return operations.filter {
            $0.id != operation.id &&
            $0.name == operation.name &&
            $0.asset?.id == operation.asset?.id &&
            $0.frequency == operation.frequency
        }.sorted { $0.date > $1.date }
    }

    var body: some View {
        List {
            Section {
                VStack(spacing: 10) {
                    Text(operation.amount, format: .currency(code: currencyCode.rawValue))
                        .font(.system(size: 52, weight: .bold, design: .rounded))
                        .foregroundStyle(accentColor)
                        .contentTransition(.numericText())

                    Text(operation.date, format: .dateTime.day().month(.wide).year().hour().minute())
                        .font(.callout)
                        .foregroundStyle(.secondary)

                    Label(
                        isInflow ? "Inflow" : "Outflow",
                        systemImage: isInflow ? "arrow.down.circle.fill" : "arrow.up.circle.fill"
                    )
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(accentColor)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(accentColor.opacity(0.12))
                    .clipShape(Capsule())
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
            }
            .listRowSeparator(.hidden)

            Section {
                LabeledContent {
                    Text(operation.name)
                        .foregroundStyle(.secondary)
                } label: {
                    Label("Name", systemImage: "text.alignleft")
                }

                if let asset = operation.asset {
                    LabeledContent {
                        Text(asset.name)
                            .foregroundStyle(.secondary)
                    } label: {
                        Label("Asset", systemImage: "building.columns")
                    }
                }

                if let category = operation.category {
                    LabeledContent {
                        Text(category.name)
                            .foregroundStyle(.secondary)
                    } label: {
                        Label("Category", systemImage: "tag")
                    }
                }

                if operation.frequency != .single {
                    LabeledContent {
                        Text(operation.frequency.rawValue)
                            .foregroundStyle(.secondary)
                    } label: {
                        Label("Recurring", systemImage: "repeat")
                    }

                    if let nextPaymentDate = operation.frequency.nextPaymentDate(from: operation.date) {
                        LabeledContent {
                            Text(nextPaymentDate, format: .dateTime.day().month(.abbreviated).year(.twoDigits).hour().minute())
                                .foregroundStyle(.secondary)
                        } label: {
                            Label("Next payment", systemImage: "calendar.badge.clock")
                        }
                    }
                }
            }

            if let linkedOperation = linkedOperation, let linkedAsset = linkedOperation.asset {
                Section {
                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("From")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                            Text(operation.asset?.name ?? "—")
                                .font(.subheadline.weight(.medium))
                        }

                        Spacer()

                        Image(systemName: "arrow.right.circle.fill")
                            .foregroundStyle(.secondary)

                        Spacer()

                        VStack(alignment: .trailing, spacing: 2) {
                            Text("To")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                            Text(linkedAsset.name)
                                .font(.subheadline.weight(.medium))
                        }
                    }
                    .padding(.vertical, 4)

                    LabeledContent {
                        Text(linkedOperation.amount, format: .currency(code: currencyCode.rawValue))
                            .foregroundStyle(linkedOperation.amount >= 0 ? .green : .red)
                    } label: {
                        Label("Received", systemImage: "arrow.down.circle")
                    }
                } header: {
                    Label("Transfer", systemImage: "arrow.left.arrow.right")
                }
            }

            if !operation.note.isEmpty {
                Section {
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: "quote.opening")
                            .font(.title2)
                            .foregroundStyle(.tertiary)

                        Text(operation.note)
                            .font(.body)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .lineLimit(8)
                            .mask {
                                VStack(spacing: 0) {
                                    LinearGradient(colors: [.clear, .black], startPoint: .top, endPoint: .bottom)
                                        .frame(height: 10)
                                    Color.black
                                    LinearGradient(colors: [.black, .clear], startPoint: .top, endPoint: .bottom)
                                        .frame(height: 10)
                                }
                            }
                    }
                    .padding(.vertical, 4)
                } header: {
                    Label("Note", systemImage: "note.text")
                }
            }
            if !seriesHistory.isEmpty {
                Section {
                    ForEach(seriesHistory) { sibling in
                        NavigationLink {
                            OperationDetailView(operation: sibling)
                        } label: {
                            HStack {
                                Text(sibling.date, format: .dateTime.day().month(.abbreviated).year())
                                    .font(.body)
                                    .foregroundStyle(.primary)

                                Spacer()

                                Text(sibling.amount, format: .currency(code: currencyCode.rawValue))
                                    .font(.body)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(sibling.amount >= 0 ? .green : .red)
                            }
                        }
                    }
                } header: {
                    Label("History", systemImage: "clock.arrow.circlepath")
                }
            }
        }
        .navigationTitle(operation.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if operation.frequency != .single {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showStopDialog = true
                    } label: {
                        Label("Stop recurring", systemImage: "stop.circle")
                    }
                    .tint(.orange)
                }
            }

            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showEditSheet = true
                } label: {
                    Label("Edit", systemImage: "pencil")
                }
            }

            ToolbarItem(placement: .topBarTrailing) {
                Button(role: .destructive) {
                    showDeleteDialog = true
                } label: {
                    Label("Delete", systemImage: "trash")
                }
                .tint(.red)
            }
        }
        .confirmationDialog("Stop recurring?", isPresented: $showStopDialog) {
            Button("Stop recurring", role: .destructive) {
                if let seriesId = operation.seriesId {
                    cancelRecurringNotifications(seriesId: seriesId)
                }
                operation.frequency = .single
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("No future occurrences will be generated. Past occurrences are kept.")
        }
        .sheet(isPresented: $showEditSheet, content: {
            if let category = operation.category {
                EditAssetOperationView(operation: operation, category: category)
            }
        })
        .confirmationDialog("Are you sure you want to delete?", isPresented: $showDeleteDialog) {
            if let linkedOperation = linkedOperation {
                Button("Delete current", role: .destructive) {
                    pendingDelete = .current
                    modelContext.delete(operation)
                    linkedOperation.swapId = nil
                    pendingDelete = .none
                    dismiss()
                }

                Button("Delete linked", role: .destructive) {
                    pendingDelete = .linked
                    modelContext.delete(linkedOperation)
                    operation.swapId = nil
                    pendingDelete = .none
                    dismiss()
                }

                Button("Delete both", role: .destructive) {
                    pendingDelete = .both
                    modelContext.delete(operation)
                    modelContext.delete(linkedOperation)
                    pendingDelete = .none
                    dismiss()
                }
            } else {
                Button("Delete", role: .destructive) {
                    pendingDelete = .current
                    modelContext.delete(operation)
                    pendingDelete = .none
                    dismiss()
                }
            }

            Button("Cancel", role: .cancel) {
                pendingDelete = .none
            }
        }
    }
}

#Preview {
    NavigationStack {
        OperationDetailView(
            operation: AssetOperation(date: .now, amount: 100.0)
        )
    }
}
