//
//  ContentView.swift
//  ByJo
//
//  Created by Giuseppe Cosenza on 04/11/24.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @AppStorage("hasCompletedOnboarding") var hasCompletedOnboarding: Bool = false

    @State var store = Store()

    private var hasPaid: Bool {
        !store.purchasedSubscriptions.isEmpty || !store.purchasedProducts.isEmpty
    }

    var body: some View {
        Group {
            if store.isLoading {
                ProgressView()
            } else if !hasPaid {
                if !hasCompletedOnboarding {
                    OnboardingView {
                        hasCompletedOnboarding = true
                    }
                } else {
                    PaywallView(store: store)
                }
            } else {
                mainTabView
            }
        }
        // Placed here so the task is always alive regardless of which view is shown.
        // Previously it was inside PaywallView, which caused a race: the task was
        // cancelled mid-flight when hasPaid flipped and the view was torn down.
        .subscriptionStatusTask(for: store.groupId) { taskState in
            guard let statuses = taskState.value else { return }
            await store.updateSubscriptionStatus(statuses: statuses)
        }
        .onAppear {
            UITextField.appearance().clearButtonMode = .whileEditing
        }
    }

    private var mainTabView: some View {
        TabView {
            Tab("Home", systemImage: "house.fill") {
                HomeView()
            }

            Tab("Assets", systemImage: "banknote.fill") {
                AssetListView()
            }

            Tab("Operations", systemImage: "book.pages") {
                OperationListView()
            }

            Tab(role: .search) {
                SearchView()
            }
        }
    }
}

#Preview {
    ContentView()
}
