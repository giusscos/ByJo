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
    enum ActiveSheet: Identifiable {
        case currencyPicker
        case paywall
        
        var id: String {
            switch self {
                case .currencyPicker:
                    return "currencyPicker"
                case .paywall:
                    return "paywall"
            }
        }
    }
    
    @AppStorage("showCurrencyPicker") var showCurrencyPicker: Bool = true
    
    @State var activeSheet: ActiveSheet?
    
    @State var store = Store()
   
    var hasPaid: Bool {
        !store.purchasedSubscriptions.isEmpty || !store.purchasedProducts.isEmpty
    }
    
    var body: some View {
        if store.isLoading {
            ProgressView()
        } else {
            TabView {
                Tab("Home", systemImage: "house.fill") {
                    HomeView()
                }
                
                Tab("Assets", systemImage: "briefcase.fill") {
                    AssetListView()
                }
                
                Tab("Operations", systemImage: "book.pages") {
                    OperationListView()
                }
                
                Tab("Settings", systemImage: "gear") {
                    SettingsView()
                }
            }
            .fullScreenCover(item: $activeSheet, content: { sheet in
                switch sheet {
                    case .currencyPicker:
                        CurrencyPickerView()
                    case .paywall:
                        PaywallView()
                }
            })
            .onChange(of: hasPaid, { _, _ in
                activeSheet = .none
                
                if showCurrencyPicker {
                    activeSheet = .currencyPicker
                }
            })
            .onAppear {
                if hasPaid {
                    if showCurrencyPicker {
                        activeSheet = .currencyPicker
                    }
                    
                    UITextField.appearance().clearButtonMode = .whileEditing
                    
                    return
                }
                
                activeSheet = .paywall
            }
        }
    }
}

#Preview {
    ContentView()
}
