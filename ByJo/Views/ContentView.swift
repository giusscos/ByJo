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
                VStack (spacing: 4) {
                    Image(systemName: "lock.fill")
                        .foregroundStyle(.blue)
                        .font(.largeTitle)
                    
                    VStack (spacing: 12) {
                        Text("Unlock App Access")
                            .font(.title)
                            .fontWeight(.bold)
                        
                        Text("Track your financial activities, view your assets and operations so you can be aware of your financial situation and make good decisions.")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .multilineTextAlignment(.center)
                    }
                }.padding()
            }
            .subscriptionStoreButtonLabel(.multiline)
            .storeButton(.visible, for: .restorePurchases)
        }
    }
}

#Preview {
    ContentView()
}
