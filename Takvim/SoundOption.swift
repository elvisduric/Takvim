//
//  SoundOption.swift
//  Takvim
//
//  Created by Elvis Duric on 24. 10. 2024..
//


import Foundation

enum SoundOption: String, CaseIterable, Identifiable {
    case defaultSound = "Standardno" // Default sound option
    case customSound = "Ezan" // Custom sound option
    
    var id: String { self.rawValue }
}
