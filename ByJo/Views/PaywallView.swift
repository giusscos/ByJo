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
            title: "Privacy first",
            description: "ByJo do not collect or track any type of data",
            imageName: "lock.shield"
        ),
        (
            title: "Achieve Your Goals",
            description: "Set goals to achieve your financial freedom",
            imageName: "target"
        ),
        (
            title: "Manage Your Assets with ease",
            description: "View, filter and manage your assets in a single place",
            imageName: "book.pages"
        )
    ]
    
    private let slideInterval: TimeInterval = 7
    
    var body: some View {
        NavigationStack {
            SubscriptionStoreView(groupID: Store().groupId) {
                VStack (alignment: .leading) {
                    Button {
                        showLifetimePlans = true
                    } label: {
                        Label("Save with Lifetime plans", systemImage: "sparkle")
                            .font(.headline)
                    }
                    .tint(.green)
                    .buttonStyle(.borderedProminent)
                    .buttonBorderShape(.capsule)
                    .frame(maxWidth: .infinity, alignment: .center)
                    
                    TabView(selection: $currentIndex) {
                        ForEach(0..<contentData.count, id: \.self) { index in
                            VStack(alignment: .leading, spacing: 12) {
                                Image(systemName: contentData[index].imageName)
                                    .font(.largeTitle)
                                    .foregroundStyle(Color.accentColor)
                                
                                Text(contentData[index].title)
                                    .font(.title)
                                    .multilineTextAlignment(.leading)
                                    .bold()
                                
                                Text(contentData[index].description)
                                    .font(.headline)
                                    .foregroundStyle(.secondary)
                                    .multilineTextAlignment(.leading)
                            }
                            .tag(index)
                        }
                    }
                    .tabViewStyle(.page)
                    .indexViewStyle(.page(backgroundDisplayMode: .always))
                    
                    HStack {
                        Spacer()
                        
                        Link("Terms of use", destination: URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!)
                            .foregroundColor(.primary)
                            .buttonStyle(.plain)
                        
                        Text("and")
                            .foregroundStyle(.secondary)
                        
                        Link("Privacy Policy", destination: URL(string: "https://giusscos.it/privacy")!)
                            .foregroundColor(.primary)
                            .buttonStyle(.plain)
                        
                        Spacer()
                    }
                    .font(.caption)
                }
                .padding()
            }
            .subscriptionStoreControlStyle(.pagedProminentPicker, placement: .bottomBar)
            .subscriptionStoreButtonLabel(.multiline)
            .storeButton(.visible, for: .restorePurchases)
            .storeButton(.hidden, for: .cancellation)
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
