//
//  JSONImportConfirmView.swift
//  ByJo

import SwiftUI
import SwiftData

struct JSONImportConfirmView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let export: ByJoExport
    let onConfirm: (Bool) -> Void

    @State private var skipDuplicates: Bool = true
    @State private var duplicates: DataManager.JSONDuplicateCounts?

    private var hasDuplicates: Bool { (duplicates?.total ?? 0) > 0 }

    var body: some View {
        NavigationStack {
            List {
                backupInfoSection
                contentsSection
                if hasDuplicates { duplicatesSection }
                importOptionsSection
                noticeSection
            }
            .navigationTitle("Restore Backup")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Import") {
                        onConfirm(skipDuplicates)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
            .onAppear {
                duplicates = DataManager.countJSONDuplicates(export: export, context: modelContext)
            }
        }
    }

    // MARK: - Sections

    private var backupInfoSection: some View {
        Section {
            LabeledContent("Export Date", value: export.exportDate.formatted(date: .abbreviated, time: .shortened))
            LabeledContent("Version", value: "\(export.version)")
        }
    }

    private var contentsSection: some View {
        Section {
            LabeledContent("Assets", value: "\(export.assets.count)")
            LabeledContent("Operations", value: "\(export.operations.count)")
            LabeledContent("Categories", value: "\(export.categories.count)")
            LabeledContent("Goals", value: "\(export.goals.count)")
        } header: {
            Text("Backup Contents")
        }
    }

    private var duplicatesSection: some View {
        Section {
            if let d = duplicates {
                if d.assets > 0      { duplicateRow("Assets",      count: d.assets) }
                if d.operations > 0  { duplicateRow("Operations",  count: d.operations) }
                if d.categories > 0  { duplicateRow("Categories",  count: d.categories) }
                if d.goals > 0       { duplicateRow("Goals",       count: d.goals) }
            }
        } header: {
            Text("Duplicates Found")
        } footer: {
            Text("Assets and categories match by name. Operations match by description, date, amount, and asset. Goals match by title, target, and asset.")
        }
    }

    private func duplicateRow(_ label: String, count: Int) -> some View {
        LabeledContent(label) {
            Text("\(count) already exist")
                .foregroundStyle(skipDuplicates ? Color.secondary : Color.orange)
        }
    }

    private var importOptionsSection: some View {
        Section {
            Toggle("Skip duplicates", isOn: $skipDuplicates)
        } header: {
            Text("Import Options")
        }
    }

    private var noticeSection: some View {
        Section {
            Label {
                Text("This adds to your existing data, not replaces it. To start fresh, delete your data first.")
                    .font(.footnote)
            } icon: {
                Image(systemName: "info.circle")
                    .foregroundStyle(.blue)
            }
        }
    }
}
