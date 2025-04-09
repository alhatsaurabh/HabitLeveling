// MARK: - File: StatsViewModel.swift
// Purpose: ViewModel for the Stats screen.
// Update: Added observer for artifact equip status changes to refresh stat points.

import SwiftUI
import CoreData
import Combine

// Assuming Notification.Name.didToggleArtifactEquipStatus is defined elsewhere
// (e.g., in StatsView.swift or a dedicated Notifications file)
// extension Notification.Name {
//     static let didToggleArtifactEquipStatus = Notification.Name("didToggleArtifactEquipStatus")
// }

class StatsViewModel: ObservableObject {
    // MARK: - Published Properties

    @Published var level: Int = 0
    @Published var xp: Int = 0
    @Published var xpGoal: Int = 100 // Default, updated by fetch
    @Published var hunterRank: String = "Rank E"
    @Published var overallStreak: Int = 0
    @Published var totalCompletions: Int = 0
    @Published var job: String = "Unspecialized"
    @Published var title: String = "Novice"
    @Published var statPoints: [String: Int64] = [:] // e.g., ["STR": 150, "INT": 120]

    // MARK: - Private Properties

    private var viewContext = PersistenceController.shared.container.viewContext
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initializer

    init() {
        fetchData() // Fetch data on initialization
        setupNotificationObservers()
    }

    // MARK: - Notification Handling

    private func setupNotificationObservers() {
        // Observe Reset Notification
        NotificationCenter.default.publisher(for: .didPerformReset)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                print("StatsViewModel received reset notification.")
                self?.fetchData() // Refetch all data on reset
            }
            .store(in: &cancellables)

        // Observe UserProfile Update Notification
        NotificationCenter.default.publisher(for: .didUpdateUserProfile)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                print("StatsViewModel received profile update notification.")
                self?.fetchData() // Refetch all data for simplicity
            }
            .store(in: &cancellables)

        // --- NEW: Observe Artifact Equip Status Toggle ---
        NotificationCenter.default.publisher(for: .didToggleArtifactEquipStatus)
            .receive(on: DispatchQueue.main) // Ensure UI updates happen on main thread
            .sink { [weak self] _ in
                print("StatsViewModel received artifact equip toggle notification.")
                // Refetch only the stat points data, as that's what's affected
                self?.fetchStatPointsData()
            }
            .store(in: &cancellables)
        // --- END NEW ---

        // Consider adding observer for habit completion if needed
    }

    // MARK: - Data Fetching Methods

    /// Fetches all necessary data for the Stats view.
    func fetchData() {
        // Use a background thread for potentially heavy fetches
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            self.fetchBaseStats()      // Fetches UserProfile data
            self.fetchAggregateStats() // Fetches streak, total completions
            self.fetchStatPointsData() // Fetches mapped stat points for radar chart
            print("StatsViewModel: fetchData complete (background).")
        }
    }

    /// Fetches stats directly from the UserProfile entity. (Runs on background thread)
    private func fetchBaseStats() {
        // ... (implementation remains the same) ...
        let context = self.viewContext; let fetchRequest: NSFetchRequest<UserProfile> = UserProfile.fetchRequest(); fetchRequest.fetchLimit = 1; var profileData: (level: Int, xp: Int, xpGoal: Int, rank: String, job: String, title: String)? = nil
        do { if let profile = try context.fetch(fetchRequest).first { let fetchedLevel = Int(profile.level); let fetchedXp = Int(profile.xp); let fetchedXpGoal = Int(LevelingManager.shared.calculateXPForNextLevel(level: fetchedLevel)); let fetchedRank = self.calculateHunterRank(level: fetchedLevel); let fetchedJob = profile.job ?? "Unspecialized"; let fetchedTitle = profile.title ?? "Novice"; profileData = (fetchedLevel, fetchedXp, fetchedXpGoal, fetchedRank, fetchedJob, fetchedTitle) } else { print("StatsViewModel: UserProfile not found."); profileData = (1, 0, 100, "Rank E", "Unspecialized", "Novice") } } catch { print("StatsViewModel: Error fetching UserProfile: \(error)"); profileData = (1, 0, 100, "Rank E", "Unspecialized", "Novice") }
        DispatchQueue.main.async { if let data = profileData { self.level = data.level; self.xp = data.xp; self.xpGoal = data.xpGoal; self.hunterRank = data.rank; self.job = data.job; self.title = data.title } }
    }

    /// Fetches aggregated stats like total completions and overall streak. (Runs on background thread)
    private func fetchAggregateStats() {
        // ... (implementation remains the same) ...
        let context = self.viewContext; let logFetchRequest: NSFetchRequest<HabitLog> = HabitLog.fetchRequest(); var fetchedTotalCompletions = 0
        do { fetchedTotalCompletions = try context.count(for: logFetchRequest) } catch { print("StatsViewModel: Error fetching total completions count: \(error)"); fetchedTotalCompletions = 0 }
        let fetchedOverallStreak = StatsManager.shared.calculateOverallStreak(context: context)
        DispatchQueue.main.async { self.totalCompletions = fetchedTotalCompletions; self.overallStreak = fetchedOverallStreak }
    }

    /// Fetches mapped stat points data for the radar chart. (Runs on background thread)
    private func fetchStatPointsData() {
        print("StatsViewModel: Fetching stat points data...") // Add log
        let context = self.viewContext
        // Calculate points using StatsManager (includes artifact boosts now)
        let calculatedPoints = StatsManager.shared.calculateStatPoints(context: context)

        // Update published property on the main thread
        DispatchQueue.main.async {
            print("StatsViewModel: Updating published stat points.") // Add log
            self.statPoints = calculatedPoints
        }
    }

    // MARK: - Helper Methods

    /// Calculates hunter rank string based on level.
    private func calculateHunterRank(level: Int) -> String {
        // ... (implementation remains the same) ...
        switch level { case 1..<10: return "Rank E"; case 10..<25: return "Rank D"; case 25..<45: return "Rank C"; case 45..<70: return "Rank B"; case 70..<100: return "Rank A"; case 100...: return "Rank S"; default: return "Rank E" }
    }
}

// MARK: - Assumptions for Compilation
// (Same as before)
