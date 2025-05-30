//
//  OperationView.swift
//  ByJo
//
//  Created by Giuseppe Cosenza on 04/11/24.
//

import SwiftUI
import SwiftData

enum ActiveSheet: Identifiable {
    case editOperation(AssetOperation)
    case viewCategories
    
    var id: String {
        switch self {
        case .editOperation(let operation):
            return "editOperation-\(operation.id)"
        case .viewCategories:
            return "viewCategories"
        }
    }
}

struct OperationView: View {
    @Environment(\.modelContext) var modelContext
    
    @Query(sort: \AssetOperation.date, order: .reverse) var operations: [AssetOperation]
    
    @Query var assets: [Asset]
    
    @Query var categories: [CategoryOperation]
    
    @State private var activeSheet: ActiveSheet?
    @State private var operationToDelete: AssetOperation?
    @State private var showingDeleteAlert = false
    @State private var showingBulkDeleteAlert = false
    
    @State private var showingImporter = false
    @State private var importError: CSVError?
    @State private var showingAddOperationError = false
    @State private var showingError = false
    @State private var showingSuccess = false
    @State private var successMessage = ""
    
    @State private var selectedAsset: Asset?
    @State private var filterCategory: CategoryOperation?
    @State private var isEditMode: EditMode = .inactive
    @State private var selectedOperations = Set<AssetOperation>()
        
    var filteredAndSortedOperations: [OperationByDate] {
        var filteredOperations = operations
        
        if let asset = selectedAsset {
            filteredOperations = filteredOperations.filter { $0.asset == asset }
        }
        
        if let category = filterCategory {
            filteredOperations = filteredOperations.filter { $0.category == category }
        }
    
        return groupOperationsByDate(filteredOperations)
    }
    
    func groupOperationsByDate(_ operations: [AssetOperation]) -> [OperationByDate] {
        let calendar = Calendar.current
        let normalizedOperations = operations.map { operation -> (Date, AssetOperation) in
            let components = calendar.dateComponents([.year, .month, .day], from: operation.date)
            let normalizedDate = calendar.date(from: components)!
            return (normalizedDate, operation)
        }
        
        let groupedDict = Dictionary(grouping: normalizedOperations) { $0.0 }
        
        return groupedDict.map { (date, operationPairs) in
            OperationByDate(date: date, operations: operationPairs.map { $0.1 })
        }.sorted { $0.date > $1.date }
    }
    
    var dateBasedOperations: [OperationByDate] {
        let calendar = Calendar.current
        
        let normalizedOperations = operations.map { operation -> (Date, AssetOperation) in
            let components = calendar.dateComponents([.year, .month, .day], from: operation.date)
            let normalizedDate = calendar.date(from: components)!
            return (normalizedDate, operation)
        }
        
        let groupedDict = Dictionary(grouping: normalizedOperations) { $0.0 }
        
        return groupedDict.map { (date, operationPairs) in
            OperationByDate(date: date, operations: operationPairs.map { $0.1 })
        }.sorted { $0.date > $1.date }
    }
    
    var body: some View {
        List(selection: $selectedOperations) {
            if filteredAndSortedOperations.isEmpty {
                ContentUnavailableView(
                    "No Operations Found",
                    systemImage: "exclamationmark",
                    description: Text("You need to add an operation by clicking the plus button on the top right corner")
                )
            } else {
                ForEach(filteredAndSortedOperations) { item in
                    Section {
                        ForEach(item.operations) { value in
                            NavigationLink {
                                OperationDetailView(operation: value)
                            } label: {
                                OperationRow(operation: value)
                            }
                            .tag(value)
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button(role: .destructive) {
                                    modelContext.delete(value)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                                
                                Button {
                                    activeSheet = .editOperation(value)
                                } label: {
                                    Label("Edit", systemImage: "pencil")
                                }
                                .tint(.blue)
                            }
                        }
                    } header: {
                        Text(item.date.formatted(.dateTime.day().month().year()))
                            .headerProminence(.increased)
                    }
                }
            }
        }
        .navigationTitle("Operations")
        .toolbar {
            if !operations.isEmpty {
                ToolbarItem(placement: .topBarLeading) {
                    EditButton()
                }
            }
            
            ToolbarItem(placement: .topBarTrailing) {
                if isEditMode == .active {
                    Button(role: .destructive) {
                        showingBulkDeleteAlert = true
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                    .disabled(selectedOperations.isEmpty)
                } else {
                    Menu {
                        Button {
                            addOperation()
                        } label: {
                            Label("Add operation", systemImage: "plus")
                        }

                        Button {
                            showingImporter.toggle()
                        } label: {
                            Label("Import Operations", systemImage: "square.and.arrow.down")
                        }
                        
                        Button {
                            activeSheet = .viewCategories
                        } label: {
                            Label("Categories", systemImage: "list.bullet")
                        }
                        
                        Section {
                            Menu("By Asset") {
                                ForEach(assets, id: \.id) { asset in
                                    Button(asset.name) {
                                        selectedAsset = asset
                                    }
                                }
                                Button("Clear Filter") {
                                    selectedAsset = nil
                                }
                            }
                            
                            Menu("By Category") {
                                ForEach(categories) { category in
                                    Button(category.name) {
                                        filterCategory = category
                                    }
                                }
                                
                                Button("Clear Filter") {
                                    filterCategory = nil
                                }
                            }
                        } header: {
                            Text("Filters")
                        }
                    } label: {
                        Label("Menu", systemImage: "ellipsis.circle")
                    }
                }
            }
        }
        .environment(\.editMode, $isEditMode)
        .sheet(item: $activeSheet) { sheet in
            switch sheet {
            case .editOperation(let operation):
                EditAssetOperation(operation: operation)
            case .viewCategories:
                CategoryOperationView()
            }
        }
        .fileImporter(
            isPresented: $showingImporter,
            allowedContentTypes: [.commaSeparatedText],
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
        .alert("You can't add an operation yet", isPresented: $showingAddOperationError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("You need to add an asset and a category before adding an operation")
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
        .alert("Delete Operations", isPresented: $showingBulkDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                deleteSelectedOperations()
            }
        } message: {
            Text("Are you sure you want to delete \(selectedOperations.count) operations? This action cannot be undone.")
        }
    }
    
    private func deleteSelectedOperations() {
        for operation in selectedOperations {
            modelContext.delete(operation)
        }
        selectedOperations.removeAll()
        isEditMode = .inactive
    }
    
    func addOperation() {
        if let asset = assets.first, !categories.isEmpty {
            let operation = AssetOperation()
            operation.asset = asset
            modelContext.insert(operation)
            activeSheet = .editOperation(operation)
        } else {
            showingAddOperationError = true
        }
    }
}

struct OperationByDate: Identifiable {
    var date: Date
    var operations: [AssetOperation]
    
    var id: Date { date }
}

#Preview {
    OperationView()
}

