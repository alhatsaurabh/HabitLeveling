// MARK: - File: HabitRowView.swift
// Purpose: Displays a single habit row with completion interaction.
// Update: Added panel styling (background, corner radius, padding).

import SwiftUI
import CoreData

struct HabitRowView: View {
    @ObservedObject var habit: Habit
    var onComplete: (Habit) -> Void
    @State private var isCompletedToday = false
    let themeAccentColor = ThemeColors.primaryAccent
    let streakColor = ThemeColors.warning

    // Define background color for the row panel
    let panelBackgroundColor = ThemeColors.panelBackground // Use the standard panel background

    var body: some View {
        HStack(spacing: 16) {
            // Left side: Quest name and XP
            VStack(alignment: .leading, spacing: 4) {
                Text(habit.name ?? "Unnamed Quest")
                    .font(.headline)
                    .foregroundColor(ThemeColors.primaryText)
                    .strikethrough(isCompletedToday)
                    .opacity(isCompletedToday ? 0.6 : 1.0)
                
                Text("XP: \(habit.xpValue)")
                    .font(.subheadline)
                    .foregroundColor(ThemeColors.secondaryText)
            }
            
            Spacer()
            
            // Right side: Completion circle
            Button(action: {
                if !isCompletedToday {
                    onComplete(habit)
                    withAnimation(.easeOut(duration: 0.2)) {
                        isCompletedToday = true
                    }
                }
            }) {
                Circle()
                    .stroke(isCompletedToday ? ThemeColors.success : ThemeColors.primaryAccent, lineWidth: 2)
                    .frame(width: 24, height: 24)
                    .overlay(
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(isCompletedToday ? ThemeColors.success : Color.clear)
                    )
            }
        }
        .padding()
        .background(ThemeColors.panelBackground.opacity(0.3))
        .cornerRadius(12)
        .onAppear {
            updateCompletionStatus()
        }
        .onChange(of: habit.lastCompletedDate) { _, _ in
            updateCompletionStatus()
        }
    }
    
    private func updateCompletionStatus() {
        if let lastDate = habit.lastCompletedDate, Calendar.current.isDateInToday(lastDate) {
            if !isCompletedToday { isCompletedToday = true }
        } else {
            if isCompletedToday { isCompletedToday = false }
        }
    }
}

// MARK: - Preview Provider (Example)
struct HabitRowView_Previews: PreviewProvider {
    // Mock ThemeColors for preview
    struct PreviewThemeColors {
        static let background = Color(red: 0.05, green: 0.05, blue: 0.1)
        static let primaryText = Color.white
        static let secondaryText = Color.gray
        static let panelBackground = Color(red: 0.15, green: 0.15, blue: 0.22) // Example panel color
        static let primaryAccent = Color.cyan
        static let success = Color.green
        static let warning = Color.orange
    }
    static let ThemeColors = PreviewThemeColors.self

    static var previews: some View {
        let context = PersistenceController.preview.container.viewContext
        let habit1 = Habit(context: context)
        habit1.id = UUID()
        habit1.name = "Daily Run"
        habit1.xpValue = 15
        habit1.streak = 5
        habit1.lastCompletedDate = Calendar.current.date(byAdding: .day, value: -1, to: Date()) // Not completed today

        let habit2 = Habit(context: context)
        habit2.id = UUID()
        habit2.name = "Read Chapter"
        habit2.xpValue = 10
        habit2.streak = 12
        habit2.lastCompletedDate = Date() // Completed today

        return VStack {
            HabitRowView(habit: habit1) { _ in print("Complete Tapped") }
            HabitRowView(habit: habit2) { _ in print("Complete Tapped") }
        }
        .padding()
        .background(ThemeColors.background)
        .preferredColorScheme(.dark)

    }
}
