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
    // Store user's location choice
    @AppStorage("selectedLocation") private var selectedLocation: LocationOption = .drammen
    // State to manage the modal sheet visibility
    @State private var isLocationPickerPresented = false

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Postavke")
                .font(.largeTitle)
                .padding(.bottom, 20)
            
            Text("Lokacija")
                .font(.headline)
            
            // Button to open the modal sheet for location selection
            Button(action: {
                isLocationPickerPresented.toggle()
            }) {
                HStack {
                    Text("Izaberite lokaciju")
                    Spacer()
                    Text(selectedLocation.rawValue)
                        .foregroundColor(.blue)
                }
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(8)
            .sheet(isPresented: $isLocationPickerPresented) {
                LocationSelectionView(selectedLocation: $selectedLocation)
            }
            
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

// Separate view for location selection
struct LocationSelectionView: View {
    @Binding var selectedLocation: LocationOption
    @Environment(\.dismiss) var dismiss // Use SwiftUI dismiss environment

    var body: some View {
        NavigationView {
            List {
                ForEach(LocationOption.allCases) { location in
                    HStack {
                        Text(location.rawValue)
                        Spacer()
                        if selectedLocation == location {
                            Image(systemName: "checkmark")
                                .foregroundColor(.blue)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedLocation = location
                        dismiss() // SwiftUI dismiss call
                    }
                }
            }
            .navigationTitle("Izaberite lokaciju")
            .navigationBarItems(trailing: Button("Zatvori") {
                dismiss() // Dismiss on button tap
            })
        }
    }
}

enum LocationOption: String, CaseIterable, Identifiable {
    case drammen = "Drammen"
    case oslo = "Oslo"
    case ostfold = "Østfold"
    case skien = "Skien"
    var id: String { self.rawValue }
}

// Function to trigger haptic feedback
func triggerHapticFeedback(style: UIImpactFeedbackGenerator.FeedbackStyle) {
    let impactFeedback = UIImpactFeedbackGenerator(style: style)
    impactFeedback.impactOccurred()
}
