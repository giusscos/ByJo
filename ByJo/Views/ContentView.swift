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
            title: "Achieve Your Goals",
            description: "Set goals to achieve and enhance your performance",
            imageName: "target"
        ),
        (
            title: "Consult Your Progress",
            description: "View fantastic charts to track your progress and view your results more easily",
            imageName: "chart.bar.fill"
        ),
        (
            title: "Manage Your Assets easily",
            description: "View, filter and manage your asset operations",
            imageName: "book.pages"
        ),
        (
            title: "Privacy first",
            description: "ByJo do not collect any personal data, you can export and import csv files to manage your data locally",
            imageName: "lock.shield"
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
            SubscriptionStoreView(groupID: Store().groupId) {
                TabView(selection: $currentIndex) {
                    ForEach(0..<contentData.count, id: \.self) { index in
                        VStack(spacing: 12) {
                            Image(systemName: contentData[index].imageName)
                                .font(.largeTitle)
                                .foregroundStyle(Color.accentColor)
                            
                            Text(contentData[index].title)
                                .font(.title)
                                .bold()
                            
                            Text(contentData[index].description)
                                .font(.headline)
                                .multilineTextAlignment(.center)
                        }
                        .tag(index)
                    }
                }
                .tabViewStyle(.page)
                .indexViewStyle(.page(backgroundDisplayMode: .always))
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
    
    private func startTimer() {
        stopTimer()
        timer = Timer.scheduledTimer(withTimeInterval: slideInterval, repeats: true) { _ in
            withAnimation {
                if currentIndex >= contentData.count - 1 {
                    currentIndex = 0
                } else {
                    currentIndex += 1
                }
            }
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
}

#Preview {
    ContentView()
}
