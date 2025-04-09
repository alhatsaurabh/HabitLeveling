// MARK: - File: CombinedLevelEssenceView.swift
// Purpose: Displays Level, XP Progress Arc, and Essence Core State in one view.
// Combines elements from CircularProgressView and EssenceCoreView.

import SwiftUI

struct CombinedLevelEssenceView: View {
    // MARK: - Inputs
    let level: Int
    let progress: Double // XP progress (0.0 to 1.0) for the arc
    let essenceState: String // "Bright", "Dim", "Flickering", "Off", etc.

    // MARK: - Configuration
    private let strokeWidth: CGFloat = 10.0
    private let frameSize: CGFloat = 100.0

    // MARK: - State for Animation
    @State private var isAnimating: Bool = false

    // MARK: - Theme Colors (Assuming global ThemeColors struct)
    private let themeAccentColor = ThemeColors.primaryAccent
    private let glowColor = ThemeColors.glowColor
    private let brightColor = ThemeColors.secondaryAccent
    private let dimColor = ThemeColors.tertiaryText // Or another appropriate color
    private let flickeringColor = ThemeColors.warning
    private let offColor = Color.gray.opacity(0.5)

    // MARK: - Body
    var body: some View {
        ZStack {
            // --- Background Glow / Fill (from EssenceCoreView logic) ---
            Circle()
                .fill(essenceBackgroundColor.opacity(isAnimating ? 0.5 : 0.3)) // Use state-based bg color
                .blur(radius: isAnimating ? 15 : 5)
                .scaleEffect(isAnimating ? 1.1 : 1.0) // Subtle scale effect for active states

            // --- XP Progress Track ---
            Circle()
                .stroke(
                    themeAccentColor.opacity(0.2), // Standard track color
                    lineWidth: strokeWidth
                )

            // --- XP Progress Arc ---
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    progressArcColor, // Use state-based color for the arc
                    style: StrokeStyle(
                        lineWidth: strokeWidth,
                        lineCap: .round
                    )
                )
                .rotationEffect(.degrees(-90))
                .shadow(color: progressArcGlow, radius: isAnimating ? 5 : 0) // Add glow to arc in active states
                .animation(.easeOut, value: progress) // Animate progress change

            // --- Level Text ---
            Text("\(level)")
                .font(.system(size: 40, weight: .bold))
                .foregroundColor(levelTextColor) // State-based text color
                .shadow(color: levelTextGlow, radius: isAnimating ? 6 : 2) // State-based glow

        }
        .frame(width: frameSize, height: frameSize)
        // Apply animations based on isAnimating state (triggered by essenceState)
        .animation(isAnimating ? .easeInOut(duration: 1.0).repeatForever(autoreverses: true) : .smooth(duration: 0.5), value: isAnimating)
        // Animate color changes smoothly
        .animation(.smooth(duration: 0.5), value: essenceBackgroundColor)
        .animation(.smooth(duration: 0.5), value: progressArcColor)
        .animation(.smooth(duration: 0.5), value: levelTextColor)
        // Trigger animation updates when essenceState changes
        .onAppear {
            updateAnimationState()
        }
        .onChange(of: essenceState) {
             updateAnimationState()
        }
    }

    // MARK: - Dynamic Colors based on Essence State

    private var essenceBackgroundColor: Color {
        // Determine a suitable background fill based on state
        switch essenceState {
            case "Bright": return brightColor
            case "Dim": return dimColor.opacity(0.5) // Make dim bg less prominent
            case "Flickering": return flickeringColor
            case "Off": return offColor.opacity(0.3)
            default: return dimColor.opacity(0.5)
        }
    }

    private var progressArcColor: Color {
        // Progress arc could use theme accent or react to state
        switch essenceState {
            case "Bright", "Flickering": return brightColor // Use essence color when active?
            default: return themeAccentColor // Default to theme accent
        }
    }

    private var progressArcGlow: Color {
        switch essenceState {
            case "Bright", "Flickering": return progressArcColor.opacity(0.7)
            default: return .clear
        }
    }

    private var levelTextColor: Color {
        // Level text could use theme accent or react to state
        switch essenceState {
            case "Bright", "Flickering": return .white // Brighter text for active states
            default: return themeAccentColor // Default to theme accent
        }
    }

    private var levelTextGlow: Color {
        switch essenceState {
            case "Bright": return brightColor.opacity(0.8)
            case "Flickering": return flickeringColor.opacity(0.8)
            default: return glowColor.opacity(0.5) // Use default glow otherwise
        }
    }

    // MARK: - Animation Helper

    private func updateAnimationState() {
        // Determine if animation should be active based on state
        let shouldAnimate = (essenceState == "Bright" || essenceState == "Flickering")
        if isAnimating != shouldAnimate {
             isAnimating = shouldAnimate
        }
    }
}

// MARK: - Preview Provider
struct CombinedLevelEssenceView_Previews: PreviewProvider {
    // Mock ThemeColors for preview
    struct PreviewThemeColors {
        static let primaryAccent = Color.cyan
        static let secondaryAccent = Color.blue // Bright Essence
        static let tertiaryText = Color.gray // Dim Essence
        static let warning = Color.yellow // Flickering Essence
        static let glowColor = Color.cyan.opacity(0.8)
        // Add other colors if needed
        static let primaryText = Color.white
    }
    // Assign to local constants matching the names used in the view
    static let ThemeColors = PreviewThemeColors.self

    static var previews: some View {
        VStack(spacing: 30) {
            CombinedLevelEssenceView(level: 1, progress: 0.1, essenceState: "Off")
            CombinedLevelEssenceView(level: 5, progress: 0.5, essenceState: "Dim")
            CombinedLevelEssenceView(level: 10, progress: 0.8, essenceState: "Bright")
            CombinedLevelEssenceView(level: 25, progress: 0.3, essenceState: "Flickering")
        }
        .padding()
        .background(Color.black)
        .preferredColorScheme(.dark)
    }
}
