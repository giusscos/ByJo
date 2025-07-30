//
//  ContentView.swift
//  ByJo
//
//  Created by Giuseppe Cosenza on 04/11/24.
//

import SwiftUI
import SwiftData
import StoreKit

struct ContentView: View {
    @State var store = Store()
   
    var body: some View {
        if !store.purchasedSubscriptions.isEmpty {
            TabView {
                Tab("Statistics", systemImage: "chart.bar.xaxis.ascending") {
                    NavigationStack {
                        HomeView()
                    }
                }
                
                Tab("Assets", systemImage: "briefcase.fill") {
                    NavigationStack {
                        AssetView()
                    }
                }
                
                Tab("Operations", systemImage: "book.pages") {
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
            .onAppear {
                UITextField.appearance().clearButtonMode = .whileEditing
            }
        } else {
            PaywallView()
        }
    }
}

#Preview {
    ContentView()
}
