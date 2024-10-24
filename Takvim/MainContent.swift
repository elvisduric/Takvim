//
//  MainContent.swift
//  Takvim
//
//  Created by Elvis Duric on 24. 10. 2024..
//


import SwiftUI
import UserNotifications

struct MainContent: View {
    @State var errorMessage: String? = nil
    @State var prayerTimes: PrayerTimes? = nil
    @State var currentDate = Date() // Track the current date
    @State var notificationEnabled: [String: Bool] = [:]
    @State private var permissionRequested: Bool = false
    @State private var isHijriDisplayed: Bool = false
    @State private var isCalendarPresented: Bool = false
    @State private var selectedDate = Date()
    @Environment(\.scenePhase) private var scenePhase

    // Computed property for current year
    var currentSystemYear: String {
        let calendar = Calendar.current
        let year = calendar.component(.year, from: currentDate)
        return "\(year)"
    }

    var body: some View {
        VStack {
            // Header section showing time and countdown
            VStack(alignment: .center) {
                if let prayerTimes = prayerTimes {
                    Text("Takvim \(currentSystemYear)")
                        .font(.title)
                        .bold()

                    HStack {
                        Image(systemName: "location.fill")
                        Text("Drammen, Norway")
                    }
                    .font(.title3)
                    .foregroundColor(.white)
                    .padding(.top, 10)

                    Spacer()
                } else if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                } else {
                    Text("Loading prayer times...")
                }
            }
            .padding(.vertical, 20)
            .background(Color.clear)
            .foregroundColor(.white)
            .cornerRadius(15)

            Spacer() // Spacer to push the content above upwards

            // Prayer times section fixed at the bottom
            VStack(alignment: .leading, spacing: 10) {
                if let prayerTimes = prayerTimes {
                    HStack {
                        Button(action: {
                            changeDate(by: -1) // Go to previous day
                        }) {
                            Image(systemName: "chevron.left")
                                .font(.title2)
                                .foregroundColor(.gray)
                                .fontWeight(.regular)
                                .bold()
                        }
                        Spacer()

                        VStack {
                            Spacer() // Push content down if there's no event
                            
                            VStack { // Stack the date and event vertically
                                // Display the formatted date based on the current state
                                Text(isHijriDisplayed ? hijriDate : formattedGregorianDate)
                                    .font(.system(size: 30, weight: .regular)) // Adjust font size and weight
                                    .padding(.top, 0)
                                    .foregroundColor(.gray)
                                    .frame(maxWidth: .infinity)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.75) // Adjust minimum scale factor
                                    .gesture(
                                        DragGesture()
                                            .onEnded { value in
                                                // Check if the vertical movement is greater than the horizontal movement
                                                if abs(value.translation.height) > abs(value.translation.width) {
                                                    withAnimation { // Animate the transition
                                                        isHijriDisplayed.toggle() // Toggle the displayed date
                                                    }
                                                }
                                            }
                                        )
                                    .simultaneousGesture(
                                        TapGesture()
                                            .onEnded {
                                                isCalendarPresented = true
                                            }
                                    )
                                    .fullScreenCover(isPresented: $isCalendarPresented) {
                                        CalendarView(isPresented: $isCalendarPresented, selectedDate: $selectedDate, showCloseButton: true) // Pass the selectedDate
                                            .onDisappear {
                                                changeDate(by: Calendar.current.dateComponents([.day], from: currentDate, to: selectedDate).day ?? 0)
                                            }
                                    }

                                // Display the event below the date if available
                                if let event = prayerTimes.event {
                                    Text(event)
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                }
                            }

                            if prayerTimes.event == nil {
                                Spacer() // Add spacing to vertically center the date if no event
                            }
                        }

                        Spacer()

                        Button(action: {
                            changeDate(by: 1) // Go to next day
                        }) {
                            Image(systemName: "chevron.right")
                                .font(.title2)
                                .fontWeight(.regular)
                                .foregroundColor(.gray)
                                .bold()
                        }
                    }
                    .padding(.horizontal, 5)
                    Divider()

                    // Prayer times
                    Group {
                        prayerTimeRow(title: "Sabah", time: prayerTimes.fajr, earlyTime: prayerTimes.earlyFajr) // Pass the early Fajr time
                        prayerTimeRow(title: "Podne", time: prayerTimes.dhuhr)
                        prayerTimeRow(title: "Ikindija", time: prayerTimes.asr)
                        prayerTimeRow(title: "Akšam", time: prayerTimes.maghrib)
                        prayerTimeRow(title: "Jacija", time: prayerTimes.isha)
                    }

                    // Sellam message
                    HStack {
                        Spacer()
                        VStack {
                            Text("I sve dok si živ, Gospodaru svome se klanjaj!")
                                .multilineTextAlignment(.center)
                                .frame(maxWidth: .infinity, alignment: .top) // Ensure it's aligned to the top
                                .fixedSize(horizontal: false, vertical: true)
                                .foregroundColor(.gray)
                                .font(.custom("Helvetica", size: 16))
                                .fontWeight(.thin)
                            Spacer() // Pushes the content to the top
                        }
                        Spacer()
                    }
                    .padding(.vertical, 0)
                } else {
                    Text("Loading prayer times...")
                }
            }
            .padding()
            .background(Color.clear)
            .foregroundColor(.black)
            .background(RoundedCorners(color: .white, tl: 20, tr: 20, bl: 0, br: 0))
            .shadow(radius: 0)
            .font(.custom("Helvetica", size: 25))
            .padding(.bottom, 43)
        }
        .padding(.horizontal, 0)
        .padding(.bottom, 0)
        .background(Image("background_takvim")
            .resizable()
            .scaledToFill()
            .ignoresSafeArea())
        .edgesIgnoringSafeArea(.bottom)
        .onAppear {
            loadPrayerTimes(for: currentDate)
            loadNotificationStates() // Load notification states on appear
        }
        .onChange(of: scenePhase) { oldPhase, newPhase in
            if newPhase == .active {
                refreshAppState()
            }
        }
    }

    // Computed property for Hijri date
    var hijriDate: String {
        let islamicCalendar = Calendar(identifier: .islamic)
        let formatter = DateFormatter()
        formatter.calendar = islamicCalendar
        formatter.dateFormat = "yyyy MMMM dd" // Format for Hijri date
        return formatter.string(from: currentDate)
    }

    // Computed property for formatted Gregorian date always in Bosnian
    var formattedGregorianDate: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "bs_BA") // Always use Bosnian
        formatter.dateFormat = "EEEE, d MMMM"
        let formattedString = formatter.string(from: currentDate)
        // Capitalize the first letter
        return formattedString.prefix(1).uppercased() + formattedString.dropFirst()
    }

    // Helper function to create prayer time rows with two time columns
    private func prayerTimeRow(title: String, time: String, earlyTime: String? = nil) -> some View {
        return HStack {
            Text(title)
                .font(.system(size: 25, weight: .medium, design: .default)) // Adjust font size and weight
            Spacer()

            // Display early Fajr time if provided, reusing notification logic
            if let earlyTime = earlyTime {
                // Tappable text for early Fajr time
                Text(earlyTime + " -")
                    .font(.system(size: 25, weight: .medium)) // Adjust font size for early time
                    .foregroundColor(notificationEnabled["Ranog \(title)"] == true ? .black : .gray) // Change color based on notification state
                    .onTapGesture {
                        handleNotification(for: "Ranog \(title)", time: earlyTime)
                    }
            }

            // Display current prayer time
            Text(time)
                .font(.system(size: 25, weight: .medium)) // Adjust font size and weight

            // Bell icon for main prayer time notifications
            Button(action: {
                handleNotification(for: title, time: time)
            }) {
                Image(systemName: notificationEnabled[title] == true ? "bell.fill" : "bell.slash.fill")
                    .font(.title2)
                    .foregroundColor(notificationEnabled[title] == true ? .black : .gray)
            }
            .buttonStyle(PlainButtonStyle()) // Prevent button from having default styling
        }
        .padding()
        .background(currentPrayer == title ? Color(red: 0.16, green: 0.54, blue: 0.52).opacity(0.10) : Color.clear)
        .cornerRadius(10)
        .frame(maxWidth: .infinity)
    }

    // Helper function to handle notification toggling logic
    private func handleNotification(for title: String, time: String) {
        // Request permission if not already requested
        if !permissionRequested {
            permissionRequested = true // Mark permission as requested
        }

        NotificationsManager.shared.toggleNotification(for: title, time: time)
        notificationEnabled[title] = !(notificationEnabled[title] ?? false)

        // Save the notification state
        saveNotificationState()
    }
    
    // Computed property for current prayer
    var currentPrayer: String? {
        guard let prayerTimes = prayerTimes else { return nil }
        let prayer = getCurrentPrayerTime(prayerTimes: prayerTimes)
        return prayer
    }

    // Helper to change the date by days (negative for previous, positive for next)
    func changeDate(by days: Int) {
        let newDate = Calendar.current.date(byAdding: .day, value: days, to: currentDate)!
        
        // Check if prayer times are available for the new date
        if arePrayerTimesAvailable(for: newDate) {
            currentDate = newDate
            loadPrayerTimes(for: currentDate)
        } else {
            // Do nothing if there are no prayer times for the new date
            print("No prayer times available for the date \(newDate)")
        }
    }
    
    // Helper function to check if prayer times are available for a specific date
    func arePrayerTimesAvailable(for date: Date) -> Bool {
        let formattedDate = formatDate(date)
        let result = loadPrayerTimesForDate(formattedDate) // Adjust this to your actual loading method
        return result.prayerTimes != nil // Return true if prayer times exist, false otherwise
    }

    // Helper to format the date
    func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }

    // Function to load prayer times for a specific date
    func loadPrayerTimes(for date: Date) {
        let formattedDate = formatDate(date)
        let result = loadPrayerTimesForDate(formattedDate)
        self.prayerTimes = result.prayerTimes
        self.errorMessage = result.errorMessage

        // Schedule notifications for prayer times if they are loaded successfully
        if let prayerTimes = self.prayerTimes {
            NotificationsManager.shared.scheduleNotifications(for: prayerTimes)
        }
    }
    
    private func refreshAppState() {
        loadPrayerTimes(for: Date())
        currentDate = Date()
    }

    // Function to load the notification state
    private func loadNotificationStates() {
        let titles = ["Ranog Sabah", "Sabah", "Podne", "Ikindija", "Akšam", "Jacija"]
        for title in titles {
            notificationEnabled[title] = UserDefaults.standard.bool(forKey: title)
        }
    }

    // Function to save the notification state
    private func saveNotificationState() {
        let titles = ["Ranog Sabah", "Sabah", "Podne", "Ikindija", "Akšam", "Jacija"]
        for title in titles {
            UserDefaults.standard.set(notificationEnabled[title] ?? false, forKey: title)
        }
    }
}
