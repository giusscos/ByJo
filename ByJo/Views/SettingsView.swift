//
//  SettingsView.swift
//  ByJo
//
//  Created by Giuseppe Cosenza on 04/11/24.
//

import SwiftUI
import StoreKit

struct SettingsView: View {
    @State var manageSubscription: Bool = false
    
    var body: some View {
        List {
            Section {
                Button("Manage subscription") {
                    manageSubscription.toggle()
                }

                Link("Send me a Feedback", destination: URL(string: "mailto:giusscos@icloud.com")!)
                    .foregroundColor(.blue)
                
                Link("Terms of use", destination: URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!)
                    .foregroundColor(.blue)
                
                Link("Privacy Policy", destination: URL(string: "https://giusscos.it/privacy")!)
                    .foregroundColor(.blue)
            } header: {
                Text("Support")
            }
        }.manageSubscriptionsSheet(isPresented: $manageSubscription, subscriptionGroupID: Store().groupId)
    }
}

#Preview {
    SettingsView()
}
