// MARK: - File: Persistence.swift (Updated April 3, 2025)
// Improved error reporting during persistent store loading

import CoreData
import SwiftUI // Added for withAnimation (if used in previews)

struct PersistenceController {
    static let shared = PersistenceController()

    // Controller for SwiftUI Previews (uses in-memory store)
    static var preview: PersistenceController = {
        let result = PersistenceController(inMemory: true)
        let viewContext = result.container.viewContext
        // --- Add Sample Data for Previews ---
        // (Sample data code remains the same as you provided)
        for i in 0..<5 {
             let newHabit = Habit(context: viewContext)
             newHabit.id = UUID()
             newHabit.name = "Sample Habit \(i+1)"
             newHabit.frequency = "Daily"
             newHabit.xpValue = Int64(10 * (i + 1))
             newHabit.creationDate = Date()
             newHabit.streak = Int64(i)
             newHabit.category = i % 2 == 0 ? "Health" : "Mind"
             newHabit.cue = "After waking up"
             newHabit.isTwoMinuteVersion = i % 3 == 0
         }
         let userProfile = UserProfile(context: viewContext)
         userProfile.level = 1
         userProfile.xp = 30
         userProfile.manaCrystals = 5
         userProfile.essenceCoreState = "Bright"
        // --- End Sample Data ---
        do {
            try viewContext.save()
        } catch {
            let nsError = error as NSError
            // Even in memory, fatal error might be okay for previews, but printing is better
            print("Error saving preview context: \(nsError), \(nsError.userInfo)")
            // fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
        return result
    }()

    let container: NSPersistentContainer

    // Initialize Core Data stack
    init(inMemory: Bool = false) {
        // Name MUST match your .xcdatamodeld file name
        container = NSPersistentContainer(name: "HabitLeveling") // Make sure "HabitLeveling" is correct

        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        }

        // Load persistent stores
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                // *** MODIFIED PART: Print the error before crashing ***
                print("‼️ Core Data failed to load persistent store!")
                print("‼️ Error: \(error)")
                print("‼️ Error User Info: \(error.userInfo)")
                // You might want to handle this more gracefully in a production app
                // For debugging, fatalError helps pinpoint the issue, but now we see the cause first.
                fatalError("Unresolved error \(error), \(error.userInfo)")
            } else {
                // Optional: Print success message
                print("Core Data persistent store loaded successfully for: \(storeDescription.url?.absoluteString ?? "In-Memory")")
            }
        })
        container.viewContext.automaticallyMergesChangesFromParent = true
    }

    // Helper function to save the context
     func saveContext() {
        let context = container.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let nsError = error as NSError
                print("Error saving context: \(nsError), \(nsError.userInfo)")
            }
        }
    }
}
