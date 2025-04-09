import SwiftUI

// Centralized definition for theme colors
struct ThemeColors {
    // Define base colors inspired by Solo Leveling UI (adjust hex values as needed)
    // Using Color(hex:) initializer (requires extension below)

    // Backgrounds
    static let background = Color(hex: "0A0A10") // Very dark, almost black with a hint of blue/purple
    static let panelBackground = Color(hex: "1B1A2E").opacity(0.65) // Dark purple/blue, semi-transparent panel

    // Accents & Glows (Key Solo Leveling Colors)
    static let primaryAccent = Color(hex: "7B68EE") // Medium Slate Blue / Vibrant Purple (Adjust!)
    static let secondaryAccent = Color(hex: "00BFFF") // Deep Sky Blue / Mana Blue (Adjust!)
    static let tertiaryAccent = Color(hex: "FFD700") // Gold - For highlights, Rank S, important items

    static let glowColor = Color(hex: "7B68EE").opacity(0.8) // Slightly stronger glow color
    static let borderColor = Color(hex: "7B68EE").opacity(0.7) // Border matching primary accent

    // Text Colors
    static let primaryText = Color.white.opacity(0.9)
    static let secondaryText = Color(hex: "A0A0B0") // Light grayish-blue/purple tint
    static let tertiaryText = Color(hex: "5A5A7A") // Darker grayish-blue/purple tint

    // Status Colors
    static let success = Color(hex: "32CD32") // Lime Green
    static let warning = Color(hex: "FFA500") // Orange
    static let danger = Color(hex: "FF4500") // OrangeRed

    // Other UI Elements
    static let placeholder = Color(hex: "5A5A7A") // Use tertiary text color for placeholders

    // Stat Colors
    static let strengthStat = Color(hex: "E53E3E") // Red for Strength
    static let vitalityStat = Color(hex: "48BB78") // Green for Vitality
    static let agilityStat = Color(hex: "4299E1") // Blue for Agility
    static let intelligenceStat = Color(hex: "9F7AEA") // Purple for Intelligence
    static let perceptionStat = Color(hex: "ED8936") // Orange for Perception

    // Gradient Button Colors (Using primary/secondary accents)
    static let gradientStart = secondaryAccent // Mana Blue
    static let gradientEnd = primaryAccent   // Vibrant Purple
}

// Helper extension to initialize Color from HEX strings
// Source: (Adapted from various online sources, e.g., HackingWithSwift)
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default: (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(.sRGB, red: Double(r) / 255, green: Double(g) / 255, blue: Double(b) / 255, opacity: Double(a) / 255)
    }
}
