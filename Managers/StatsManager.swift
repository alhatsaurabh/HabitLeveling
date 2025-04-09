// MARK: - File: StatsManager.swift
// Purpose: Central place for calculating user stats.
// Update: Modified calculateStatPoints to include boosts from equipped artifacts.

import Foundation
import CoreData

class StatsManager {
    // MARK: - Singleton Setup
    static let shared = StatsManager()
    private init() {} // Private initializer for singleton

    // MARK: - Streak Calculation
    // (calculateOverallStreak function remains the same)
    func calculateOverallStreak(context: NSManagedObjectContext) -> Int {
        // ... (Existing streak calculation logic) ...
        let logFetchRequest: NSFetchRequest<HabitLog> = HabitLog.fetchRequest()
        logFetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \HabitLog.completionDate, ascending: false)]
        do {
            let logs = try context.fetch(logFetchRequest)
            guard !logs.isEmpty else { return 0 }
            let calendar = Calendar.current
            var uniqueCompletionDays = Set<DateComponents>()
            for log in logs { if let date = log.completionDate { uniqueCompletionDays.insert(calendar.dateComponents([.year, .month, .day], from: date)) } }
            var currentStreak = 0; var checkDate = Date()
            let todayComponents = calendar.dateComponents([.year, .month, .day], from: checkDate)
            if uniqueCompletionDays.contains(todayComponents) { currentStreak = 1 } else { guard let yesterday = calendar.date(byAdding: .day, value: -1, to: checkDate) else { return 0 }; let yesterdayComponents = calendar.dateComponents([.year, .month, .day], from: yesterday); if uniqueCompletionDays.contains(yesterdayComponents) { currentStreak = 1; checkDate = yesterday } else { return 0 } }
            while true { guard let previousDay = calendar.date(byAdding: .day, value: -1, to: checkDate) else { break }; let previousDayComponents = calendar.dateComponents([.year, .month, .day], from: previousDay); if uniqueCompletionDays.contains(previousDayComponents) { currentStreak += 1; checkDate = previousDay } else { break } }
            return currentStreak
        } catch { print("StatsManager: Error calculating overall streak: \(error)"); return 0 }
    }

    // MARK: - Category Streak Calculation
    func calculateStreak(forCategory category: String, context: NSManagedObjectContext) -> Int {
        print("StatsManager: Calculating streak for category: \(category)")
        
        // Fetch habits in the specified category
        let habitFetchRequest: NSFetchRequest<Habit> = Habit.fetchRequest()
        habitFetchRequest.predicate = NSPredicate(format: "statCategory == %@", category)
        habitFetchRequest.propertiesToFetch = ["id"]
        
        var habitIDs: [UUID] = []
        do {
            let habits = try context.fetch(habitFetchRequest)
            habitIDs = habits.compactMap { $0.id }
            print("   Found \(habitIDs.count) habits in category '\(category)'")
        } catch {
            print("   Error fetching habits for category: \(error)")
            return 0
        }
        
        // Fetch logs for these habits
        let logFetchRequest: NSFetchRequest<HabitLog> = HabitLog.fetchRequest()
        logFetchRequest.predicate = NSPredicate(format: "habitID IN %@", habitIDs)
        logFetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \HabitLog.completionDate, ascending: false)]
        
        do {
            let logs = try context.fetch(logFetchRequest)
            guard !logs.isEmpty else { return 0 }
            
            let calendar = Calendar.current
            var uniqueCompletionDays = Set<DateComponents>()
            
            // Collect unique completion days
            for log in logs {
                if let date = log.completionDate {
                    uniqueCompletionDays.insert(calendar.dateComponents([.year, .month, .day], from: date))
                }
            }
            
            // Calculate streak
            var currentStreak = 0
            var checkDate = Date()
            let todayComponents = calendar.dateComponents([.year, .month, .day], from: checkDate)
            
            // Check if there's a completion today
            if uniqueCompletionDays.contains(todayComponents) {
                currentStreak = 1
            } else {
                // Check yesterday
                guard let yesterday = calendar.date(byAdding: .day, value: -1, to: checkDate) else { return 0 }
                let yesterdayComponents = calendar.dateComponents([.year, .month, .day], from: yesterday)
                if uniqueCompletionDays.contains(yesterdayComponents) {
                    currentStreak = 1
                    checkDate = yesterday
                } else {
                    return 0
                }
            }
            
            // Count backwards
            while true {
                guard let previousDay = calendar.date(byAdding: .day, value: -1, to: checkDate) else { break }
                let previousDayComponents = calendar.dateComponents([.year, .month, .day], from: previousDay)
                if uniqueCompletionDays.contains(previousDayComponents) {
                    currentStreak += 1
                    checkDate = previousDay
                } else {
                    break
                }
            }
            
            print("   Category streak: \(currentStreak) days")
            return currentStreak
        } catch {
            print("   Error calculating category streak: \(error)")
            return 0
        }
    }

    // MARK: - Mapped Stat Point Calculation (with Artifact Boosts)

    // Calculates the total points for display stats (STR, INT, etc.)
    // based on completed habits AND boosts from equipped artifacts.
    // Returns a dictionary mapping display stat names (String) to total points (Int64).
    func calculateStatPoints(context: NSManagedObjectContext) -> [String: Int64] {
        print("StatsManager: Calculating mapped stat points (including artifact boosts)...")
        // Initialize points for the 5 display stats
        var displayPoints: [String: Int64] = [
            "STR": 0, "INT": 0, "PER": 0, "AGI": 0, "VIT": 0
        ]

        // --- Step 1: Calculate Base Points from Habit Logs ---
        print("   Calculating base points from logs...")
        // --- Step 1a: Fetch Habits and map by ID ---
        let habitFetchRequest: NSFetchRequest<Habit> = Habit.fetchRequest()
        habitFetchRequest.propertiesToFetch = ["id", "statCategory", "xpValue"]
        var habitMap: [UUID: (category: StatCategory?, xp: Int64)] = [:]
        do {
            let habits = try context.fetch(habitFetchRequest)
            for habit in habits {
                guard let id = habit.id else { continue }
                let categoryEnum = StatCategory(rawValue: habit.statCategory ?? "")
                habitMap[id] = (category: categoryEnum, xp: habit.xpValue)
            }
            print("      Mapped \(habitMap.count) habits.")
        } catch {
            print("      Error fetching habits for stat calculation: \(error)")
            // Proceed without habit data if fetch fails, points will be 0 + artifact boosts
        }

        // --- Step 1b: Fetch HabitLogs ---
        let logFetchRequest: NSFetchRequest<HabitLog> = HabitLog.fetchRequest()
        logFetchRequest.propertiesToFetch = ["habitID"]
        do {
            let logs = try context.fetch(logFetchRequest)
            print("      Processing \(logs.count) habit logs.")

            // --- Step 1c: Iterate logs and distribute points based on mapping ---
            for log in logs {
                guard let habitID = log.habitID, let habitInfo = habitMap[habitID], let category = habitInfo.category else {
                    continue // Skip logs without valid habitID or category
                }
                let xp = habitInfo.xp // XP value for this completed habit

                // Apply the approved mapping logic
                switch category {
                case .mind:
                    displayPoints["INT", default: 0] += xp
                    displayPoints["PER", default: 0] += xp
                case .body:
                    displayPoints["STR", default: 0] += xp
                    displayPoints["AGI", default: 0] += xp
                case .skill:
                    displayPoints["AGI", default: 0] += xp
                    displayPoints["INT", default: 0] += xp
                case .discipline:
                    displayPoints["VIT", default: 0] += xp
                    displayPoints["STR", default: 0] += xp
                case .wellbeing:
                    displayPoints["PER", default: 0] += xp
                    displayPoints["VIT", default: 0] += xp
                case .other:
                    break // Ignore 'Other' category
                }
            }
        } catch {
            print("      Error fetching habit logs for stat calculation: \(error)")
            // Continue to artifact calculation even if log processing fails
        }
        print("   Base points from logs calculated: \(displayPoints)")


        // --- Step 2: Calculate and Add Artifact Boosts ---
        print("   Calculating artifact boosts...")
        var artifactBoosts: [String: Double] = [:] // Store raw boosts by StatCategory rawValue

        // --- Step 2a: Fetch UserProfile ---
        let profileFetchRequest: NSFetchRequest<UserProfile> = UserProfile.fetchRequest()
        profileFetchRequest.fetchLimit = 1
        guard let userProfile = try? context.fetch(profileFetchRequest).first else {
            print("      Error: UserProfile not found. Cannot apply artifact boosts.")
            // Return only points calculated from logs if profile not found
            return displayPoints
        }

        // --- Step 2b: Fetch Equipped UserArtifacts ---
        let equippedFetchRequest: NSFetchRequest<UserArtifact> = UserArtifact.fetchRequest()
        equippedFetchRequest.predicate = NSPredicate(format: "profile == %@ AND isEquipped == YES", userProfile)
        // Fetch relationship data efficiently
        equippedFetchRequest.relationshipKeyPathsForPrefetching = ["artifact"]

        do {
            let equippedArtifacts = try context.fetch(equippedFetchRequest)
            print("      Found \(equippedArtifacts.count) equipped artifacts.")

            // --- Step 2c: Calculate Total Boosts per StatCategory ---
            for userArtifact in equippedArtifacts {
                guard let artifact = userArtifact.artifact, // Ensure artifact relationship is valid
                      let boostType = artifact.statBoostType, // String like "Body"
                      !boostType.isEmpty,
                      artifact.statBoostValue != 0 else { continue } // Skip if no boost type or value

                // Add boost value to the dictionary, summing if category already exists
                artifactBoosts[boostType, default: 0.0] += artifact.statBoostValue
            }
            print("      Raw artifact boosts calculated: \(artifactBoosts)")

            // --- Step 2d: Map Artifact Boosts to Display Stats (STR, AGI, etc.) ---
            var mappedBoostPoints: [String: Int64] = [:] // e.g., ["STR": 1, "AGI": 1]
            for (categoryRawValue, totalBoost) in artifactBoosts {
                guard let category = StatCategory(rawValue: categoryRawValue) else {
                    print("      Warning: Unknown StatCategory rawValue '\(categoryRawValue)' found in artifact boost type.")
                    continue
                }
                // Round the boost value to the nearest whole number and convert to Int64
                let boostPoints = Int64(totalBoost.rounded())
                guard boostPoints != 0 else { continue } // Skip if rounded boost is zero

                // Apply the same mapping logic as habit XP
                switch category {
                case .mind:
                    mappedBoostPoints["INT", default: 0] += boostPoints
                    mappedBoostPoints["PER", default: 0] += boostPoints
                case .body:
                    mappedBoostPoints["STR", default: 0] += boostPoints
                    mappedBoostPoints["AGI", default: 0] += boostPoints
                case .skill:
                    mappedBoostPoints["AGI", default: 0] += boostPoints
                    mappedBoostPoints["INT", default: 0] += boostPoints
                case .discipline:
                    mappedBoostPoints["VIT", default: 0] += boostPoints
                    mappedBoostPoints["STR", default: 0] += boostPoints
                case .wellbeing:
                    mappedBoostPoints["PER", default: 0] += boostPoints
                    mappedBoostPoints["VIT", default: 0] += boostPoints
                case .other:
                    break // Ignore 'Other' category boosts
                }
            }
            print("      Mapped artifact boost points: \(mappedBoostPoints)")

            // --- Step 2e: Add Mapped Boosts to Base Points from Logs ---
            for (statKey, boost) in mappedBoostPoints {
                displayPoints[statKey, default: 0] += boost
            }
            print("   Added artifact boosts to base points.")

        } catch {
            print("      Error fetching or processing equipped artifacts: \(error)")
            // Return points calculated from logs only if artifact processing fails
        }
        // --- END Artifact Boost Calculation ---

        print("   Final stat points (including artifact boosts): \(displayPoints)")
        return displayPoints
    }
}
