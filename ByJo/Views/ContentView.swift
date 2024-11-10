//
//  ContentView.swift
//  ByJo
//
//  Created by Giuseppe Cosenza on 04/11/24.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    var body: some View {
        TabView {
            Tab("Home", systemImage: "house.fill") {
                NavigationStack {
                    HomeView()
                }
            }
            
            Tab("Assets", systemImage: "briefcase.fill") {
                NavigationStack {
                    AssetView()
                }
            }
            
            Tab("Operations", systemImage: "minus.slash.plus") {
                NavigationStack {
                    OperationView()
                }
            }
            
            Tab("Settings", systemImage: "gear") {
                NavigationStack {
                    SettingsView()
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
