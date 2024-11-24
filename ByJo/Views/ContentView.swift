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
    @State private var currentIndex: Int = 0
    @State private var timer: Timer? = nil
    
    private let contentData = [
        (
            title: "Unlock App Access",
            description: "Set goals to achieve and enhance your performance",
            imageName: "Goal"
        ),
        (
            title: "Unlock App Access",
            description: "View fantastic charts to track your progress and view your results more easily",
            imageName: "Charts"
        ),
        (
            title: "Unlock App Access",
            description: "View, filter and manage your asset operations",
            imageName: "Operations"
        )
    ]
    
    private let slideInterval: TimeInterval = 7
    
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
                VStack(spacing: 12) {
                    Spacer()
                    
                    Text(contentData[currentIndex].title)
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text(contentData[currentIndex].description)
                        .font(.headline)
                        .multilineTextAlignment(.center)
                    
                    Spacer()
                    
                    Image(contentData[currentIndex].imageName)
                        .resizable()
                        .scaledToFit()
                    
                    Text("\(currentIndex + 1)/\(contentData.count)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .animation(.easeInOut, value: currentIndex)
            }
            .subscriptionStoreControlStyle(.compactPicker, placement: .bottomBar)
            .subscriptionStoreButtonLabel(.multiline)
            .storeButton(.visible, for: .restorePurchases)
            .onAppear {
                startTimer()
            }
            .onDisappear {
                stopTimer()
            }
        }
    }
    
    func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: slideInterval, repeats: true) { _ in
            currentIndex = currentIndex + 1
            if currentIndex > contentData.count - 1 {
                currentIndex = 0
            }
        }
    }
    
    func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
}

#Preview {
    ContentView()
}
