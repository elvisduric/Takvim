import SwiftUI

struct CalendarView: View {
    @Binding var isPresented: Bool
    @Binding var selectedDate: Date // Binding to the selected date
    @State var groupedDates: [String: [Date]] = [:] // Dictionary to hold dates grouped by month and year

    let columns: [GridItem] = Array(repeating: .init(.flexible()), count: 7) // 7 columns for days of the week
    let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = Locale(identifier: "bs_BA")
        calendar.timeZone = TimeZone.current
        return calendar
    }()

    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                Spacer(minLength: 50) // Adds space at the top
                ScrollView(.vertical, showsIndicators: false) {
                    LazyVStack {
                        ForEach(groupedDates.keys.sorted(by: >), id: \.self) { monthYear in
                            Section(header: Text(monthYear).font(.system(size: 30, weight: .bold)).padding()) {
                                LazyVGrid(columns: columns, spacing: 20) {
                                    ForEach(bosnianWeekdaySymbols(), id: \.self) { day in
                                        Text(day)
                                            .font(.headline)
                                            .frame(maxWidth: .infinity)
                                    }
                                }
                                LazyVGrid(columns: columns, spacing: 15) {
                                    let dates = groupedDates[monthYear]!
                                    let firstWeekdayIndex = (calendar.component(.weekday, from: dates.first!) + 5) % 7

                                    ForEach(0..<firstWeekdayIndex, id: \.self) { _ in
                                        Text("") // Empty cells to align dates
                                    }

                                    ForEach(dates, id: \.self) { date in
                                        let dayNumber = calendar.component(.day, from: date)
                                        let isFriday = calendar.component(.weekday, from: date) == 6 // 1 = Sunday, ..., 6 = Friday
                                        let isToday = calendar.isDateInToday(date) // Check if it's today

                                        Text("\(dayNumber)")
                                            .frame(maxWidth: .infinity)
                                            .font(.system(size: 19, weight: isToday ? .bold : .regular))
                                            .background(isToday ? Color.blue.opacity(0.2) : Color.clear)
                                            .foregroundColor(isFriday ? Color(red: 0.0, green: 0.39, blue: 0.0) : .black) // Green if Friday
                                            .onTapGesture {
                                                // Set the selected date when tapped
                                                selectedDate = calendar.date(bySettingHour: 12, minute: 0, second: 0, of: date)!
                                                isPresented = false // Close the calendar after selecting a date
                                            }
                                    }
                                }
                            }
                        }
                    }
                    .frame(width: geometry.size.width * 0.8) // 80% of screen width
                }

                Button("Close") {
                    isPresented = false
                }
                .padding()
                .font(.system(size: 20, weight: .regular))
                .foregroundColor(.red)
            }
            .frame(width: geometry.size.width) // Full width of the screen
            .frame(height: geometry.size.height, alignment: .top) // This ensures the VStack takes full height and aligns to top
        }
        .ignoresSafeArea(.all, edges: .top) // This ignores the safe area at the top
        .onAppear {
            groupDatesByMonth()
        }
    }
    
    // Function to group dates by month and year
    func groupDatesByMonth() {
        let dates = loadAvailableDates() // Load dates from PrayerTimes.swift
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMMM yyyy" // Format for month and year (e.g., "October 2024")

        // Create a dictionary where keys are month-year strings and values are arrays of dates
        groupedDates = Dictionary(grouping: dates) { date -> String in
            dateFormatter.string(from: date) // Group by formatted month and year
        }
    }

    // Function to get weekday symbols in Bosnian, starting with Monday
    func bosnianWeekdaySymbols() -> [String] {
        let symbols = calendar.shortWeekdaySymbols
        return Array(symbols[1...]) + [symbols[0]]  // Move Sunday to the end
    }
}
