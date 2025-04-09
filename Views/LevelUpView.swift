// MARK: - File: LevelUpView.swift (Placeholder)
// Purpose: Placeholder view for the level up overlay animation/notification.
// Dependencies: ThemeColors

import SwiftUI

struct LevelUpView: View {
    // Accepts the level passed from DashboardView
    let level: Int

    var body: some View {
        VStack(spacing: 15) {
            Image(systemName: "star.fill") // Example icon
                .font(.system(size: 60))
                .foregroundColor(ThemeColors.tertiaryAccent) // Gold color

            Text("LEVEL UP!")
                .font(.largeTitle)
                .fontWeight(.heavy)
                .foregroundColor(ThemeColors.primaryText)

            Text("You reached Level \(level)!")
                .font(.title2)
                .foregroundColor(ThemeColors.secondaryText)
        }
        .padding(30)
        .background(Material.ultraThinMaterial) // Use a material background for overlay effect
        .background(ThemeColors.panelBackground.opacity(0.8)) // Use ThemeColors with opacity
        .cornerRadius(15)
        .shadow(color: ThemeColors.glowColor.opacity(0.5), radius: 10) // Use ThemeColors
        // Note: Ensure ThemeColors is globally accessible or imported
    }
}

// MARK: - Preview (Optional)
struct LevelUpView_Previews: PreviewProvider {
     // Mock ThemeColors for preview if needed
    struct PreviewThemeColors { static let background = Color.black; static let primaryText = Color.white; static let secondaryText = Color.gray; static let panelBackground = Color.gray.opacity(0.2); static let glowColor = Color.cyan.opacity(0.5); static let tertiaryAccent = Color.yellow }
    static let ThemeColors = PreviewThemeColors.self

    static var previews: some View {
        LevelUpView(level: 10)
            .padding()
            .background(PreviewThemeColors.background) // Use Preview ThemeColors
            .preferredColorScheme(.dark)
    }
}
