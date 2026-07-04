//
//  SearchView.swift
//  ByJo
//
//  Created by Giuseppe Cosenza on 04/07/26.
//

import SwiftUI
import SwiftData

struct SearchView: View {
    @Query var assets: [Asset]
    @Query(sort: \AssetOperation.date, order: .reverse) var operations: [AssetOperation]

    @State private var searchText = ""

    var filteredAssets: [Asset] {
        guard !searchText.isEmpty else { return [] }
        return assets.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.type.rawValue.localizedCaseInsensitiveContains(searchText)
        }
    }

    var filteredOperations: [AssetOperation] {
        guard !searchText.isEmpty else { return [] }
        return operations.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.asset?.name.localizedCaseInsensitiveContains(searchText) == true ||
            $0.category?.name.localizedCaseInsensitiveContains(searchText) == true
        }
    }

    var hasResults: Bool {
        !filteredAssets.isEmpty || !filteredOperations.isEmpty
    }

    var body: some View {
        NavigationStack {
            List {
                if searchText.isEmpty {
                    ContentUnavailableView("Search", systemImage: "magnifyingglass", description: Text("Search for assets and operations by name, type, or category."))
                } else if !hasResults {
                    ContentUnavailableView.search(text: searchText)
                } else {
                    if !filteredAssets.isEmpty {
                        Section("Assets") {
                            ForEach(filteredAssets) { asset in
                                NavigationLink {
                                    AssetDetailView(asset: asset)
                                } label: {
                                    AssetRowView(asset: asset)
                                }
                            }
                        }
                    }

                    if !filteredOperations.isEmpty {
                        Section("Operations") {
                            ForEach(filteredOperations) { operation in
                                NavigationLink {
                                    OperationDetailView(operation: operation)
                                } label: {
                                    OperationRow(operation: operation)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Search")
            .searchable(text: $searchText, prompt: "Assets, operations, categories…")
        }
    }
}

#Preview {
    SearchView()
}
