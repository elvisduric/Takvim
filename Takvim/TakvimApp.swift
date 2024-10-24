import SwiftUI
import UserNotifications

@main
struct TakvimApp: App {
    init() {
        UITabBar.appearance().tintColor = UIColor.black
        NotificationsManager.shared.loadNotificationPreferences()
        NotificationsManager.shared.requestNotificationPermission()
        clearPreviousNotificationsIfNeeded() // Clear previous notifications if app is updated
    }

    private func clearPreviousNotificationsIfNeeded() {
        let currentVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
        let previousVersion = UserDefaults.standard.string(forKey: "appVersion")

        if currentVersion != previousVersion {
            UNUserNotificationCenter.current().removeAllPendingNotificationRequests() // Clear all notifications
            UserDefaults.standard.set(currentVersion, forKey: "appVersion") // Update saved version
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
