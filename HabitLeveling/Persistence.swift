// MARK: - File: Persistence.swift (Updated April 5, 2025)
// Corrected closure capture list to avoid warning

import CoreData
import SwiftUI // Added for withAnimation (if used in previews)

struct PersistenceController {
    static let shared = PersistenceController()

    // Controller for SwiftUI Previews (uses in-memory store)
    static var preview: PersistenceController = {
        let result = PersistenceController(inMemory: true)
        let viewContext = result.container.viewContext

        // --- Add Sample Data for Previews ---
        for i in 0..<5 {
             let newHabit = Habit(context: viewContext)
             newHabit.id = UUID()
             newHabit.name = "Sample Habit \(i+1)"
             newHabit.frequency = "Daily"
             newHabit.xpValue = Int64(10 * (i + 1))
             newHabit.creationDate = Date()
             newHabit.streak = Int64(i)
             // Using .body and .mind as examples based on your StatCategory.swift
             newHabit.category = i % 2 == 0 ? StatCategory.body.rawValue : StatCategory.mind.rawValue
             newHabit.cue = "After waking up"
         }
         // Ensure UserProfile properties match your current model
         let userProfile = UserProfile(context: viewContext)
         userProfile.level = 1
         userProfile.xp = 30
         // Add other UserProfile attributes as needed for previews

        // --- Seed Artifacts for Previews ---
        // Use the viewContext directly available here
        ArtifactSeeder.seedInitialArtifacts(context: viewContext)

        // --- End Sample Data ---
        do {
            try viewContext.save()
        } catch {
            let nsError = error as NSError
            print("Error saving preview context: \(nsError), \(nsError.userInfo)")
        }
        return result
    }()

    let container: NSPersistentContainer

    // Initialize Core Data stack
    init(inMemory: Bool = false) {
        // Ensure this name matches your .xcdatamodeld file
        container = NSPersistentContainer(name: "HabitLeveling")

        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        }

        // Load persistent stores
        // --- CORRECTED: Explicitly capture container to avoid warning ---
        container.loadPersistentStores(completionHandler: { [container] (storeDescription, error) in
            if let error = error as NSError? {
                print("‼️ Core Data failed to load persistent store!")
                print("‼️ Error: \(error)")
                print("‼️ Error User Info: \(error.userInfo)")
                // Consider more robust error handling for production
                fatalError("Unresolved error \(error), \(error.userInfo)")
            } else {
                print("Core Data persistent store loaded successfully for: \(storeDescription.url?.absoluteString ?? "In-Memory")")

                // --- Seed Artifacts for Main App ---
                // Call the seeder after the store is loaded successfully
                // Access viewContext via the captured container
                ArtifactSeeder.seedInitialArtifacts(context: container.viewContext)
            }
        })
        // Configure merge policies AFTER loading stores
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
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
                // Handle save error appropriately in production
            }
        }
    }
}
