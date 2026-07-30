//
//  ExportImportView.swift
//  ByJo

import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct ExportImportView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @Query var assets: [Asset]
    @Query(sort: \AssetOperation.date, order: .reverse) var operations: [AssetOperation]
    @Query var categories: [CategoryOperation]
    @Query var goals: [Goal]

    @State private var csvExportURL: URL?
    @State private var jsonExportURL: URL?
    @State private var showCSVPicker = false
    @State private var showJSONPicker = false
    @State private var csvImportState: CSVImportState?
    @State private var pendingJSONImport: ByJoExport?
    @State private var showJSONConfirm = false
    @State private var errorMessage: String?
    @State private var showError = false

    var body: some View {
        NavigationStack {
            List {
                exportSection
                importSection
                sampleFilesSection
            }
            .navigationTitle("Export & Import")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .onAppear { prepareExportFiles() }
            .fileImporter(
                isPresented: $showCSVPicker,
                allowedContentTypes: [.commaSeparatedText],
                onCompletion: handleCSVImport
            )
            .fileImporter(
                isPresented: $showJSONPicker,
                allowedContentTypes: [.json],
                onCompletion: handleJSONImport
            )
            .sheet(item: $csvImportState) { state in
                CSVImportMappingView(state: state)
            }
            .sheet(isPresented: $showJSONConfirm) {
                if let export = pendingJSONImport {
                    JSONImportConfirmView(export: export) { skipDuplicates in
                        performJSONImport(export, skipDuplicates: skipDuplicates)
                    }
                }
            }
            .alert("Import Error", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage ?? "Unknown error")
            }
        }
    }

    // MARK: - Sections

    private var exportSection: some View {
        Section {
            if let url = csvExportURL {
                ShareLink(
                    item: url,
                    preview: SharePreview("byjo_operations.csv", icon: Image(systemName: "tablecells"))
                ) {
                    Label("Export Operations as CSV", systemImage: "tablecells")
                }
            } else {
                Label("No operations to export", systemImage: "tablecells")
                    .foregroundStyle(.secondary)
            }

            if let url = jsonExportURL {
                ShareLink(
                    item: url,
                    preview: SharePreview("byjo_backup.json", icon: Image(systemName: "arrow.up.doc"))
                ) {
                    Label("Export Full Backup (JSON)", systemImage: "arrow.up.doc")
                }
            } else {
                Label("No data to export", systemImage: "arrow.up.doc")
                    .foregroundStyle(.secondary)
            }
        } header: {
            Text("Export")
        } footer: {
            Text("CSV contains all operations. JSON contains everything: assets, operations, categories, and goals.")
        }
    }

    private var importSection: some View {
        Section {
            Button {
                showCSVPicker = true
            } label: {
                Label("Import CSV…", systemImage: "tablecells.badge.ellipsis")
            }

            Button {
                showJSONPicker = true
            } label: {
                Label("Restore from JSON Backup…", systemImage: "arrow.down.doc")
            }
        } header: {
            Text("Import")
        } footer: {
            Text("Imported data is added to your existing data. CSV lets you map columns from any spreadsheet.")
        }
    }

    private var sampleFilesSection: some View {
        Section {
            if let url = Bundle.main.url(forResource: "sample_operations", withExtension: "csv") {
                ShareLink(item: url, preview: SharePreview("sample_operations.csv")) {
                    Label("Sample CSV File", systemImage: "doc.text")
                }
            }
            if let url = Bundle.main.url(forResource: "sample_backup", withExtension: "json") {
                ShareLink(item: url, preview: SharePreview("sample_backup.json")) {
                    Label("Sample JSON Backup", systemImage: "doc.badge.gearshape")
                }
            }
        } header: {
            Text("Sample Files")
        } footer: {
            Text("Download these to understand the expected format before importing your own data.")
        }
    }

    // MARK: - Helpers

    private func prepareExportFiles() {
        if !operations.isEmpty {
            let csv = DataManager.exportCSV(operations: operations)
            csvExportURL = DataManager.writeToTemp(data: Data(csv.utf8), filename: "byjo_operations.csv")
        }

        if !assets.isEmpty || !operations.isEmpty || !categories.isEmpty || !goals.isEmpty {
            if let data = try? DataManager.exportJSON(
                assets: assets,
                operations: operations,
                categories: categories,
                goals: goals
            ) {
                jsonExportURL = DataManager.writeToTemp(data: data, filename: "byjo_backup.json")
            }
        }
    }

    private func handleCSVImport(_ result: Result<URL, Error>) {
        switch result {
        case .success(let url):
            guard url.startAccessingSecurityScopedResource() else {
                showImportError("Could not access the file.")
                return
            }
            defer { url.stopAccessingSecurityScopedResource() }

            guard let text = try? String(contentsOf: url, encoding: .utf8) else {
                showImportError("Could not read the file.")
                return
            }

            let (headers, rows) = DataManager.parseCSV(text)
            guard !headers.isEmpty else {
                showImportError("The CSV file appears to be empty or has no header row.")
                return
            }

            let mapping = DataManager.autoDetectMapping(headers: headers)
            csvImportState = CSVImportState(
                id: UUID(),
                filename: url.lastPathComponent,
                headers: headers,
                rows: rows,
                mapping: mapping
            )

        case .failure(let error):
            showImportError(error.localizedDescription)
        }
    }

    private func handleJSONImport(_ result: Result<URL, Error>) {
        switch result {
        case .success(let url):
            guard url.startAccessingSecurityScopedResource() else {
                showImportError("Could not access the file.")
                return
            }
            defer { url.stopAccessingSecurityScopedResource() }

            guard let data = try? Data(contentsOf: url) else {
                showImportError("Could not read the file.")
                return
            }

            do {
                let export = try DataManager.validateJSON(data)
                pendingJSONImport = export
                showJSONConfirm = true
            } catch {
                showImportError(error.localizedDescription)
            }

        case .failure(let error):
            showImportError(error.localizedDescription)
        }
    }

    private func performJSONImport(_ export: ByJoExport, skipDuplicates: Bool) {
        do {
            try DataManager.importJSON(export, context: modelContext, skipDuplicates: skipDuplicates)
        } catch {
            showImportError(error.localizedDescription)
        }
    }

    private func showImportError(_ message: String) {
        errorMessage = message
        showError = true
    }
}
