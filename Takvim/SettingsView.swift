//
//  SettingsView.swift
//  Takvim
//
//  Created by Elvis Duric on 24. 10. 2024..
//


import SwiftUI

struct SettingsView: View {
    // Store user's sound choice using @AppStorage to persist the choice
    @AppStorage("notificationSound") private var selectedSound: SoundOption = .customSound // Ezan as default option

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Postavke")
                .font(.largeTitle)
                .padding(.bottom, 20)
            
            Text("Zvuk notifikacije")
                .font(.headline)
            
            // Picker for selecting notification sound
            Picker("Izaberite zvuk notifikacije", selection: $selectedSound) {
                ForEach(SoundOption.allCases) { option in
                    Text(option.rawValue).tag(option)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .onChange(of: selectedSound) { oldValue, newValue in
                            triggerHapticFeedback(style: .heavy)
                        }
            Spacer()
        }
        .padding()
    }
}

// Function to trigger haptic feedback
func triggerHapticFeedback(style: UIImpactFeedbackGenerator.FeedbackStyle) {
    let impactFeedback = UIImpactFeedbackGenerator(style: style)
    impactFeedback.impactOccurred()
}
