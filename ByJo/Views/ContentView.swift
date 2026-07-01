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
        case onboarding
        case currencyPicker
        case paywall

        var id: String {
            switch self {
            case .onboarding: return "onboarding"
            case .currencyPicker: return "currencyPicker"
            case .paywall: return "paywall"
            }
        }
    }

    @AppStorage("showCurrencyPicker") var showCurrencyPicker: Bool = true
    @AppStorage("hasCompletedOnboarding") var hasCompletedOnboarding: Bool = false

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
            }
            .fullScreenCover(item: $activeSheet, content: { sheet in
                switch sheet {
                case .onboarding:
                    OnboardingView {
                        hasCompletedOnboarding = true
                        activeSheet = .paywall
                    }
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
                UITextField.appearance().clearButtonMode = .whileEditing

                if hasPaid {
                    if showCurrencyPicker {
                        activeSheet = .currencyPicker
                    }
                    return
                }

                activeSheet = hasCompletedOnboarding ? .paywall : .onboarding
            }
        }
    }
}

#Preview {
    ContentView()
}
