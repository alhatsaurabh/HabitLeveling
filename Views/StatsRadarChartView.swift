// MARK: - File: StatsRadarChartView.swift
// Purpose: A SwiftUI view to display 5 stat categories on a radar chart.
// Update: Restored PreviewProvider implementation.

import SwiftUI
import Foundation // Import Foundation for log1p

struct StatsRadarChartView: View {
    let statPoints: [String: Int64]

    // Configuration
    // Assuming ThemeColors is accessible globally
    private let axisColor: Color = ThemeColors.tertiaryText.opacity(0.6)
    private let gridColor: Color = ThemeColors.tertiaryText.opacity(0.3)
    private let dataShapeColor: Color = ThemeColors.primaryAccent
    private let labelColor: Color = ThemeColors.secondaryText
    private let labelFont: Font = .caption2
    private let displayStatsOrder: [String] = ["STR", "INT", "PER", "AGI", "VIT"]
    private let axisCount = 5

    var body: some View {
        Canvas { context, size in
            // Debug print
             print("StatsRadarChartView received statPoints: \(statPoints)")

            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            let maxRadius = min(size.width, size.height) / 2 * 0.7 // Keep reduced radius

            // Determine the maximum LOGARITHMIC value for scaling
            let logValues = statPoints.values.map { log1p(Double($0)) } // log1p(x) = log(1+x)
            let maxLogValue = max(log1p(100.0), logValues.max() ?? log1p(100.0))

            // Draw Grid Lines
            drawGrid(context: context, center: center, maxRadius: maxRadius, levels: 4)

            // Draw Axes and Labels
            drawAxesAndLabels(context: context, center: center, maxRadius: maxRadius)

            // Draw Data Shape (using log scale)
            if statPoints.values.contains(where: { $0 > 0 }) {
                drawDataShapeLogScale(context: context, center: center, maxRadius: maxRadius, maxLogValue: maxLogValue)
            } else {
                // Draw center dot if no data
                var centerDot = Path(); centerDot.addEllipse(in: CGRect(x: center.x - 1, y: center.y - 1, width: 2, height: 2))
                context.fill(centerDot, with: .color(dataShapeColor.opacity(0.5)))
            }
        }
        .aspectRatio(1, contentMode: .fit)
        .padding()
    }

    // MARK: - Drawing Helper Functions

    /// Draws the concentric grid lines (pentagons)
    private func drawGrid(context: GraphicsContext, center: CGPoint, maxRadius: CGFloat, levels: Int) {
         guard levels > 0 else { return }
         for i in 1...levels {
             let radius = maxRadius * (CGFloat(i) / CGFloat(levels))
             var path = Path()
             for j in 0..<axisCount {
                 let angle = angleForAxis(index: j)
                 let point = pointOnCircle(center: center, radius: radius, angle: angle)
                 if j == 0 { path.move(to: point) } else { path.addLine(to: point) }
             }
             path.closeSubpath()
             context.stroke(path, with: .color(gridColor), lineWidth: 0.5)
         }
    }

    /// Draws the axes lines and category labels
    private func drawAxesAndLabels(context: GraphicsContext, center: CGPoint, maxRadius: CGFloat) {
         for i in 0..<axisCount {
             let angle = angleForAxis(index: i)
             let axisEndPoint = pointOnCircle(center: center, radius: maxRadius, angle: angle)
             var axisPath = Path(); axisPath.move(to: center); axisPath.addLine(to: axisEndPoint)
             context.stroke(axisPath, with: .color(axisColor), lineWidth: 1)

             let label = displayStatsOrder[i]
             let labelPoint = pointOnCircle(center: center, radius: maxRadius * 1.2, angle: angle) // Adjust multiplier if needed
             let horizontalAlignment: HorizontalAlignment = (abs(labelPoint.x - center.x) < maxRadius * 0.1) ? .center : (labelPoint.x < center.x ? .trailing : .leading)
             let verticalAlignment: VerticalAlignment = (abs(labelPoint.y - center.y) < maxRadius * 0.1) ? .center : (labelPoint.y < center.y ? .bottom : .top)
             let anchorX: CGFloat; switch horizontalAlignment { case .leading: anchorX = 0.0; case .center: anchorX = 0.5; case .trailing: anchorX = 1.0; default: anchorX = 0.5 }
             let anchorY: CGFloat; switch verticalAlignment { case .top: anchorY = 0.0; case .center: anchorY = 0.5; case .bottom: anchorY = 1.0; default: anchorY = 0.5 }
             context.draw( Text(label).font(labelFont).foregroundColor(labelColor), at: labelPoint, anchor: UnitPoint(x: anchorX, y: anchorY) )
         }
    }


