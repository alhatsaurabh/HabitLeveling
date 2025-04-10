import Foundation

// MARK: - Stat Types
public enum StatType: String {
    case str = "Strength"
    case agi = "Agility"
    case vit = "Vitality"
    case int = "Intelligence"
    case per = "Perception"
}

// MARK: - Stat Categories
public enum StatCategory: String, CaseIterable, Identifiable {
    case mind = "Mind"
    case body = "Body"
    case skill = "Skill"
    case discipline = "Discipline"
    case wellbeing = "Wellbeing"
    case other = "Other"
    
    public var id: String { self.rawValue }
    
    public func distributeXP(_ xp: Int) -> [StatType: Int] {
        switch self {
        case .mind:
            return [.int: Int(Double(xp) * 0.7), .per: Int(Double(xp) * 0.3)]
        case .body:
            return [.str: Int(Double(xp) * 0.6), .agi: Int(Double(xp) * 0.4)]
        case .skill:
            return [.agi: Int(Double(xp) * 0.8), .int: Int(Double(xp) * 0.2)]
        case .discipline:
            return [.vit: Int(Double(xp) * 0.7), .str: Int(Double(xp) * 0.3)]
        case .wellbeing:
            return [.per: Int(Double(xp) * 0.6), .vit: Int(Double(xp) * 0.4)]
        case .other:
            return [:] // No XP distribution for other category
        }
    }
} 