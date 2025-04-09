// MARK: - File: HabitTemplate.swift
// Purpose: Defines the structure for a predefined habit template.

import Foundation
import SwiftUI // Needed for Color if we add it later

// Struct to represent a predefined habit template
struct HabitTemplate: Identifiable, Hashable {
    let id = UUID() // Make it identifiable for lists
    let name: String
    let description: String? // Optional description
    let category: StatCategory // The underlying category
    let xpValue: Int64
    let frequency: String // e.g., "Daily", "Weekly"
    // Optional: Add default icon, color, etc. later if needed
    // let iconName: String?
    // let color: Color?

    // Hashable conformance (based on id)
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    static func == (lhs: HabitTemplate, rhs: HabitTemplate) -> Bool {
        lhs.id == rhs.id
    }
}
