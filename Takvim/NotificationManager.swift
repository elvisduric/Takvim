import Foundation
import UserNotifications
import UIKit

class NotificationsManager {
    static let shared = NotificationsManager()

    // Dictionary to track notifications for each prayer time
    var notificationEnabled: [String: Bool] = [
        "Ranog Sabah": false,
        "Sabah": false,
        "Podne": false,
        "Ikindija": false,
        "Akšam": false,
        "Jacija": false
    ]

    // Store notification preferences in UserDefaults
    func saveNotificationPreferences() {
        UserDefaults.standard.set(notificationEnabled, forKey: "notificationEnabled")
    }

    // Load notification preferences from UserDefaults
    func loadNotificationPreferences() {
        if let savedPreferences = UserDefaults.standard.dictionary(forKey: "notificationEnabled") as? [String: Bool] {
            notificationEnabled = savedPreferences
        }
    }

    // Request notification permission
    func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { (granted, error) in
            if let error = error {
                print("Error requesting notification permission: \(error.localizedDescription)")
            }
            if granted {
                print("Notification permission granted")
            } else {
                print("Notification permission denied")
            }
        }
    }

    // Schedule notifications for each prayer time
    func scheduleNotifications(for prayerTimes: PrayerTimes) {
        let center = UNUserNotificationCenter.current()
        
        let prayerTimeDetails = [
            ("Ranog Sabah", prayerTimes.earlyFajr),
            ("Sabah", prayerTimes.fajr),
            ("Podne", prayerTimes.dhuhr),
            ("Ikindija", prayerTimes.asr),
            ("Akšam", prayerTimes.maghrib),
            ("Jacija", prayerTimes.isha)
        ]
        
        for (title, time) in prayerTimeDetails {
            if notificationEnabled[title] == true {
                scheduleNotification(center: center, title: title, time: time)
            }
        }
    }

    // Toggle notifications
    func toggleNotification(for title: String, time: String) {
        // Toggle the notification state
        notificationEnabled[title]?.toggle()
        
        if notificationEnabled[title] == true {
            scheduleNotification(center: UNUserNotificationCenter.current(), title: title, time: time)
            triggerHapticFeedback(style: .heavy)
        } else {
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["\(title)-notification"])
            triggerHapticFeedback(style: .heavy)
        }
        
        // Save the notification state after toggling
        saveNotificationPreferences()
    }

    // Function to trigger haptic feedback
    func triggerHapticFeedback(style: UIImpactFeedbackGenerator.FeedbackStyle) {
        let impactFeedback = UIImpactFeedbackGenerator(style: style)
        impactFeedback.impactOccurred()
    }


    // Schedule a local notification
    private func scheduleNotification(center: UNUserNotificationCenter, title: String, time: String) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm"
        
        guard let prayerDate = dateFormatter.date(from: time) else { return }
        
        var dateComponents = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: Date())
        let prayerComponents = Calendar.current.dateComponents([.hour, .minute], from: prayerDate)
        dateComponents.hour = prayerComponents.hour
        dateComponents.minute = prayerComponents.minute
        
        // Adjust dateComponents to the next occurrence of the prayer time
        let now = Date()
        if let prayerDateTime = Calendar.current.date(from: dateComponents), prayerDateTime <= now {
            dateComponents.day! += 1 // Move to the next day
        }
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
        
        let content = UNMutableNotificationContent()
        content.title = "Takvim"
        content.body = "Nastupilo je vrijeme \(title) namaza"
        
        // Retrieve the selected sound from UserDefaults
        let selectedSoundName = UserDefaults.standard.string(forKey: "notificationSound") ?? SoundOption.customSound.rawValue
        print("Selected sound: \(selectedSoundName)")
        
        // Set the sound for the notification
        if selectedSoundName == SoundOption.customSound.rawValue {
            content.sound = UNNotificationSound(named: UNNotificationSoundName(rawValue: "ezan.wav")) // Use custom sound without the extension
        } else {
            content.sound = UNNotificationSound.default // Use the default sound
        }
        
        // Add the notification icon attachment
        if let iconURL = Bundle.main.url(forResource: "MessageIcon", withExtension: "png") {
            do {
                let attachment = try UNNotificationAttachment(identifier: "icon", url: iconURL, options: nil)
                content.attachments = [attachment]
            } catch {
                print("Error adding attachment: \(error.localizedDescription)")
            }
        }
        
        let request = UNNotificationRequest(identifier: "\(title)-notification", content: content, trigger: trigger)
        
        center.add(request) { error in
            if let error = error {
                print("Error adding notification: \(error.localizedDescription)")
            }
        }
    }
}
