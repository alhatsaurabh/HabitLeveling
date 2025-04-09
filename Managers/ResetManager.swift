
import Foundation
import CoreData
import Combine

// Define Notification Names
extension Notification.Name {
    static let didPerformReset = Notification.Name("didPerformReset")
    // --- NEW Notification Name ---
    static let didUpdateUserProfile = Notification.Name("didUpdateUserProfile")
}

class ResetManager {
    static let shared = ResetManager()
    private init() {}

    func performReset(context: NSManagedObjectContext) {
        print("--- Performing Debug Reset ---")
        // 1. Reset UserProfile
        let profileFetchRequest: NSFetchRequest<UserProfile> = UserProfile.fetchRequest(); profileFetchRequest.fetchLimit = 1
        do { if let profile = try context.fetch(profileFetchRequest).first { print("Resetting UserProfile..."); profile.level = 1; profile.xp = 0; profile.manaCrystals = 0; profile.essenceCoreState = "Dim"; profile.job = "Unspecialized"; profile.title = "Novice" } else { print("UserProfile not found, cannot reset.") } } catch { print("Error fetching UserProfile for reset: \(error)") }
        // 2. Delete All Habit Logs
        print("Deleting Habit Logs..."); let logFetchRequest: NSFetchRequest<NSFetchRequestResult> = HabitLog.fetchRequest(); let logDeleteRequest = NSBatchDeleteRequest(fetchRequest: logFetchRequest)
        do { try context.execute(logDeleteRequest); print("Habit Logs deleted.") } catch { print("Error deleting Habit Logs: \(error)") }
        // 3. Delete All Gates
        print("Deleting Gates..."); let gateFetchRequest: NSFetchRequest<NSFetchRequestResult> = GateStatus.fetchRequest(); let gateDeleteRequest = NSBatchDeleteRequest(fetchRequest: gateFetchRequest)
        do { try context.execute(gateDeleteRequest); print("Gates deleted.") } catch { print("Error deleting Gates: \(error)") }
        // 4. Reset Streaks
        print("Resetting Habit Streaks..."); let habitFetchRequest: NSFetchRequest<Habit> = Habit.fetchRequest()
        do { let habits = try context.fetch(habitFetchRequest); for habit in habits { habit.streak = 0; habit.lastCompletedDate = nil }; print("Habit streaks reset.") } catch { print("Error fetching Habits for streak reset: \(error)") }
        // 5. Save Changes
        print("Saving reset context..."); PersistenceController.shared.saveContext()
        // 6. Post Notification
        print("Posting reset notification."); NotificationCenter.default.post(name: .didPerformReset, object: nil) // Use specific name
        // 7. Create initial gate
        GateManager.shared.createInitialGateIfNeeded(context: context)
        print("--- Debug Reset Complete ---")
    }

    // --- NEW Function to Add Crystals (Debug) ---
    func addManaCrystals(amount: Int, context: NSManagedObjectContext) {
        print("--- Debug: Adding \(amount) Mana Crystals ---")
        let profileFetchRequest: NSFetchRequest<UserProfile> = UserProfile.fetchRequest()
        profileFetchRequest.fetchLimit = 1
        do {
            if let profile = try context.fetch(profileFetchRequest).first {
                profile.manaCrystals += Int64(amount)
                PersistenceController.shared.saveContext()
                print("Added \(amount) crystals. New total: \(profile.manaCrystals)")
                // Post notification that profile updated
                NotificationCenter.default.post(name: .didUpdateUserProfile, object: nil)
            } else {
                print("UserProfile not found, cannot add crystals.")
            }
        } catch {
            print("Error fetching UserProfile to add crystals: \(error)")
        }
    }
}
