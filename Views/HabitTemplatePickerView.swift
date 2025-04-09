// MARK: - File: HabitTemplatePickerView.swift
// Purpose: Displays a list of predefined habit templates for selection.
// Update: Removed local HabitTemplateProvider definition from PreviewProvider to resolve redeclaration error.

import SwiftUI

// Assume HabitTemplate struct exists and is Identifiable & Hashable
// Assume HabitTemplateProvider exists GLOBALLY and has a static 'templates' array

struct HabitTemplatePickerView: View {
    // Closure to call when a template is selected
    var onTemplateSelected: (HabitTemplate) -> Void
    @Environment(\.dismiss) var dismiss

    // Data source for templates - Uses the GLOBAL HabitTemplateProvider
    let templates: [HabitTemplate] = HabitTemplateProvider.templates

    // Theme Colors (Assume ThemeColors struct exists globally)
    let themeAccentColor = ThemeColors.primaryAccent
    let panelBackgroundColor = ThemeColors.panelBackground

    var body: some View {
        NavigationView {
            List {
                // Check if the globally provided templates list is empty
                if templates.isEmpty {
                    Text("No templates available.")
                        .foregroundColor(.secondary)
                        .listRowBackground(Color.clear) // Make background clear
                } else {
                    ForEach(templates) { template in
                        // Use a Button for the whole row to make it tappable
                        Button {
                            // Call completion handler and dismiss
                            onTemplateSelected(template)
                            dismiss()
                        } label: {
                            // Row content
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(template.name)
                                        .font(.headline)
                                        .foregroundColor(ThemeColors.primaryText)
                                    if let description = template.description, !description.isEmpty {
                                        Text(description)
                                            .font(.caption)
                                            .foregroundColor(ThemeColors.secondaryText)
                                            .lineLimit(2) // Limit description lines
                                    }
                                    HStack {
                                        Text("Category: \(template.category.rawValue)")
                                        Text("| XP: \(template.xpValue)")
                                        Text("| Freq: \(template.frequency)")
                                    }
                                    .font(.caption2)
                                    .foregroundColor(ThemeColors.secondaryText)
                                }
                                Spacer() // Push content left
                                Image(systemName: "chevron.right") // Indicate tappable row
                                    .foregroundColor(ThemeColors.secondaryText)
                            }
                            .padding(.vertical, 8) // Add some vertical padding within the row content
                        }
                        // Styling for the list row
                        .listRowBackground(panelBackgroundColor.opacity(0.7)) // Apply panel background to row
                        .listRowSeparator(.hidden) // Hide default separators
                    }
                }
            }
            .listStyle(.plain) // Use plain style to remove default List background/insets
            .background(ThemeColors.background.ignoresSafeArea()) // Match app background
            .navigationTitle("Choose Template")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss() // Dismiss the sheet
                    }
                    .tint(themeAccentColor) // Use theme accent color
                }
            }
            .preferredColorScheme(.dark) // Force dark mode
        }
        // Note: This view now relies on the GLOBAL HabitTemplateProvider.swift file existing
        // and containing a static property 'templates: [HabitTemplate]'.
        // Ensure ThemeColors is also globally accessible.
    }
}

// MARK: - Preview Provider
struct HabitTemplatePickerView_Previews: PreviewProvider {
    // Mock ThemeColors and StatCategory for preview
    // These mocks are only needed if the global versions aren't accessible or suitable for previews
    struct PreviewThemeColors {
        static let background = Color.black
        static let primaryText = Color.white
        static let secondaryText = Color.gray
        static let panelBackground = Color(red: 0.15, green: 0.15, blue: 0.22)
        static let primaryAccent = Color.cyan
        // Add other colors if needed by templates
    }
    // Use the local mock ThemeColors struct for the preview context
    static let ThemeColors = PreviewThemeColors.self

    // Mock StatCategory needed by HabitTemplate (if global one isn't accessible/suitable)
    // If your global StatCategory is accessible, you might not need this mock.
    enum StatCategory: String, CaseIterable, Identifiable {
        case mind="Mind", body="Body", skill="Skill", discipline="Discipline", wellbeing="Wellbeing", other="Other"
        var id: String { rawValue } // Add identifiable conformance if needed by template mock
    }

    // --- REMOVED Local HabitTemplateProvider struct ---
    // The preview now relies on the GLOBAL HabitTemplateProvider
    // Make sure your global HabitTemplateProvider.swift provides suitable static 'templates' data
    // OR create a specific Mock Provider if the global one isn't suitable for previews.


    static var previews: some View {
        // Ensure the global HabitTemplateProvider has data for the preview to work
        HabitTemplatePickerView { template in
            print("Selected template: \(template.name)")
        }
        .preferredColorScheme(.dark)
    }
}