    /// Draws the main data shape using LOGARITHMIC scaling
    private func drawDataShapeLogScale(context: GraphicsContext, center: CGPoint, maxRadius: CGFloat, maxLogValue: Double) {
        guard maxLogValue > 0 else { return }
        var dataPath = Path()
        for i in 0..<axisCount {
            let statKey = displayStatsOrder[i]
            let originalValue = Double(statPoints[statKey] ?? 0)
            let logValue = log1p(originalValue)
            let scaledRadius = max(0, maxRadius * (logValue / maxLogValue))
            let effectiveRadius = max(0.5, scaledRadius)
            let angle = angleForAxis(index: i)
            let point = pointOnCircle(center: center, radius: effectiveRadius, angle: angle)
            if i == 0 { dataPath.move(to: point) } else { dataPath.addLine(to: point) }
        }
        dataPath.closeSubpath()
        context.fill(dataPath, with: .color(dataShapeColor.opacity(0.4)))
        context.stroke(dataPath, with: .color(dataShapeColor), lineWidth: 2)
    }


    // MARK: - Geometry Helper Functions
    private func angleForAxis(index: Int) -> CGFloat {
         let anglePerAxis = 2 * .pi / CGFloat(axisCount); return CGFloat(index) * anglePerAxis - (.pi / 2)
    }
    private func pointOnCircle(center: CGPoint, radius: CGFloat, angle: CGFloat) -> CGPoint {
         let x = center.x + radius * cos(angle); let y = center.y + radius * sin(angle); return CGPoint(x: x, y: y)
    }
}


// MARK: - Preview Provider
struct StatsRadarChartView_Previews: PreviewProvider {
    // --- RESTORED: Implementation for previews ---
    // Define sample data directly here or ensure ThemeColors is accessible
     struct PreviewThemeColors {
         static let tertiaryText = Color.gray
         static let primaryAccent = Color.cyan
         static let secondaryText = Color.white.opacity(0.7)
     }
     static let ThemeColors = PreviewThemeColors.self // Use mock ThemeColors for preview

    static let sampleStatPoints: [String: Int64] = [
        "STR": 75, "INT": 80, "PER": 50, "AGI": 90, "VIT": 65
    ]
    static let sampleLowStatPoints: [String: Int64] = [
        "STR": 15, "INT": 25, "PER": 30, "AGI": 5, "VIT": 20
    ]
    static let sampleZeroStatPoints: [String: Int64] = [:] // Test empty dictionary
    static let sampleHighVariancePoints: [String: Int64] = [ // Test high variance
         "STR": 500000, "INT": 5, "PER": 10, "AGI": 550000, "VIT": 20
    ]


    static var previews: some View {
        VStack {
            Text("Mapped Stats Example")
            StatsRadarChartView(statPoints: sampleStatPoints)
                .frame(width: 300, height: 300)
                .background(Color.gray.opacity(0.1))
            Divider()
            Text("Low Mapped Stats Example")
            StatsRadarChartView(statPoints: sampleLowStatPoints)
                .frame(width: 200, height: 200)
                .background(Color.gray.opacity(0.1))
            Divider()
            Text("Zero Mapped Stats Example")
            StatsRadarChartView(statPoints: sampleZeroStatPoints)
                .frame(width: 200, height: 200)
                .background(Color.gray.opacity(0.1))
             Divider()
            Text("High Variance Example (Log Scale)")
            StatsRadarChartView(statPoints: sampleHighVariancePoints)
                .frame(width: 300, height: 300)
                .background(Color.gray.opacity(0.1))
        }
        .padding()
        .background(Color.black) // Use dark background for preview
        .preferredColorScheme(.dark)
    }
    // --- END RESTORED ---
}

// MARK: - Assumptions for Compilation
// - ThemeColors struct exists globally OR is mocked in Preview as above.
