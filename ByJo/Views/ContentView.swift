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
    
    @State var showPaywallSheet: Bool = true
   
    var hasntPaid: Bool {
        store.purchasedSubscriptions.isEmpty || store.purchasedProducts.isEmpty
    }
    
    var body: some View {
        if store.isLoading {
            ProgressView()
        } else {
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
            .fullScreenCover(isPresented: $showPaywallSheet, content: {
                PaywallView()
            })
            .onAppear {
                UITextField.appearance().clearButtonMode = .whileEditing
                
                if hasntPaid {
                    showPaywallSheet = false
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
