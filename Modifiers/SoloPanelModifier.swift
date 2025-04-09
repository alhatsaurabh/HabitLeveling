import SwiftUI

struct SoloPanelModifier: ViewModifier {
    // Use updated colors from ThemeColors struct
    let backgroundColor = ThemeColors.panelBackground
    // Use primary accent for a more focused border glow
    let borderGradientStart = ThemeColors.primaryAccent.opacity(0.9)
    let borderGradientMid = ThemeColors.primaryAccent.opacity(0.4)
    let borderGradientEnd = ThemeColors.primaryAccent.opacity(0.9)
    let shadowColor = ThemeColors.glowColor // Use glow color from theme

    func body(content: Content) -> some View {
        content
            .padding() // Keep internal padding
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(backgroundColor.opacity(0.7))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        borderGradientStart,
                                        borderGradientMid,
                                        borderGradientEnd
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
                    .shadow(color: shadowColor.opacity(0.5), radius: 8, x: 0, y: 0)
                    .shadow(color: shadowColor.opacity(0.2), radius: 16, x: 0, y: 8)
            )
            .padding(.vertical, 5)
            .padding(.horizontal, 10)
            .listRowInsets(EdgeInsets())
            .listRowBackground(Color.clear)
    }
}

// Extension remains the same
extension View {
    func soloPanelStyle() -> some View {
        modifier(SoloPanelModifier())
    }
}
