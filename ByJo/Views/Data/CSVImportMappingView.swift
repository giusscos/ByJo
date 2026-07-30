//
//  CSVImportMappingView.swift
//  ByJo

import SwiftUI
import SwiftData

struct CSVImportState: Identifiable {
    let id: UUID
    let filename: String
    let headers: [String]
    let rows: [[String]]
    var mapping: ColumnMapping
}

struct CSVImportMappingView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let state: CSVImportState

    @State private var mapping: ColumnMapping
    @State private var skipDuplicates: Bool = true
    @State private var duplicateCount: Int = 0
    @State private var importedCount: Int = 0
    @State private var skippedCount: Int = 0
    @State private var showSuccess = false
    @State private var errorMessage: String?
    @State private var showError = false

    init(state: CSVImportState) {
        self.state = state
        self._mapping = State(initialValue: state.mapping)
    }

    private var validation: (valid: [CSVImportRow], errors: [DataImportError]) {
        DataManager.validateAndParseCSV(headers: state.headers, rows: state.rows, mapping: mapping)
    }

    private var netImportCount: Int {
        max(0, validation.valid.count - (skipDuplicates ? duplicateCount : 0))
    }

    private var canImport: Bool {
        validation.errors.isEmpty && netImportCount > 0
    }

    var body: some View {
        NavigationStack {
            Form {
                fileInfoSection
                requiredFieldsSection
                optionalFieldsSection
                importOptionsSection
                if !state.rows.prefix(3).isEmpty { previewSection }
                if !validation.errors.isEmpty { errorsSection }
            }
            .navigationTitle("Map Columns")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Import \(netImportCount)") {
                        performImport()
                    }
                    .disabled(!canImport)
                    .fontWeight(.semibold)
                }
            }
            .alert("Import Complete", isPresented: $showSuccess) {
                Button("Done") { dismiss() }
            } message: {
                if skippedCount > 0 {
                    Text("\(importedCount) imported, \(skippedCount) duplicates skipped.")
                } else {
                    Text("\(importedCount) operations imported successfully.")
                }
            }
            .alert("Import Failed", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage ?? "Unknown error")
            }
            .onAppear { refreshDuplicateCount() }
            .onChange(of: mapping) { _, _ in refreshDuplicateCount() }
        }
    }

    // MARK: - Sections

    private var fileInfoSection: some View {
        Section {
            LabeledContent("File", value: state.filename)
            LabeledContent("Rows", value: "\(state.rows.count)")
            LabeledContent("Columns detected", value: "\(state.headers.count)")
        } header: {
            Text("File Info")
        }
    }

    private var requiredFieldsSection: some View {
        Section {
            MappingPickerRow(label: "Description", selection: $mapping.name, headers: state.headers, required: true)
            MappingPickerRow(label: "Date", selection: $mapping.date, headers: state.headers, required: true)
            MappingPickerRow(label: "Amount", selection: $mapping.amount, headers: state.headers, required: true)
            MappingPickerRow(label: "Asset", selection: $mapping.asset, headers: state.headers, required: true)
        } header: {
            Text("Required Fields")
        } footer: {
            Text("Select which column in your file corresponds to each field.")
        }
    }

    private var optionalFieldsSection: some View {
        Section {
            MappingPickerRow(label: "Category", selection: $mapping.category, headers: state.headers, required: false)
            MappingPickerRow(label: "Frequency", selection: $mapping.frequency, headers: state.headers, required: false)
            MappingPickerRow(label: "Note", selection: $mapping.note, headers: state.headers, required: false)
        } header: {
            Text("Optional Fields")
        } footer: {
            Text("Frequency values: Single, Daily, Weekly, Monthly, Yearly. Unrecognised values default to Single.")
        }
    }

    private var importOptionsSection: some View {
        Section {
            Toggle("Skip duplicates", isOn: $skipDuplicates)
                .onChange(of: skipDuplicates) { _, _ in refreshDuplicateCount() }
            if duplicateCount > 0 {
                LabeledContent("Duplicates found") {
                    Text("\(duplicateCount)")
                        .foregroundStyle(skipDuplicates ? Color.secondary : Color.orange)
                }
            }
        } header: {
            Text("Import Options")
        } footer: {
            Text("A duplicate matches an existing operation by description, date, amount, and asset.")
        }
    }

    private var previewSection: some View {
        Section {
            ForEach(Array(state.rows.prefix(3).enumerated()), id: \.offset) { _, row in
                VStack(alignment: .leading, spacing: 3) {
                    if let col = mapping.name, let idx = state.headers.firstIndex(of: col), idx < row.count {
                        Text(row[idx]).font(.subheadline).fontWeight(.medium)
                    }
                    HStack {
                        if let col = mapping.date, let idx = state.headers.firstIndex(of: col), idx < row.count {
                            Text(row[idx]).font(.caption).foregroundStyle(.secondary)
                        }
                        Spacer()
                        if let col = mapping.amount, let idx = state.headers.firstIndex(of: col), idx < row.count {
                            Text(row[idx]).font(.caption).monospacedDigit()
                        }
                    }
                    if let col = mapping.asset, let idx = state.headers.firstIndex(of: col), idx < row.count {
                        Text(row[idx]).font(.caption2).foregroundStyle(.tertiary)
                    }
                }
                .padding(.vertical, 2)
            }
        } header: {
            Text("Preview — first \(min(3, state.rows.count)) rows")
        }
    }

    private var errorsSection: some View {
        Section {
            ForEach(validation.errors) { error in
                Label {
                    Text(error.localizedDescription ?? "Unknown error")
                        .font(.caption)
                } icon: {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                }
            }
        } header: {
            Text("Issues — fix these to enable import")
        }
    }

    // MARK: - Helpers

    private func refreshDuplicateCount() {
        guard mapping.isComplete else { duplicateCount = 0; return }
        duplicateCount = DataManager.countDuplicates(rows: validation.valid, context: modelContext)
    }

    // MARK: - Import

    private func performImport() {
        let rows = validation.valid
        guard !rows.isEmpty else { return }
        do {
            let result = try DataManager.importCSV(rows: rows, context: modelContext, skipDuplicates: skipDuplicates)
            importedCount = result.imported
            skippedCount = result.skipped
            showSuccess = true
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }
}

// MARK: - MappingPickerRow

struct MappingPickerRow: View {
    let label: String
    @Binding var selection: String?
    let headers: [String]
    let required: Bool

    var body: some View {
        Picker(selection: $selection) {
            Text(required ? "Select column…" : "None")
                .tag(Optional<String>.none)
            ForEach(headers, id: \.self) { header in
                Text(header).tag(Optional<String>(header))
            }
        } label: {
            HStack(spacing: 4) {
                Text(label)
                if required && selection == nil {
                    Image(systemName: "asterisk")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundStyle(.orange)
                        .offset(y: -3)
                }
            }
        }
    }
}
