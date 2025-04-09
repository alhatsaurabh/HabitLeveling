// MARK: - File: DashboardViewModel.swift
// Update: Restored missing method/property implementations.

import SwiftUI
import CoreData
import Combine

// Assume StatCategory enum exists GLOBALLY
// Assume Notification Names are defined (e.g., in HabitTrackingManager.swift)
// Assume PersistenceController exists
// Assume all Managers exist (Leveling, EssenceCore, Gate, Stats, HabitTracking)

class DashboardViewModel: ObservableObject {
    // --- Properties ---
    @Published var userLevel: Int = 1
    @Published var userXP: Int = 0
    @Published var xpGoal: Int = 100
    @Published var essenceCoreState: String = "Dim"
    @Published var manaCrystals: Int = 0 // Assuming this exists on UserProfile
    @Published var hunterRank: String = "Rank E"
    @Published var overallStreak: Int = 0
    @Published var totalCompletions: Int = 0
    @Published var job: String = "Unspecialized"
    @Published var title: String = "Novice"
    @Published var selectedCategory: String? = nil
    @Published var activeHabits: [Habit] = []
    @Published var statPoints: [String: Int64] = [:]

    // Filter categories based on the global StatCategory enum
    let filterCategories: [String] = ["All"] + StatCategory.allCases.map { $0.rawValue }

    // Subject for level up events, sends the NEW level
    let levelUpSubject = PassthroughSubject<Int, Never>()

    private var viewContext = PersistenceController.shared.container.viewContext
    private var userProfile: UserProfile?
    private var cancellables = Set<AnyCancellable>()

    init() {
        fetchAllData()
        setupNotificationObservers()
    }

    // --- Notification Handling ---
    private func setupNotificationObservers() {
        // Observe Reset Notification
        NotificationCenter.default.publisher(for: .didPerformReset).receive(on: DispatchQueue.main).sink { [weak self] _ in print("DashboardViewModel received reset notification."); self?.fetchAllData() }.store(in: &cancellables)
        // Observe UserProfile Update Notification (e.g., from Settings)
        NotificationCenter.default.publisher(for: .didUpdateUserProfile).receive(on: DispatchQueue.main).sink { [weak self] _ in print("DashboardViewModel received profile update notification."); self?.fetchAllData() }.store(in: &cancellables)
        // Observe Artifact Equip Toggle (Handled by StatsViewModel)
        // NotificationCenter.default.publisher(for: .didToggleArtifactEquipStatus).receive(on: DispatchQueue.main).sink { [weak self] _ in print("DashboardViewModel received artifact equip toggle."); self?.fetchStatPointsData() }.store(in: &cancellables)
    }


    // --- Data Fetching Functions ---
    func fetchAllData() { DispatchQueue.global(qos: .userInitiated).async { [weak self] in guard let self = self else { return }; self.fetchUserProfile(); self.fetchHabits(); self.fetchOverallStats(); self.fetchStatPointsData(); DispatchQueue.main.async { if let profile = self.userProfile { EssenceCoreManager.shared.updateCoreState(for: profile); print("DashboardViewModel: Updated Essence Core state.") } }; print("DashboardViewModel: fetchAllData complete (background).") } }

