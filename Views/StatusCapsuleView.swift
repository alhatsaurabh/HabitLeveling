
import SwiftUI

struct StatusCapsuleView: View {
    let iconName: String
    let value: String
    let label: String
    let color: Color // Keep specific color (Warning/Success)

    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: iconName)
                .font(.subheadline)
                .foregroundColor(color)

            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(ThemeColors.primaryText) // Use theme text

            Text(label)
                .font(.caption)
                .foregroundColor(ThemeColors.secondaryText) // Use theme text
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(color.opacity(0.15))
        .cornerRadius(20)
        .overlay(
            Capsule().stroke(color.opacity(0.5), lineWidth: 1)
        )
    }
}
