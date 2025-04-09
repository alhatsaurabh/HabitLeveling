import SwiftUI

struct StatDistributionBarView: View {
    // Input: Dictionary of stat points, e.g., ["STR": 150, "VIT": 120, ...]
    let statPoints: [String: Int64]

    // Configuration
    private let barHeight: CGFloat = 12
    private let cornerRadius: CGFloat = 6
    private let spacing: CGFloat = 1 // Spacing between segments

    // Define the order and colors ONLY for the stats to be displayed in the bar
    // These should correspond to colors defined in your ThemeColors struct
    private let coreStatOrder: [String] = ["STR", "VIT", "AGI", "INT", "PER"]
    private let statColors: [String: Color] = [
        // IMPORTANT: Ensure these color names exist in your ThemeColors struct!
        // If not, add them or adjust the names used here.
        "STR": ThemeColors.strengthStat,
        "VIT": ThemeColors.vitalityStat,
        "AGI": ThemeColors.agilityStat,
        "INT": ThemeColors.intelligenceStat,
        "PER": ThemeColors.perceptionStat
    ]

    // Filtered points containing only the core stats we want to display
    private var coreStatPoints: [String: Int64] {
        statPoints.filter { coreStatOrder.contains($0.key) }
    }

    // Calculate total points ONLY from the core stats for proportion calculation
    private var totalCorePoints: Int64 {
        coreStatPoints.values.reduce(0, +)
    }

    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: spacing) {
                // Ensure total core points is not zero
                if totalCorePoints > 0 {
                    // Iterate only over the defined core stat order
                    ForEach(coreStatOrder, id: \.self) { statKey in
                        // Use the filtered coreStatPoints dictionary
                        if let points = coreStatPoints[statKey], points > 0 {
                            // Calculate proportion based on total *core* points
                            let proportion = CGFloat(points) / CGFloat(totalCorePoints)
                            // Calculate width based on available geometry and spacing
                            // Subtract total spacing from width before calculating proportion
                            let totalSpacing = spacing * CGFloat(coreStatPoints.filter { $0.value > 0 }.count - 1)
                            let availableWidth = max(0, geometry.size.width - totalSpacing)
                            let segmentWidth = availableWidth * proportion

                            // Ensure width is valid before creating the rectangle
                            if segmentWidth > 0 && !segmentWidth.isNaN {
                                Rectangle()
                                    .fill(statColors[statKey] ?? Color.gray) // Use defined color or gray fallback
                                    .frame(width: segmentWidth)
                            }
                        }
                    }
                } else {
                    // Show a default empty bar if no core points
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: geometry.size.width) // Fill entire width
                }
            }
        }
        .frame(height: barHeight)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
        .overlay(
            RoundedRectangle(cornerRadius: cornerRadius)
                .stroke(Color.white.opacity(0.1), lineWidth: 1) // Subtle border
        )
        // Add animation if desired when statPoints change
        // .animation(.easeInOut, value: statPoints)
    }
}

// MARK: - Preview Provider
struct StatDistributionBarView_Previews: PreviewProvider {
    // Mock ThemeColors for preview
    struct PreviewThemeColors {
        static let strengthStat: Color? = .red
        static let vitalityStat: Color? = .green
        static let agilityStat: Color? = .blue
        static let intelligenceStat: Color? = .purple
        static let perceptionStat: Color? = .orange
    }
    static let ThemeColors = PreviewThemeColors.self

    static var previews: some View {
        // Sample data for preview including non-core stats
        let samplePoints1: [String: Int64] = ["STR": 100, "VIT": 80, "AGI": 60, "INT": 70, "PER": 50, "OTHER_STAT": 1000]
        let samplePoints2: [String: Int64] = ["STR": 20, "VIT": 30, "AGI": 100, "INT": 10, "PER": 5]
        let samplePointsEmpty: [String: Int64] = [:]
        let samplePointsSingle: [String: Int64] = ["INT": 100]
        let samplePointsOnlyOther: [String: Int64] = ["OTHER_STAT": 500]


        VStack(alignment: .leading, spacing: 10) {
            Text("Example 1 (Mixed + Other Ignored):")
            StatDistributionBarView(statPoints: samplePoints1)

            Text("Example 2 (AGI Dominated):")
            StatDistributionBarView(statPoints: samplePoints2)

            Text("Example 3 (Empty):")
            StatDistributionBarView(statPoints: samplePointsEmpty)

            Text("Example 4 (Single Core Stat):")
            StatDistributionBarView(statPoints: samplePointsSingle)

            Text("Example 5 (Only Non-Core Stats):")
            StatDistributionBarView(statPoints: samplePointsOnlyOther) // Should show empty bar
        }
        .padding()
        .background(Color.black)
        .preferredColorScheme(.dark)
        .foregroundColor(.white) // Set text color for preview labels
    }
}

// MARK: - Additions needed in ThemeColors.swift (Example)
/*
 struct ThemeColors {
     // ... existing colors ...

     // Stat Colors (Ensure these exist)
     static let strengthStat: Color? = Color(hex: "E53E3E") // Example Red
     static let vitalityStat: Color? = Color(hex: "48BB78") // Example Green
     static let agilityStat: Color? = Color(hex: "4299E1") // Example Blue
     static let intelligenceStat: Color? = Color(hex: "9F7AEA") // Example Purple
     static let perceptionStat: Color? = Color(hex: "ED8936") // Example Orange
 }
 */
