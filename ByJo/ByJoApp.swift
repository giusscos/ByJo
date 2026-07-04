//
//  ByJoApp.swift
//  ByJo
//
//  Created by Giuseppe Cosenza on 04/11/24.
//

import SwiftUI
import SwiftData
import TipKit

@main
struct ByJoApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    init() {
        try? Tips.configure([
            .displayFrequency(.immediate),
            .datastoreLocation(.applicationDefault)
        ])
    }

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([Asset.self])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            let container = try ModelContainer(for: schema, configurations: [modelConfiguration])
            container.mainContext.undoManager = UndoManager()
            return container
        } catch {
            // Existing store is incompatible with the new schema (e.g. removed entity).
            // Wipe it and start fresh — acceptable during development.
            let url = modelConfiguration.url
            try? FileManager.default.removeItem(at: url)
            try? FileManager.default.removeItem(at: URL(fileURLWithPath: url.path + "-shm"))
            try? FileManager.default.removeItem(at: URL(fileURLWithPath: url.path + "-wal"))

            do {
                let container = try ModelContainer(for: schema, configurations: [modelConfiguration])
                container.mainContext.undoManager = UndoManager()
                return container
            } catch {
                fatalError("Could not create ModelContainer: \(error)")
            }
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }

    class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
        func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
            UNUserNotificationCenter.current().delegate = self
            clearBadgeCount(application)
            return true
        }

        func applicationDidBecomeActive(_ application: UIApplication) {
            clearBadgeCount(application)
        }

        func clearBadgeCount(_ application: UIApplication) {
            UNUserNotificationCenter.current().setBadgeCount(0) { error in
                if let error = error {
                    print("Error clearing badge count: \(error.localizedDescription)")
                }
            }
        }

        func userNotificationCenter(_ center: UNUserNotificationCenter,
                                    willPresent notification: UNNotification,
                                    withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
            clearBadgeCount(UIApplication.shared)
            completionHandler([.banner, .sound])
        }

        func userNotificationCenter(_ center: UNUserNotificationCenter,
                                    didReceive response: UNNotificationResponse,
                                    withCompletionHandler completionHandler: @escaping () -> Void) {
            clearBadgeCount(UIApplication.shared)
            completionHandler()
        }
    }
}
