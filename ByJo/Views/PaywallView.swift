//
//  PaywallView.swift
//  ByJo
//
//  Created by Giuseppe Cosenza on 28/07/25.
//

import StoreKit
import SwiftUI

struct PaywallView: View {
    @State private var currentIndex: Int = 0
    @State private var timer: Timer? = nil
    
    @State private var showLifetimePlans: Bool = false
    
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
        NavigationStack {
            SubscriptionStoreView(groupID: Store().groupId) {
                VStack {
                    Button {
                        showLifetimePlans = true
                    } label: {
                        Label("Save with Lifetime plans", systemImage: "sparkle")
                            .font(.headline)
                    }
                    .tint(.green)
                    .buttonStyle(.borderedProminent)
                    .buttonBorderShape(.capsule)
                    
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
                    
                    HStack {
                        Link("Terms of use", destination: URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!)
                            .foregroundColor(.primary)
                            .buttonStyle(.plain)
                        
                        Text("and")
                            .foregroundStyle(.secondary)
                        
                        Link("Privacy Policy", destination: URL(string: "https://giusscos.it/privacy")!)
                            .foregroundColor(.primary)
                            .buttonStyle(.plain)
                    }
                    .font(.caption)
                }
            }
            .subscriptionStoreControlStyle(.pagedProminentPicker, placement: .bottomBar)
            .subscriptionStoreButtonLabel(.multiline)
            .storeButton(.visible, for: .restorePurchases)
            .interactiveDismissDisabled()
            .sheet(isPresented: $showLifetimePlans) {
                PaywallLifetimeView()
                    .presentationDetents(.init([.medium]))
            }
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
    PaywallView()
}
