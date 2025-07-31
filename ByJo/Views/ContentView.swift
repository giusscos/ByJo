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
                Tab("Home", systemImage: "house.fill") {
                    HomeView()
                }
                
                Tab("Assets", systemImage: "briefcase.fill") {
                    AssetView()
                }
                
                Tab("Operations", systemImage: "book.pages") {
                    OperationView()
                }
                
                Tab("Settings", systemImage: "gear") {
                    SettingsView()
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
