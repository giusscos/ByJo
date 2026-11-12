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

    var body: some View {
        Group {
            if !hasCompletedOnboarding {
                OnboardingView(store: store) {
                    hasCompletedOnboarding = true
                }
            } else {
                // The free plan opens the app; Pro features show the paywall when reached.
                mainTabView
            }
        }
        .environment(store)
        // Placed here so the task is always alive regardless of which view is shown.
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

            Tab("Assets", systemImage: "building.columns") {
                AssetListView()
            }

            Tab("Operations", systemImage: "book.pages") {
                OperationListView()
            }

            Tab(role: .search) {
                SearchView()
            }
        }
        // Tab bar on compact width; on regular width (iPhone Duo inner display, iPad)
        // it can expand into a sidebar.
        .tabViewStyle(.sidebarAdaptable)
        .activatesSearchOnTabSelection()
    }
}

private extension View {
    /// Tapping the Search tab opens the search field and the keyboard right away (iOS 26+):
    /// the Search screen has nothing to show until something is typed.
    @ViewBuilder
    func activatesSearchOnTabSelection() -> some View {
        if #available(iOS 26.0, *) {
            tabViewSearchActivation(.searchTabSelection)
        } else {
            self
        }
    }
}

#Preview {
    ContentView()
}
