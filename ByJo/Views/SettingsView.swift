//
//  SettingsView.swift
//  ByJo
//
//  Created by Giuseppe Cosenza on 04/11/24.
//

import SwiftUI
import StoreKit
import SwiftData
import UniformTypeIdentifiers

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \AssetOperation.date, order: .reverse) private var operations: [AssetOperation]
    @Query private var assets: [Asset]
    @Query private var categories: [CategoryOperation]
    
    @State private var manageSubscription: Bool = false
    @State private var showingImporter = false
    @State private var showingExporter = false
    @State private var showingTemplate = false
    @State private var importError: CSVError?
    @State private var showingError = false
    @State private var showingSuccess = false
    @State private var successMessage = ""
    
    var body: some View {
        List {
            Section {
                Button("Import Operations from CSV") {
                    showingImporter = true
                }
                
                Button("Export Operations to CSV") {
                    showingExporter = true
                }
                
                Button("View CSV Template") {
                    showingTemplate = true
                }
            } header: {
                Text("Data Management")
            }
            
            Section {
                Button("Manage subscription") {
                    manageSubscription.toggle()
                }

                Link("Send me a Feedback", destination: URL(string: "mailto:hellos@giusscos.com")!)
                    .foregroundColor(.blue)
                
                Link("Terms of use", destination: URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!)
                    .foregroundColor(.blue)
                
                Link("Privacy Policy", destination: URL(string: "https://giusscos.it/privacy")!)
                    .foregroundColor(.blue)
            } header: {
                Text("Support")
            }
        }
        .manageSubscriptionsSheet(isPresented: $manageSubscription, subscriptionGroupID: Store().groupId)
        .fileImporter(
            isPresented: $showingImporter,
            allowedContentTypes: [.text, .commaSeparatedText],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                guard let url = urls.first else { return }
                
                // Start accessing the security-scoped resource
                guard url.startAccessingSecurityScopedResource() else {
                    importError = CSVError.detailedError("Permission denied: Cannot access the selected file")
                    showingError = true
                    return
                }
                
                // Ensure we stop accessing the resource when we're done
                defer { url.stopAccessingSecurityScopedResource() }
                
                do {
                    let importedOperations = try CSVManager.shared.importCSV(
                        from: url,
                        context: modelContext,
                        assets: assets,
                        categories: categories
                    )
                    successMessage = "Successfully imported \(importedOperations.count) operations"
                    showingSuccess = true
                } catch let error as CSVError {
                    importError = error
                    showingError = true
                } catch {
                    importError = .detailedError("Unexpected error: \(error.localizedDescription)")
                    showingError = true
                }
                
            case .failure(let error):
                importError = .detailedError("Failed to import file: \(error.localizedDescription)")
                showingError = true
            }
        }
        .fileExporter(
            isPresented: $showingExporter,
            document: CSVDocument(operations: operations),
            contentType: .commaSeparatedText,
            defaultFilename: "operations_export"
        ) { result in
            if case .failure(_) = result {
                importError = .exportError
                showingError = true
            } else {
                successMessage = "Successfully exported \(operations.count) operations"
                showingSuccess = true
            }
        }
        .sheet(isPresented: $showingTemplate) {
            NavigationStack {
                CSVTemplateView(csvString: CSVManager.shared.getCSVTemplate())
                    .navigationTitle("CSV Template")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button("Done") {
                                showingTemplate = false
                            }
                        }
                        
                        ToolbarItem(placement: .topBarLeading) {
                            ShareLink(
                                item: CSVDocument(text: CSVManager.shared.getCSVTemplate()),
                                preview: SharePreview(
                                    "CSV Template",
                                    image: Image(systemName: "doc.text")
                                )
                            ) {
                                Image(systemName: "square.and.arrow.down")
                            }
                        }
                    }
            }
            .presentationDetents([.medium])
        }
        .alert("Import Error", isPresented: $showingError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(importError?.description ?? "Unknown error occurred")
        }
        .alert("Success", isPresented: $showingSuccess) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(successMessage)
        }
    }
}

struct CSVDocument: FileDocument, Transferable {
    static var readableContentTypes: [UTType] { [.commaSeparatedText] }
    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(exportedContentType: UTType.commaSeparatedText) { document in
            Data(document.text.utf8)
        }
    }
    
    var text: String
    
    init(text: String) {
        self.text = text
    }
    
    init(operations: [AssetOperation]) {
        do {
            self.text = try CSVManager.shared.exportCSV(operations: operations)
        } catch {
            self.text = ""
        }
    }
    
    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents,
              let string = String(data: data, encoding: .utf8)
        else {
            throw CocoaError(.fileReadCorruptFile)
        }
        text = string
    }
    
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        return FileWrapper(regularFileWithContents: Data(text.utf8))
    }
}

struct CSVRow: Identifiable {
    let id = UUID()
    let date: String
    let name: String
    let amount: String
    let category: String
    let asset: String
    let note: String
}

struct CSVTemplateView: View {
    let headers: [String]
    let rows: [[String]]
    private let columnWidths: [CGFloat]
    
    init(csvString: String) {
        let lines = csvString.components(separatedBy: .newlines)
            .filter { !$0.isEmpty }
        self.headers = CSVManager.shared.parseCSVLine(lines[0])
        self.rows = lines.dropFirst().map { CSVManager.shared.parseCSVLine($0) }
        
        // Calculate column widths based on content
        var widths: [CGFloat] = Array(repeating: 0, count: self.headers.count)
        
        // Check headers width
        for (index, header) in self.headers.enumerated() {
            widths[index] = max(widths[index], CGFloat(header.count * 10 + 32))
        }
        
        // Check content width
        for row in self.rows {
            for (index, cell) in row.enumerated() where index < widths.count {
                widths[index] = max(widths[index], CGFloat(cell.count * 10 + 32))
            }
        }
        
        self.columnWidths = widths.map { max($0, 100) }
    }
    
    var body: some View {
        ScrollView([.horizontal]) {
            VStack(alignment: .leading, spacing: 0) {
                // Headers
                HStack(spacing: 0) {
                    ForEach(Array(headers.enumerated()), id: \.offset) { index, header in
                        Text(header)
                            .font(.headline)
                            .padding(8)
                            .frame(width: columnWidths[index])
                            .background(Color.gray.opacity(0.2))
                            .border(Color.gray.opacity(0.3), width: 1)
                    }
                }
                
                // Rows
                ForEach(rows, id: \.self) { row in
                    HStack(spacing: 0) {
                        ForEach(0..<headers.count, id: \.self) { index in
                            Text(index < row.count ? row[index] : "")
                                .font(.body)
                                .padding(8)
                                .frame(width: columnWidths[index])
                                .border(Color.gray.opacity(0.3), width: 1)
                        }
                    }
                }
            }
        }
        .scrollIndicators(.hidden)
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }
}

#Preview {
    SettingsView()
}
