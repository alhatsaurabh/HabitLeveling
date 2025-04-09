// --- Essence Core View (EssenceCoreView.swift) ---
// Displays the visual representation of the Essence Core.
struct EssenceCoreView: View {
    var state: String // e.g., "Bright", "Dim", "Flickering" (Passed from ViewModel)

    var body: some View {
        // Simple representation for now
        Circle()
            .fill(coreColor)
            .frame(width: 50, height: 50)
            .shadow(color: coreColor.opacity(0.8), radius: state == "Bright" ? 10 : 2) // Glowing effect
            .overlay(
                Circle().stroke(coreColor.opacity(0.5), lineWidth: 1)
            )
            .animation(.easeInOut, value: state) // Animate changes
    }

    // Determine color based on state
    private var coreColor: Color {
        switch state {
        case "Bright":
            return .cyan // Use theme accent
        case "Dim":
            return .gray
        case "Flickering": // Could add animation later
            return .orange
        default:
            return .gray
        }
    }
}

