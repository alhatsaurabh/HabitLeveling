// MARK: - File: AddEditHabitViewModel.swift
// Update: Reverted template population logic back into the initializer.

import SwiftUI
import CoreData
import Combine

class AddEditHabitViewModel: ObservableObject {

    // MARK: - Published Properties (Form Fields)
    @Published var name: String = ""
    @Published var description: String = ""
    @Published var statCategory: StatCategory = .body // Default category
    @Published var xpValue: Int = 10 // Default XP
    @Published var frequency: String = "Daily" // Default frequency
    @Published var notificationTime: Date? = nil // Optional reminder time
    @Published var isTwoMinuteVersion: Bool = false // Atomic Habits toggle

    // MARK: - Internal State
    let habitToEdit: Habit? // Holds the habit being edited, if any
    let frequencies = ["Daily", "Weekly"] // Available frequencies

    // Access to Core Data context
    private var viewContext = PersistenceController.shared.container.viewContext // Assume PersistenceController exists

    // MARK: - Initializer
    // REVERTED: Handles template directly in init again.
    init(habit: Habit? = nil, template: HabitTemplate? = nil) {
        self.habitToEdit = habit

        if let habit = habit {
            // Editing existing habit: Populate from habit object
            print("Initializing ViewModel for Editing Habit: \(habit.name ?? "nil")")
            name = habit.name ?? ""
            description = habit.habitDescription ?? "" // Ensure CoreData attribute name matches
            statCategory = StatCategory(rawValue: habit.statCategory ?? "") ?? .body
            xpValue = Int(habit.xpValue)
            frequency = habit.frequency ?? "Daily"
            notificationTime = habit.notificationTime
            isTwoMinuteVersion = habit.isTwoMinuteVersion
        } else if let template = template {
            // Adding new habit from template: Populate from template object
            print("Initializing ViewModel from Template: \(template.name)")
            name = template.name
            description = template.description ?? ""
            statCategory = template.category // Assumes HabitTemplate.category is StatCategory type
            xpValue = Int(template.xpValue) // Convert Int64 if needed
            frequency = template.frequency
            // Use defaults for fields not in template
            notificationTime = nil
            isTwoMinuteVersion = false
        } else {
            // Adding new custom habit: Use default values (set above)
            print("Initializing ViewModel for New Custom Habit")
        }
    }

    // --- REMOVED configureFromTemplate method ---

    // MARK: - Save Logic
    func saveHabit() -> Bool {
        guard !name.isEmpty else { print("Validation Failed: Name empty."); return false }
        let habit = habitToEdit ?? Habit(context: viewContext)
        // Assign properties
        habit.id = habitToEdit?.id ?? UUID()
        habit.name = name
        habit.habitDescription = description
        habit.statCategory = statCategory.rawValue
        habit.xpValue = Int64(xpValue)
        habit.frequency = frequency
        habit.notificationTime = notificationTime
        habit.isTwoMinuteVersion = isTwoMinuteVersion
        if habitToEdit == nil { habit.creationDate = Date() } // Set creation date only for new

        print("Attempting to save habit: \(habit.name ?? "nil")")
        do {
            try viewContext.save()
            print("Habit saved successfully.")
            
            // Handle notifications based on reminder settings
            if notificationTime != nil {
                print("Scheduling notification for habit with reminder time")
                NotificationManager.shared.scheduleNotificationForHabit(habit)
            } else if habitToEdit?.notificationTime != nil {
                // If editing a habit and removing the notification time
                print("Cancelling notification for habit after removing reminder time")
                NotificationManager.shared.cancelNotification(for: habit)
            }
            
            return true
        } catch {
            print("Error saving habit: \(error.localizedDescription)")
            viewContext.rollback()
            return false
        }
    }
}
