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
            allowedContentTypes: [.commaSeparatedText],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                guard let url = urls.first else { return }
                
                do {
                    _ = try CSVManager.shared.importCSV(
                        from: url,
                        context: modelContext,
                        assets: assets,
                        categories: categories
                    )
                } catch let error as CSVError {
                    importError = error
                    showingError = true
                } catch {
                    importError = .invalidFormat
                    showingError = true
                }
                
            case .failure(_):
                importError = .invalidFormat
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
            }
        }
        .sheet(isPresented: $showingTemplate) {
            NavigationStack {
                ScrollView {
                    Text(CSVManager.shared.getCSVTemplate())
                        .font(.system(.body, design: .monospaced))
                        .padding()
                }
                .navigationTitle("CSV Template")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Done") {
                            showingTemplate = false
                        }
                    }
                }
            }
        }
        .alert("Import Error", isPresented: $showingError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(importError?.description ?? "Unknown error occurred")
        }
    }
}

struct CSVDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.commaSeparatedText] }
    
    var operations: [AssetOperation]
    
    init(operations: [AssetOperation]) {
        self.operations = operations
    }
    
    init(configuration: ReadConfiguration) throws {
        operations = []
    }
    
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        let data = try CSVManager.shared.exportCSV(operations: operations)
        return FileWrapper(regularFileWithContents: Data(data.utf8))
    }
}

#Preview {
    SettingsView()
}
