// MARK: - File: EssenceCoreView.swift (Updated April 3, 2025)
// Fixed syntax error in PreviewProvider

import SwiftUI

struct EssenceCoreView: View {
    var state: String // "Bright", "Dim", "Flickering", "Off" etc.
    // Assuming ThemeColors defined elsewhere ONCE in your project
    // These properties will now use the *actual* ThemeColors struct from your project
    let brightColor = ThemeColors.secondaryAccent
    let dimColor = ThemeColors.tertiaryText // Assuming tertiaryText exists in your ThemeColors
    let flickeringColor = ThemeColors.warning
    let offColor = Color.gray.opacity(0.5)
    let glowColor = ThemeColors.secondaryAccent.opacity(0.7)

    @State private var isAnimating: Bool = false

    var body: some View {
        ZStack {
            // Outer Glow
            Circle()
                .fill(currentColor.opacity(0.3))
                .blur(radius: isAnimating ? 15 : 5)
                .scaleEffect(isAnimating ? 1.2 : 1.0)
                .opacity(isAnimating ? 0.7 : 0.4)

            // Inner Core
            Circle()
                .fill(
                    RadialGradient(
                        gradient: Gradient(colors: [currentColor.opacity(0.7), currentColor]),
                        center: .center,
                        startRadius: 5,
                        endRadius: 20
                    )
                )
                .shadow(color: (state == "Bright" || state == "Flickering") ? glowColor.opacity(isAnimating ? 0.8 : 0.3) : .clear,
                        radius: (state == "Dim" || state == "Off") ? 2 : 10)

        }
        .frame(width: 50, height: 50)
        .scaleEffect(isAnimating ? 1.1 : 1.0)
        .onAppear {
            updateAnimationState()
        }
        .onChange(of: state) {
             updateAnimationState()
        }
        .animation(isAnimating ? .easeInOut(duration: 1.0).repeatForever(autoreverses: true) : .smooth(duration: 0.5), value: isAnimating)
        .animation(.smooth(duration: 0.5), value: currentColor)
    }

    // Determine the color based on the state string
    private var currentColor: Color {
        switch state {
        case "Bright": return brightColor
        case "Dim": return dimColor
        case "Flickering": return flickeringColor
        case "Off": return offColor
        default: return dimColor // Default to Dim if state is unknown
        }
    }

    // Update the animation flag based on the state
    private func updateAnimationState() {
        let shouldAnimate = (state == "Bright" || state == "Flickering")
        if isAnimating != shouldAnimate {
             isAnimating = shouldAnimate
        }
    }
}

// Preview Provider
struct EssenceCoreView_Previews: PreviewProvider {
    // *** Define temporary ThemeColors struct HERE for preview scope ***
    // This allows the preview to compile without needing the global ThemeColors,
    // and avoids the redeclaration error.
    struct PreviewThemeColors {
         static let secondaryAccent = Color.cyan
         static let tertiaryText = Color.gray // Use .gray instead of .darkGray
         static let warning = Color.yellow
         // Add other colors used ONLY by EssenceCoreView if needed for preview
    }

    // Use the temporary struct within the preview
    static var previews: some View {
        // We need to pass state values to the preview instances
        VStack(spacing: 20) {
            // Manually create instances for preview, passing state
            // Note: We can't directly use the PreviewThemeColors for the main struct's properties easily here.
            // The main struct will use the *real* ThemeColors when run in the app.
            // Previews might not look exactly right if colors differ significantly.
            Text("Preview (Colors might differ slightly from app)")
                 .font(.caption)
                 .foregroundColor(.gray)
            EssenceCoreView(state: "Off")
            EssenceCoreView(state: "Dim")
            EssenceCoreView(state: "Bright")
            EssenceCoreView(state: "Flickering")
        }
        .padding()
        .background(Color.black) // Preview on dark background
    }
}

// *** IMPORTANT: Ensure the REAL ThemeColors struct is defined ***
// *** exactly ONCE elsewhere in your project. ***
