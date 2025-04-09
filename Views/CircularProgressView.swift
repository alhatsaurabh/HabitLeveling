
import SwiftUI

struct CircularProgressView: View {
    let progress: Double // Value between 0.0 and 1.0
    let level: Int
    let strokeWidth: CGFloat = 10.0
    let themeAccentColor = ThemeColors.primaryAccent // Use theme color
    let glowColor = ThemeColors.glowColor // Use theme glow color

    var body: some View {
        ZStack {
            // Background track circle
            Circle()
                .stroke(
                    themeAccentColor.opacity(0.2),
                    lineWidth: strokeWidth
                )

            // Progress circle
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    themeAccentColor,
                    style: StrokeStyle(
                        lineWidth: strokeWidth,
                        lineCap: .round
                    )
                )
                .rotationEffect(.degrees(-90))
                .animation(.easeOut, value: progress)

            // Level Text in the center
            Text("\(level)")
                .font(.system(size: 40, weight: .bold))
                .foregroundColor(themeAccentColor)
                // --- ADDED Text Shadow for Glow ---
                .shadow(color: glowColor, radius: 4, x: 0, y: 0) // Add subtle glow
                // --- END Text Shadow ---
        }
        .frame(width: 100, height: 100)
        .padding(strokeWidth / 2)
    }
}
