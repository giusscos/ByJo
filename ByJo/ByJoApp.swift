//
//  ByJoApp.swift
//  ByJo
//
//  Created by Giuseppe Cosenza on 04/11/24.
//

import SwiftUI
import SwiftData

@main
struct ByJoApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([Asset.self])
        
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        
        do {
            let container = try ModelContainer(for: schema, configurations: [modelConfiguration])
            container.mainContext.undoManager = UndoManager()
            
            return container
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
    
    class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
        // Request and subscribe to remote notifications
        func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
            let center = UNUserNotificationCenter.current()
            center.delegate = self
            center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
                if granted {
                    DispatchQueue.main.async {
                        application.registerForRemoteNotifications()
                        // Clear badge on launch
                        self.clearBadgeCount(application)
                    }
                } else {
                    print("Error permission notification: \(error?.localizedDescription ?? "unkwon error")")
                }
            }
            
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
        
        func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
            print("Error registering for remote notifications: \(error.localizedDescription)")
        }
        
        // Handle incoming notifications (app in foreground)
        func userNotificationCenter(_ center: UNUserNotificationCenter,
                                    willPresent notification: UNNotification,
                                    withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
            // Clear badge when receiving notification in foreground
            clearBadgeCount(UIApplication.shared)
            completionHandler([.banner, .sound])
        }
        
        // Handle notification response when user taps the notification
        func userNotificationCenter(_ center: UNUserNotificationCenter,
                                    didReceive response: UNNotificationResponse,
                                    withCompletionHandler completionHandler: @escaping () -> Void) {
            // Clear badge when user taps notification
            clearBadgeCount(UIApplication.shared)
            completionHandler()
        }
    }
}
