import SwiftUI

struct GradientButtonStyle: ButtonStyle {
    // Use updated colors from ThemeColors struct
    let startColor = ThemeColors.gradientStart // Now uses secondaryAccent (Mana Blue)
    let endColor = ThemeColors.gradientEnd   // Now uses primaryAccent (Vibrant Purple)
    let pressedOpacity: Double = 0.8

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundColor(ThemeColors.primaryText) // Use theme text color
            .padding(.vertical, 10)
            .padding(.horizontal, 25)
            .frame(maxWidth: .infinity)
            .background(
                LinearGradient(gradient: Gradient(colors: [startColor, endColor]), startPoint: .leading, endPoint: .trailing)
            )
            .cornerRadius(8)
            .opacity(configuration.isPressed ? pressedOpacity : 1.0)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeOut(duration: 0.1), value: configuration.isPressed)
    }
}
