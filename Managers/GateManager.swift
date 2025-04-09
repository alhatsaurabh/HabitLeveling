
import Foundation
import CoreData

// Handles unlocking and managing Sanctum elements.
class SanctumManager {
    // Singleton pattern
    static let shared = SanctumManager()
    private init() {}

    // Function called potentially after a level up to check for new unlocks
    func checkForUnlocks(for profile: UserProfile) {
        let viewContext = PersistenceController.shared.container.viewContext
        let currentLevel = Int(profile.level)

        // Define unlocks based on level (Example)
        let unlocks: [Int: String] = [
            2: "Foundation Stone"
            // Removed Training Post & Meditation Rock as they are now buildable
        ]

        if let unlockType = unlocks[currentLevel] {
            // Check if this item type has already been unlocked
            let fetchRequest: NSFetchRequest<SanctumItem> = SanctumItem.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "elementType == %@", unlockType)
            fetchRequest.fetchLimit = 1

            do {
                let existing = try viewContext.fetch(fetchRequest)
                if existing.isEmpty {
                    // Unlock the new item
                    let newItem = SanctumItem(context: viewContext)
                    newItem.id = UUID()
                    newItem.elementType = unlockType
                    newItem.unlockDate = Date()
                    PersistenceController.shared.saveContext()
                    print("Sanctum Unlock: \(unlockType) unlocked at level \(currentLevel)!")
                    // TODO: Trigger notification/feedback to user
                }
            } catch {
                print("Error checking for existing Sanctum items: \(error)")
            }
        }
    }

    // --- NEW FUNCTION ---
    // Function to attempt spending fragments to build a specific item
    // Returns true if successful, false otherwise (e.g., insufficient funds, already exists)
    func spendFragmentsToBuild(item: AvailableSanctumItem, profile: UserProfile) -> Bool {
        let viewContext = PersistenceController.shared.container.viewContext
        let currentFragments = profile.fragmentCount

        // 1. Check if user has enough fragments
        guard currentFragments >= item.fragmentCost else {
            print("Build failed: Insufficient fragments (\(currentFragments)/\(item.fragmentCost)) for \(item.name).")
            return false
        }

        // 2. Check if an item of this type already exists (optional - allow multiple?)
        // For now, let's assume only one of each buildable type can exist.
        let fetchRequest: NSFetchRequest<SanctumItem> = SanctumItem.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "elementType == %@", item.elementType)
        fetchRequest.fetchLimit = 1

        do {
            let existingItems = try viewContext.fetch(fetchRequest)
            guard existingItems.isEmpty else {
                print("Build failed: Item '\(item.name)' already constructed.")
                // Optionally provide different feedback to the user
                return false
            }
        } catch {
             print("Error checking for existing Sanctum items before building: \(error)")
             return false // Prevent building if check fails
        }


        // 3. Deduct fragments
        profile.fragmentCount -= Int64(item.fragmentCost)

        // 4. Create the new SanctumItem in Core Data
        let newItem = SanctumItem(context: viewContext)
        newItem.id = UUID()
        newItem.elementType = item.elementType // Use the defined type string
        newItem.unlockDate = Date() // Record when it was built

        // 5. Save changes (profile fragments and new item)
        PersistenceController.shared.saveContext()
        print("Build successful: Constructed '\(item.name)' for \(item.fragmentCost) fragments. Remaining: \(profile.fragmentCount)")
        return true
    }
}
