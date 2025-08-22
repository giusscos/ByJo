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
            title: "Privacy first.",
            description: "ByJo do not collect, track or share any type of data.",
            imageName: "lock.fill"
        ),
        (
            title: "Focus on what really matters.",
            description: "Designed with simplicity in mind to help you manage your finances effectively.",
            imageName: "brain.head.profile"
        ),
        (
            title: "Achieve Your Goals.",
            description: "Set goals to achieve your financial freedom.",
            imageName: "target"
        ),
        (
            title: "Manage Your Assets with ease.",
            description: "View, filter and manage all your assets and operations in a single place.",
            imageName: "book.pages"
        )
    ]
    
    private let slideInterval: TimeInterval = 7
    
    var body: some View {
        NavigationStack {
            SubscriptionStoreView(groupID: Store().groupId) {
                VStack (spacing: 16) {
                    Button {
                        showLifetimePlans = true
                    } label: {
                        Label("Save with Lifetime plans", systemImage: "sparkle")
                            .font(.headline)
                    }
                    .tint(.green)
                    .buttonStyle(.borderedProminent)
                    .buttonBorderShape(.capsule)
                    .padding()
                    
                    Spacer()
                    
                    TabView(selection: $currentIndex) {
                        ForEach(0..<contentData.count, id: \.self) { index in
                            VStack(alignment: .center) {
                                Image(systemName: contentData[index].imageName)
                                    .imageScale(.large)
                                    .font(.title)
                                    .foregroundStyle(Color.accentColor)
                                
                                Text(contentData[index].title)
                                    .font(.title)
                                    .fontWeight(.semibold)
                                    .multilineTextAlignment(.center)
                                
                                Text(contentData[index].description)
                                    .font(.title3)
                                    .fontWeight(.medium)
                                    .foregroundStyle(.secondary)
                                    .multilineTextAlignment(.center)
                            }
                            .tag(index)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .center)
                        }
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                    
                    Spacer()
                    
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
                    .padding()
                }
                .frame(maxWidth: 650)
                .frame(minHeight: 300)
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
