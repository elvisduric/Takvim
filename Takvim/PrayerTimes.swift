import Foundation
import UserNotifications

// Model to represent prayer times
struct PrayerTimes: Codable {
    let date: String
    let event: String?
    let earlyFajr: String
    let fajr: String
    let dhuhr: String
    let asr: String
    let maghrib: String
    let isha: String
    
    // Computed property to return the formatted date
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        if let date = formatter.date(from: self.date) {
            formatter.dateStyle = .full
            formatter.dateFormat = "EEEE, d MMMM"
            return formatter.string(from: date)
        }
        return self.date
    }
}

// Load all prayer times from the JSON file
func loadPrayerTimes() -> ([PrayerTimes], String?) {
    if let url = Bundle.main.url(forResource: "namaska_vremena", withExtension: "json") {
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            let json = try decoder.decode([String: [PrayerTimes]].self, from: data)
            
            // Combine all prayer times into one array
            let prayerTimesArray = json.values.flatMap { $0 }
            
            return (prayerTimesArray, nil)
        } catch {
            return ([], "Error loading or decoding JSON: \(error)")
        }
    } else {
        return ([], "File not found.")
    }
}

// Load all available dates from prayer times
func loadAvailableDates() -> [Date] {
    let (prayerTimesArray, _) = loadPrayerTimes()
    
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "yyyy-MM-dd"

    // Extract the dates from prayer times
    let dates = prayerTimesArray.compactMap { prayerTime in
        dateFormatter.date(from: prayerTime.date)
    }

    return dates
}

// Load prayer times for a specific date
func loadPrayerTimesForDate(_ formattedDate: String) -> (prayerTimes: PrayerTimes?, errorMessage: String?) {
    let (prayerTimesArray, errorMessage) = loadPrayerTimes()
    
    if let errorMessage = errorMessage {
        return (nil, errorMessage)
    }
    
    if let prayerTimes = prayerTimesArray.first(where: { $0.date == formattedDate }) {
        return (prayerTimes, nil)
    } else {
        return (nil, "No prayer times available for the selected date.")
    }
}

// Get the current prayer time based on the system time
func getCurrentPrayerTime(prayerTimes: PrayerTimes) -> String? {
    let currentTime = Date() // Use the current date and time directly

    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "HH:mm"
    
    let calendar = Calendar.current

    let prayerTimeStrings = [
        ("Rani Sabah", prayerTimes.earlyFajr),
        ("Sabah", prayerTimes.fajr),
        ("Podne", prayerTimes.dhuhr),
        ("Ikindija", prayerTimes.asr),
        ("Akšam", prayerTimes.maghrib),
        ("Jacija", prayerTimes.isha)
    ]
    
    // Convert prayer times to date objects
    var prayerTimesDates: [(String, Date)] = []
    
    for (name, timeString) in prayerTimeStrings {
        if let prayerTime = dateFormatter.date(from: timeString) {
            let prayerDateTime = calendar.date(bySettingHour: calendar.component(.hour, from: prayerTime),
                                               minute: calendar.component(.minute, from: prayerTime),
                                               second: 0, of: currentTime)!
            prayerTimesDates.append((name, prayerDateTime))
        }
    }
    
    guard let jacijaTime = prayerTimesDates.last(where: { $0.0 == "Jacija" })?.1,
          let raniSabahTime = prayerTimesDates.first(where: { $0.0 == "Rani Sabah" })?.1,
          let sabahTime = prayerTimesDates.first(where: { $0.0 == "Sabah" })?.1 else {
        return nil // If any required time is missing, return nil
    }
    
    // Check if it's after "Jacija" and before "Rani Sabah"
    if currentTime >= jacijaTime || currentTime < raniSabahTime {
        return "Jacija" // Keep highlighting Jacija throughout the night
    }
    
    // Check if it's after "Rani Sabah" but before "Sabah"
    if currentTime >= raniSabahTime && currentTime <= sabahTime {
        return "Sabah" // Highlight Sabah once Rani Sabah time is passed
    }

    var lastPrayerName: String? = nil

    // Find the next prayer time
    for (name, prayerTime) in prayerTimesDates {
        if currentTime < prayerTime {
            return lastPrayerName ?? name
        }
        lastPrayerName = name
    }

    return prayerTimesDates.last?.0 // Return the last prayer if no future prayers are found
}


// Load events from the prayer times
func loadEvents() -> [String] {
    let (prayerTimesArray, _) = loadPrayerTimes()
    
    // Extract the non-nil events from the prayer times array
    let events = prayerTimesArray.compactMap { $0.event }
    
    return events
}
