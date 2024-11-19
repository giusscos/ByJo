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
            .onAppear {
                UITextField.appearance().clearButtonMode = .whileEditing
            }
        } else {
            SubscriptionStoreView(groupID: Store().groupId) {
                VStack {
                    Image(systemName: "lock.fill")
                        .foregroundStyle(.blue)
                        .font(.largeTitle)
                    
                    Text("Unlock App Access")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("You can track your financial activities, view your assets, and operations in fantastic charts so you can be aware of your financial situation and make good decisions.")
                        .font(.subheadline)
                        .multilineTextAlignment(.center)
                    
                    Text("Subscribe to unlock access and start tracking your finances")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fontWeight(.semibold)
                        .multilineTextAlignment(.center)
                        .padding(.vertical)
                    
                    HStack {
                        Link("Terms of use", destination: URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!)

                        Link("Privacy Policy", destination: URL(string: "https://giusscos.it/privacy")!)
                    }
                }.padding()
            }
        }
    }
}

#Preview {
    ContentView()
}
