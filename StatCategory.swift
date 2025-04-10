import Foundation

// Enum defining the primary stat categories for habits
// Conforms to String to allow storing the raw value in Core Data
// Conforms to CaseIterable to easily get all categories (e.g., for Pickers)
// Conforms to Identifiable to be used directly in SwiftUI ForEach loops
enum StatCategory: String, CaseIterable, Identifiable {
    case mind = "Mind"
    case body = "Body"
    case skill = "Skill"
    case discipline = "Discipline"
    case wellbeing = "Wellbeing"
    case other = "Other"
    
    var id: String { self.rawValue }
    
    func distributeXP(_ xp: Int) -> [String: Int] {
        switch self {
        case .mind:
            return ["int": Int(Double(xp) * 0.7), "per": Int(Double(xp) * 0.3)]
        case .body:
            return ["str": Int(Double(xp) * 0.6), "agi": Int(Double(xp) * 0.4)]
        case .skill:
            return ["agi": Int(Double(xp) * 0.8), "int": Int(Double(xp) * 0.2)]
        case .discipline:
            return ["vit": Int(Double(xp) * 0.7), "str": Int(Double(xp) * 0.3)]
        case .wellbeing:
            return ["per": Int(Double(xp) * 0.6), "vit": Int(Double(xp) * 0.4)]
        case .other:
            return [:] // No XP distribution for other category
        }
    }
} 