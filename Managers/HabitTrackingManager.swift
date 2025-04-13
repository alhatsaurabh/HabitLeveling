import Foundation
import CoreData

// --- Consolidated Notification Name Definitions ---
extension Notification.Name {
    /// Posted when an artifact is first earned by the user. UserInfo contains ["artifactName": String].
    static let didEarnArtifact = Notification.Name("didEarnArtifact")
    /// Posted when an artifact's equipped status is successfully toggled. UserInfo is nil.
    static let didToggleArtifactEquipStatus = Notification.Name("didToggleArtifactEquipStatus")
    // Add other app-wide notification names here if desired
    // static let didPerformReset = Notification.Name("didPerformReset")
    // static let didUpdateUserProfile = Notification.Name("didUpdateUserProfile")
    static let habitStatusChanged = Notification.Name("habitStatusChanged")
    static let habitStatsChanged = Notification.Name("habitStatsChanged")
    static let habitAdded = Notification.Name("habitAdded")
    static let habitCompleted = Notification.Name("habitCompleted")
}
// --- END DEFINITIONS ---

class HabitTrackingManager {
    static let shared = HabitTrackingManager()
    private init() {}

    /**
     Marks a habit as completed, updates streak, logs completion,
     grants mana, and checks for/awards multiple artifacts based on conditions.
     */
    func completeHabit(_ habit: Habit, date: Date = Date()) {
        let viewContext = PersistenceController.shared.container.viewContext

        // --- Update Streak ---
        var potentialStreak = habit.streak; if let lastCompletion = habit.lastCompletedDate { if Calendar.current.isDateInYesterday(lastCompletion) { potentialStreak += 1 } else if !Calendar.current.isDateInToday(lastCompletion) { potentialStreak = 1 } else { print("Habit '\(habit.name ?? "")' already completed today."); return } } else { potentialStreak = 1 }; habit.streak = potentialStreak; habit.lastCompletedDate = date; print("Habit '\(habit.name ?? "")' completed. New streak: \(habit.streak)")

        // --- Log Completion ---
        let logEntry = HabitLog(context: viewContext)
        logEntry.habitID = habit.id
        logEntry.completionDate = date

        // --- Fetch User Profile (Needed for Mana and Artifact Awarding) ---
        let profileFetchRequest: NSFetchRequest<UserProfile> = UserProfile.fetchRequest()
        profileFetchRequest.fetchLimit = 1
        var userProfile: UserProfile? = nil
        do { userProfile = try viewContext.fetch(profileFetchRequest).first } catch { print("Error fetching UserProfile: \(error)") }
        guard let profile = userProfile else { print("Error: UserProfile not found."); PersistenceController.shared.saveContext(); return }

        // --- Grant Mana Crystals ---
        print("INFO: Mana crystal awarding logic placeholder.")

        // --- Check and Award Artifacts ---
        checkAndAwardArtifacts(context: viewContext, profile: profile, completedHabit: habit)

        // --- Save Changes ---
        PersistenceController.shared.saveContext()
        
        // --- Post Notification for Calendar Update ---
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .habitCompleted, object: nil, userInfo: ["habitID": habit.id?.uuidString ?? ""])
        }
        
        print("Habit completion and related updates saved.")
    }


    /**
     Checks conditions for multiple artifacts and awards them if criteria are met
     and the user doesn't already own them. Posts notifications.
     */
    private func checkAndAwardArtifacts(context: NSManagedObjectContext, profile: UserProfile, completedHabit: Habit) {
        // ... (Implementation remains the same as in previous version) ...
         print("Checking artifact conditions...")
         let currentLevel = Int(profile.level); print("   Checking conditions for Level \(currentLevel)")
         let logFetchRequest: NSFetchRequest<HabitLog> = HabitLog.fetchRequest(); var totalCompletions = 0
         do { totalCompletions = try context.count(for: logFetchRequest) } catch { print("Error fetching log count: \(error)") }
         if totalCompletions == 1 { print("   Condition potentially met: First completion."); attemptToAwardArtifact(named: "Badge of the Initiate", context: context, profile: profile) }
         if currentLevel >= 10 { print("   Condition potentially met: Level 10+ reached (Level \(currentLevel))."); attemptToAwardArtifact(named: "Circlet of Clarity", context: context, profile: profile) }
         guard let categoryRawValue = completedHabit.statCategory, let category = StatCategory(rawValue: categoryRawValue), category != .other else { print("   Skipping category count check."); return }
         var categoryCompletions = 0
         do { let allLogsFetch: NSFetchRequest<HabitLog> = HabitLog.fetchRequest(); let allLogs = try context.fetch(allLogsFetch); let habitFetchRequest: NSFetchRequest<Habit> = Habit.fetchRequest(); habitFetchRequest.propertiesToFetch = ["id", "statCategory"]; let allHabits = try context.fetch(habitFetchRequest); let habitCategoryMap = Dictionary(uniqueKeysWithValues: allHabits.compactMap { h -> (UUID, String)? in guard let id = h.id, let cat = h.statCategory else { return nil }; return (id, cat) }); categoryCompletions = allLogs.filter { log in guard let logHabitID = log.habitID else { return false }; return habitCategoryMap[logHabitID] == categoryRawValue }.count; print("   Total completions found for category '\(categoryRawValue)': \(categoryCompletions)")
             if category == .body && categoryCompletions >= 5 { print("   Condition potentially met: 5+ Body completions (\(categoryCompletions))."); attemptToAwardArtifact(named: "Stone of Minor Vigor", context: context, profile: profile) }
             if category == .skill && categoryCompletions >= 10 { print("   Condition potentially met: 10+ Skill completions (\(categoryCompletions))."); attemptToAwardArtifact(named: "Adept's Training Band", context: context, profile: profile) }
         } catch { print("   Error fetching logs/habits for category count: \(error)") }
        print("Finished checking artifact conditions.")
    }


    /**
     Helper function to fetch an artifact by name, check ownership,
     create the UserArtifact if not owned, and post a notification.
     */
    private func attemptToAwardArtifact(named name: String, context: NSManagedObjectContext, profile: UserProfile) {
        // ... (Implementation remains the same - Uses .didEarnArtifact) ...
        let artifactFetchRequest: NSFetchRequest<Artifact> = Artifact.fetchRequest(); artifactFetchRequest.predicate = NSPredicate(format: "name == %@", name); artifactFetchRequest.fetchLimit = 1
        do {
            guard let artifactToAward = try context.fetch(artifactFetchRequest).first else { print("AttemptAward Failed: Find artifact '\(name)'."); return }
            let ownershipCheckRequest: NSFetchRequest<UserArtifact> = UserArtifact.fetchRequest(); ownershipCheckRequest.predicate = NSPredicate(format: "profile == %@ AND artifact == %@", profile, artifactToAward); ownershipCheckRequest.fetchLimit = 1
            let existingCount = try context.count(for: ownershipCheckRequest)
            guard existingCount == 0 else { return } // Already owns it
            print("Awarding '\(name)'..."); let newUserArtifact = UserArtifact(context: context); newUserArtifact.id = UUID(); newUserArtifact.acquiredDate = Date(); newUserArtifact.isEquipped = false; newUserArtifact.profile = profile; newUserArtifact.artifact = artifactToAward
            DispatchQueue.main.async { print("Posting didEarnArtifact notification for: \(name)"); NotificationCenter.default.post( name: .didEarnArtifact, object: nil, userInfo: ["artifactName": name] ) } // Use .didEarnArtifact
            print("'\(name)' awarded successfully! (Will be saved shortly)")
        } catch { print("AttemptAward Error: Failed fetching artifact '\(name)' or checking ownership: \(error)") }
    }
}