    // --- RESTORED: fetchHabits ---
    func fetchHabits() {
        let request: NSFetchRequest<Habit> = Habit.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Habit.creationDate, ascending: true)]
        // Example predicate: Fetch only habits NOT marked as archived (if you add such a property)
        // request.predicate = NSPredicate(format: "isArchived == NO")
        do {
            let fetchedHabits = try viewContext.fetch(request)
            DispatchQueue.main.async {
                self.activeHabits = fetchedHabits
                // print("DashboardViewModel: Fetched \(fetchedHabits.count) active habits.") // Debug log
            }
        } catch {
            print("Error fetching habits: \(error)")
            DispatchQueue.main.async {
                self.activeHabits = [] // Reset on error
            }
        }
    }
    // --- END RESTORED ---

    // --- RESTORED: fetchUserProfile ---
    func fetchUserProfile() {
        let fetchRequest: NSFetchRequest<UserProfile> = UserProfile.fetchRequest()
        fetchRequest.fetchLimit = 1
        var profileData: (level: Int, xp: Int, xpGoal: Int, rank: String, job: String, title: String, essenceState: String, manaCrystals: Int, profile: UserProfile?)? = nil
        do {
            if let profile = try viewContext.fetch(fetchRequest).first {
                let fetchedLevel = Int(profile.level)
                let fetchedXp = Int(profile.xp)
                let fetchedXpGoal = Int(LevelingManager.shared.calculateXPForNextLevel(level: fetchedLevel))
                let fetchedRank = calculateHunterRank(level: fetchedLevel) // Use helper
                let fetchedJob = profile.job ?? "Unspecialized"
                let fetchedTitle = profile.title ?? "Novice"
                let fetchedEssenceState = profile.essenceCoreState ?? "Dim"
                let fetchedManaCrystals = Int(profile.manaCrystals) // Assuming manaCrystals exists
                profileData = (fetchedLevel, fetchedXp, fetchedXpGoal, fetchedRank, fetchedJob, fetchedTitle, fetchedEssenceState, fetchedManaCrystals, profile)
                 // print("DashboardViewModel: Fetched UserProfile - Level \(fetchedLevel)") // Debug log
            } else {
                print("No UserProfile found. Creating default.")
                // Ensure creation happens on main thread if it modifies published properties directly
                // But here we set profileData, update happens later on main thread
                 if self.userProfile == nil { // Avoid potential race condition if called multiple times
                    let defaultProfile = self.createDefaultUserProfile() // Create and save default
                    profileData = (1, 0, 100, "Rank E", "Unspecialized", "Novice", "Dim", 0, defaultProfile)
                 }
            }
        } catch {
            print("Error fetching UserProfile: \(error)")
            // Set defaults on main thread
            DispatchQueue.main.async {
                 self.userProfile = nil; self.userLevel = 1; self.userXP = 0; self.xpGoal = 100; self.hunterRank = "Rank E"; self.job = "Unspecialized"; self.title = "Novice"; self.essenceCoreState = "Dim"; self.manaCrystals = 0
            }
            return // Exit if fetch fails
        }
        // Update published properties on the main thread
        DispatchQueue.main.async {
            if let data = profileData {
                self.userProfile = data.profile
                self.userLevel = data.level
                self.userXP = data.xp
                self.xpGoal = data.xpGoal
                self.hunterRank = data.rank
                self.job = data.job
                self.title = data.title
                self.essenceCoreState = data.essenceState
                self.manaCrystals = data.manaCrystals
            }
        }
    }
    // --- END RESTORED ---

    // --- RESTORED: fetchOverallStats ---
    func fetchOverallStats() {
        let logFetchRequest: NSFetchRequest<HabitLog> = HabitLog.fetchRequest()
        var fetchedTotalCompletions = 0
        do {
            // Note: This counts ALL logs. If logs should be user-specific, add a predicate.
            fetchedTotalCompletions = try viewContext.count(for: logFetchRequest)
        } catch {
            print("DashboardViewModel: Error fetching total completions count: \(error)")
            fetchedTotalCompletions = 0
        }

        // Assuming StatsManager is accessible
        let fetchedOverallStreak = StatsManager.shared.calculateOverallStreak(context: viewContext)

        // Update published properties on the main thread
        DispatchQueue.main.async {
            self.totalCompletions = fetchedTotalCompletions
            self.overallStreak = fetchedOverallStreak
             // print("DashboardViewModel: Fetched Aggregate Stats - Completions: \(fetchedTotalCompletions), Streak: \(fetchedOverallStreak)") // Debug log
        }
    }
    // --- END RESTORED ---

    // --- RESTORED: fetchStatPointsData ---
    private func fetchStatPointsData() {
        // Assuming StatsManager is accessible
        let calculatedPoints = StatsManager.shared.calculateStatPoints(context: viewContext)
        // Update published property on the main thread
        DispatchQueue.main.async {
            self.statPoints = calculatedPoints
            print("DashboardViewModel: Updated stat points.")
        }
    }
    // --- END RESTORED ---

    // --- RESTORED: createDefaultUserProfile ---
    private func createDefaultUserProfile() -> UserProfile? {
        let context = self.viewContext // Use instance context
        let newProfile = UserProfile(context: context)
        newProfile.level = 1
        newProfile.xp = 0
        newProfile.manaCrystals = 0 // Initialize mana crystals
        newProfile.essenceCoreState = "Dim" // Initialize essence state
        newProfile.job = "Unspecialized"
        newProfile.title = "Novice"
        // Initialize other UserProfile attributes as needed

        // Save the context after creating the profile
        do {
            try context.save()
            print("Default UserProfile created and saved.")
            return newProfile
        } catch {
            print("Error saving default UserProfile: \(error)")
            context.rollback() // Rollback on error
            return nil
        }
    }
    // --- END RESTORED ---

    // --- Computed Properties & Helpers ---
    // --- RESTORED: filteredDueHabits ---
    var filteredDueHabits: [Habit] {
        return activeHabits.filter { habit in
            let isDue = isHabitDueNow(habit) // Check if due first
            guard isDue else { return false }

            // Apply category filter if one is selected (and not "All")
            if let selected = selectedCategory, selected != "All" {
                // Ensure comparison handles potential nil statCategory on habit
                return habit.statCategory == selected
            } else {
                // No category filter or "All" selected, include if due
                return true
            }
        }
    }
    // --- END RESTORED ---

    // --- RESTORED: isHabitDueNow ---
    private func isHabitDueNow(_ habit: Habit) -> Bool {
        let today = Date()
        let calendar = Calendar.current

        guard let lastCompletion = habit.lastCompletedDate else {
            // Never completed, so it's due
            return true
        }

        // Check based on frequency
        switch habit.frequency {
        case "Daily":
            // Due if not completed today
            return !calendar.isDateInToday(lastCompletion)
        case "Weekly":
            // Due if not completed this week (using weekOfYear comparison)
            return !calendar.isDate(lastCompletion, equalTo: today, toGranularity: .weekOfYear)
        // Add cases for "Monthly", specific weekdays, etc. if needed
        // case "Monthly":
        //     return !calendar.isDate(lastCompletion, equalTo: today, toGranularity: .month)
        default:
            print("Warning: Unknown habit frequency '\(habit.frequency ?? "")' for habit '\(habit.name ?? "")'. Assuming not due.")
            return false // Don't show habits with unknown frequency
        }
    }
    // --- END RESTORED ---

    // --- RESTORED: calculateHunterRank ---
    private func calculateHunterRank(level: Int) -> String {
        switch level {
        case 1..<10: return "Rank E"
        case 10..<25: return "Rank D"
        case 25..<45: return "Rank C"
        case 45..<70: return "Rank B"
        case 70..<100: return "Rank A"
        case 100...: return "Rank S" // Or higher ranks like National, Monarch...
        default: return "Rank E" // Default for level 0 or less
        }
    }
    // --- END RESTORED ---

    // --- Actions ---

    // completeHabit (Uses returned level from LevelingManager)
    func completeHabit(habit: Habit) {
        print("--- completeHabit START for: \(habit.name ?? "Unknown") ---")
        guard let profile = userProfile else {
            print("Error completing habit: UserProfile not loaded."); fetchUserProfile();
             guard let recoveredProfile = self.userProfile else { print("--- completeHabit END (Recovery Failed) ---"); return }
             completeHabitInternal(habit: habit, profile: recoveredProfile)
             return
        }
        completeHabitInternal(habit: habit, profile: profile)
    }

    // Internal function (Uses returned level from LevelingManager)
    private func completeHabitInternal(habit: Habit, profile: UserProfile) {
        HabitTrackingManager.shared.completeHabit(habit) // Handles log, streak, awards, saves context
        let xpGained = Int(habit.xpValue)
        let finalLevelReached: Int? = LevelingManager.shared.addXP(to: profile, amount: xpGained, context: viewContext) // Handles level up, saves context
        EssenceCoreManager.shared.updateCoreState(for: profile) // Update essence based on potentially changed profile
        // Refresh ViewModel data AFTER managers have potentially modified profile and saved
        fetchAllData()
        // Trigger Level Up Notification *using the returned level*
        if let newLevel = finalLevelReached {
            print("Level up occurred! New level reported by LevelingManager: \(newLevel). Triggering level up subject.")
             if let currentProfile = self.userProfile { GateManager.shared.checkForUnlocks(for: currentProfile) } else { print("Error: UserProfile nil when checking gate unlocks.") }
            levelUpSubject.send(newLevel) // Send correct level
        } else {
            print("No level up occurred.")
        }
        print("--- completeHabit END for: \(habit.name ?? "Unknown") ---")
    }


    // Delete Habit
    func deleteHabit(_ habit: Habit) {
        print("Attempting to delete habit: \(habit.name ?? "Unknown")"); viewContext.delete(habit)
        do {
            try viewContext.save(); print("Habit deleted successfully.")
            // Refresh data after delete
            fetchHabits()
            fetchOverallStats()
            fetchStatPointsData()
            // Post notification if other parts of the app need to know
            // NotificationCenter.default.post(name: .didModifyHabits, object: nil)
        } catch { print("Error deleting habit: \(error.localizedDescription)"); viewContext.rollback() }
    }
}

// MARK: - Assumptions
// Assume StatCategory enum exists GLOBALLY, is String raw value, and conforms to CaseIterable.
// Assume all Managers (HabitTracking, Leveling, EssenceCore, Gate, Stats) exist.
// Assume Notification Names defined.
// Assume PersistenceController exists.
