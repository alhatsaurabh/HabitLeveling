
import SwiftUI

// Define the reusable View Modifier for the panel style
struct SoloPanelModifier: ViewModifier {
    // Define colors (adjust these to match Solo Leveling theme better)
    let backgroundColor = Color.black.opacity(0.5) // Slightly darker background
    let gradientStart = Color.cyan.opacity(0.8) // Brighter part of the glow
    let gradientEnd = Color.cyan.opacity(0.1)   // Fainter part of the glow
    let shadowColor = Color.cyan.opacity(0.6) // Outer glow color

    func body(content: Content) -> some View {
        content
            .padding() // Add padding inside the row content
            .background(backgroundColor) // Apply background color
            .cornerRadius(8) // Rounded corners
            // --- Use a gradient for the border stroke ---
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    // Create a linear gradient for the stroke
                    .stroke(
                        LinearGradient(
                            gradient: Gradient(colors: [gradientStart, gradientEnd, gradientStart]), // Cycle colors for effect
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.5 // Adjust line width as needed
                    )
            )
            // --- End gradient border ---
            // Add an outer shadow for the glow effect
            .shadow(color: shadowColor, radius: 6, x: 0, y: 0) // Slightly increased radius
            // Add padding *around* the row itself to separate panels
            .padding(.vertical, 5)
            .padding(.horizontal, 10)
            // Ensure the background color doesn't make rows transparent to each other
            .listRowInsets(EdgeInsets()) // Remove default list row padding
            .listRowBackground(Color.clear) // Make default list row background clear
    }
}

// Optional: Extension to make applying the modifier easier
extension View {
    func soloPanelStyle() -> some View {
        modifier(SoloPanelModifier())
    }
}
