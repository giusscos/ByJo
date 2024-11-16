//
//  SettingsView.swift
//  ByJo
//
//  Created by Giuseppe Cosenza on 04/11/24.
//

import SwiftUI

struct SettingsView: View {
    @State var manageSubscription: Bool = false
    
    var body: some View {
        List {
            Section {
                Button("Manage subscription") {
                    manageSubscription.toggle()
                }
                
                Link("Terms of use", destination: URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!)
                    .font(.headline)
                    .foregroundColor(.blue)
                
                Link("Privacy Policy", destination: URL(string: "https://giusscos.it/privacy")!)
                    .font(.headline)
                    .foregroundColor(.blue)
            } header: {
                Text("Support")
            }
        }
    }
}

#Preview {
    SettingsView()
}
