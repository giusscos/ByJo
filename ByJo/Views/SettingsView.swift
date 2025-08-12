//
//  SettingsView.swift
//  ByJo
//
//  Created by Giuseppe Cosenza on 04/11/24.
//

import SwiftUI
import StoreKit
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    
    @AppStorage("currencyCode") var currency: CurrencyCode = .usd
    
    @State private var manageSubscription: Bool = false
    
    var body: some View {
        NavigationStack {
            List {
                Section("Currency") {
                    Picker("Currency", selection: $currency) {
                        ForEach(CurrencyCode.allCases, id: \.self) { value in
                            Text(value.rawValue)
                        }
                    }
                }
                
                Section("Support") {
                    Button("Manage subscription") {
                        manageSubscription.toggle()
                    }
                    
                    Link("Send me a Feedback", destination: URL(string: "mailto:hellos@giusscos.com")!)
                        .foregroundColor(.blue)
                    
                    Link("Terms of use", destination: URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!)
                        .foregroundColor(.blue)
                    
                    Link("Privacy Policy", destination: URL(string: "https://giusscos.it/privacy")!)
                        .foregroundColor(.blue)
                }
            }
            .manageSubscriptionsSheet(isPresented: $manageSubscription, subscriptionGroupID: Store().groupId)
        }
    }
}

#Preview {
    SettingsView()
}
