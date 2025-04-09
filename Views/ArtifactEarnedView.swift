// MARK: - File: ArtifactEarnedView.swift (Placeholder)
// Purpose: Placeholder view for the artifact earned overlay notification.
// Dependencies: ThemeColors

import SwiftUI

struct ArtifactEarnedView: View {
    // Accepts the artifact name passed from DashboardView
    let artifactName: String

    var body: some View {
        VStack(spacing: 15) {
            Image(systemName: "shield.lefthalf.filled") // Example icon
                .font(.system(size: 50))
                .foregroundColor(ThemeColors.primaryAccent) // Use ThemeColors

            Text("Artifact Acquired!")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(ThemeColors.primaryText)

            Text(artifactName)
                .font(.title3)
                .fontWeight(.medium)
                .foregroundColor(ThemeColors.secondaryText)
                .multilineTextAlignment(.center)

        }
        .padding(30)
        .background(Material.ultraThinMaterial) // Use a material background for overlay effect
        .background(ThemeColors.panelBackground.opacity(0.8)) // Use ThemeColors with opacity
        .cornerRadius(15)
        .shadow(color: ThemeColors.glowColor.opacity(0.4), radius: 8) // Use ThemeColors
         // Note: Ensure ThemeColors is globally accessible or imported
    }
}

// MARK: - Preview (Optional)
struct ArtifactEarnedView_Previews: PreviewProvider {
    // Mock ThemeColors for preview if needed
    struct PreviewThemeColors { static let background = Color.black; static let primaryText = Color.white; static let secondaryText = Color.gray; static let panelBackground = Color.gray.opacity(0.2); static let glowColor = Color.cyan.opacity(0.5); static let primaryAccent = Color.cyan }
    static let ThemeColors = PreviewThemeColors.self

    static var previews: some View {
        ArtifactEarnedView(artifactName: "Badge of the Initiate")
            .padding()
            .background(PreviewThemeColors.background) // Use Preview ThemeColors
            .preferredColorScheme(.dark)
    }
}
