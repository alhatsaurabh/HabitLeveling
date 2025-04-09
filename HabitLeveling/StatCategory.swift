import Foundation

// Enum defining the five core stat categories for habits
// Conforms to String to allow storing the raw value in Core Data
// Conforms to CaseIterable to easily get all categories (e.g., for Pickers)
// Conforms to Identifiable to be used directly in SwiftUI ForEach loops

enum StatCategory: String, CaseIterable, Identifiable {
    case mind = "Mind"
    case body = "Body"
    case skill = "Skill"
    case discipline = "Discipline"
    case wellbeing = "Wellbeing"
    case other = "Other" // <-- ADD THIS LINE

    var id: String { self.rawValue }
}
