// MARK: - File: ViewModifiers.swift
// Purpose: Contains custom ViewModifiers and extensions used in the app.

import SwiftUI

// Assume ThemeColors struct exists globally or is imported
// struct ThemeColors {
//     static let primaryText: Color = .white
//     static let secondaryText: Color = .gray
//     static let tertiaryText: Color = .darkGray
//     static let panelBackground: Color = Color.gray.opacity(0.15)
//     // ... other colors
// }

// MARK: - Custom View Modifiers

/// Style for input field labels (e.g., "Quest Title", "Description").
struct InputLabelStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.headline) // Or .caption, .footnote, etc.
            .foregroundColor(ThemeColors.secondaryText) // Use theme color
            // Add any other consistent label styling here
    }
}

/// Style for TextFields and TextEditor input areas.
struct InputFieldStyle: ViewModifier {
    var isFocused: Bool
    var accentColor: Color // Pass accent color for focus border

    func body(content: Content) -> some View {
        content
            .font(.body) // Standard font for input
            .padding(10) // Internal padding
            .background(ThemeColors.panelBackground.opacity(0.5)) // Use theme panel color
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isFocused ? accentColor : ThemeColors.tertiaryText.opacity(0.5), lineWidth: 1.5) // Highlight when focused, use theme colors
            )
            .foregroundColor(ThemeColors.primaryText) // Text color inside field
    }
}

// MARK: - View Extension for Modifiers

extension View {
    /// Applies standard styling for input field labels.
    func inputLabelStyle() -> some View {
        modifier(InputLabelStyle())
    }

    /// Applies standard styling for text fields and text editors.
    /// - Parameters:
    ///   - isFocused: Boolean indicating if the field currently has focus.
    ///   - accentColor: The color to use for the border when focused (usually ThemeColors.primaryAccent).
    func inputFieldStyle(isFocused: Bool, accentColor: Color) -> some View {
        modifier(InputFieldStyle(isFocused: isFocused, accentColor: accentColor))
    }
}
