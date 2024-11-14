//
//  HomeView.swift
//  ByJo
//
//  Created by Giuseppe Cosenza on 04/11/24.
//

import SwiftUI
import SwiftData
import Charts

struct HomeView: View {
    @Query var assets: [Asset]
    @Query(sort: \AssetOperation.date, order: .reverse) var operations: [AssetOperation]
    
    var body: some View {
        List {
            if assets.isEmpty {
                ContentUnavailableView(
                    "No Assets Found",
                    systemImage: "exclamationmark",
                    description: Text("You need to add an asset by selecting the Assets tab and tapping the plus button on the top right corner")
                ).listRowSeparator(.hidden)
            } else {
                Section {
                    Chart(assets, id: \.id) { value in
                        BarMark(
                            x: .value("Asset", value.name),
                            y: .value("Amount", value.initialBalance)
                        )
                        .foregroundStyle(.blue.gradient)
                        .cornerRadius(4)
                    }
                    .frame(maxHeight: UIScreen.main.bounds.height / 3, alignment: .top)
                    .listRowInsets(.init(top: 10, leading: 0, bottom: 10, trailing: 0))
                    .listRowBackground(Color.clear)
                    .aspectRatio(16/9, contentMode: .fit)
                } header: {
                    Text("Assets")
                }
            }
            
            if operations.isEmpty {
                ContentUnavailableView(
                    "No Operations Found",
                    systemImage: "exclamationmark",
                    description: Text("You need to add an operation by selecting the Operations tab and tapping the plus button on the top right corner")
                ).listRowSeparator(.hidden)
            } else {
                Section {
                    Chart(operations, id: \.id) { value in
                        if let category = value.category {
                            BarMark(
                                x: .value("Category", category.name),
                                y: .value("Amount", value.amount)
                            )
                            .foregroundStyle(.blue.gradient)
                            .cornerRadius(4)
                        }
                    }
                    .frame(maxHeight: UIScreen.main.bounds.height / 3, alignment: .top)
                    .listRowInsets(.init(top: 10, leading: 0, bottom: 10, trailing: 0))
                    .listRowBackground(Color.clear)
                    .aspectRatio(16/9, contentMode: .fit)
                } header: {
                    Text("Categories")
                }
                
                Section {
                    Chart(operations, id: \.id) { value in
                        LineMark(
                            x: .value("Date", value.date),
                            y: .value("Amount", value.amount)
                        )
                    }
                    .frame(maxHeight: UIScreen.main.bounds.height / 3, alignment: .top)
                    .listRowInsets(.init(top: 10, leading: 0, bottom: 10, trailing: 0))
                    .listRowBackground(Color.clear)
                    .aspectRatio(16/9, contentMode: .fit)
                } header: {
                    Text("Operations")
                }
            }
        }
        .navigationTitle("Home")
        .navigationBarTitleDisplayMode(.inline)
        .listStyle(.plain)
    }
}

#Preview {
    HomeView()
}
