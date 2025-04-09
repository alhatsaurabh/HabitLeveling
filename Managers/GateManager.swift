// MARK: - File: GateManager.swift (Updated April 3, 2025)
// Restored full implementations for helper functions

import Foundation
import CoreData

class GateManager {
    static let shared = GateManager()
    private init() {}

    // --- Constants ---
    let analysisCost = 10
    let refreshLockedCost = 2
    let refreshAnalyzedCost = 5
    let maxActiveGates = 3

    // Level thresholds
    let unlockLevelD = 10; let unlockLevelC = 25; let unlockLevelB = 45; let unlockLevelA = 70; let unlockLevelS = 100

    // --- Core Functions ---

    func checkForUnlocks(for profile: UserProfile) {
        // (Code remains the same)
        print("GateManager: Checking for unlocks for level \(profile.level).")
        if profile.level >= unlockLevelS { print("    Level \(unlockLevelS)+ reached! S-Rank gates may now appear.") }
        else if profile.level >= unlockLevelA { print("    Level \(unlockLevelA)+ reached! A-Rank gates may now appear.") }
        else if profile.level >= unlockLevelB { print("    Level \(unlockLevelB)+ reached! B-Rank gates may now appear.") }
        else if profile.level >= unlockLevelC { print("    Level \(unlockLevelC)+ reached! C-Rank gates may now appear.") }
        else if profile.level >= unlockLevelD { print("    Level \(unlockLevelD)+ reached! D-Rank gates may now appear.") }
        createInitialGateIfNeeded(context: PersistenceController.shared.container.viewContext)
    }

    func analyzeGate(gate: GateStatus, profile: UserProfile) -> Bool {
        // (Code remains the same - Posts notification)
        let currentCrystals = profile.manaCrystals
        guard gate.status == "Locked" else { print("Analysis failed: Gate status is '\(gate.status ?? "Unknown")'."); return false }
        guard currentCrystals >= analysisCost else { print("Analysis failed: Insufficient Mana Crystals (\(currentCrystals)/\(analysisCost))."); return false }
        profile.manaCrystals -= Int64(analysisCost); profile.totalManaSpent += Int64(analysisCost)
        print("    Incremented totalManaSpent by \(analysisCost). New total spent: \(profile.totalManaSpent)")
        gate.status = "Analyzed"; gate.statusChangeDate = Date()
        // *** Call helper to generate condition/reward ***
        gate.clearConditionDescription = generateClearCondition(rank: gate.gateRank ?? "E")
        gate.rewardDescription = generateRewardDescription(rank: gate.gateRank ?? "E")
        PersistenceController.shared.saveContext()
        NotificationCenter.default.post(name: .didUpdateUserProfile, object: nil) // Post notification
        print("Analysis successful. Gate ID: \(gate.id?.uuidString ?? "N/A"), Condition: \(gate.clearConditionDescription ?? ""), Reward: \(gate.rewardDescription ?? "")")
        return true
    }

    func checkClearCondition(gate: GateStatus, profile: UserProfile, context: NSManagedObjectContext) -> Bool {
        guard gate.status == "Analyzed", let condition = gate.clearConditionDescription else { 
            print("Cannot check condition: Gate not analyzed or condition missing."); 
            return false 
        }
        print("Checking condition: '\(condition)'")
        
        if condition.starts(with: "Reach Level") { 
            let components = condition.components(separatedBy: " ")
            let numericPart = components.last?.filter("0123456789".contains) ?? ""
            guard let requiredLevel = Int(numericPart), requiredLevel > 0 else { 
                print("... invalid level format in condition: \(condition)"); 
                return false 
            }
            let currentLevel = Int(profile.level)
            print("... requires Level \(requiredLevel), current Level \(currentLevel)")
            return currentLevel >= requiredLevel
        } 
        else if condition.starts(with: "Achieve a") && condition.contains("Overall Streak") { 
            let components = condition.components(separatedBy: CharacterSet.decimalDigits.inverted)
            guard let requiredStreakString = components.first(where: { Int($0) != nil }), 
                  let requiredStreak = Int(requiredStreakString), 
                  requiredStreak > 0 else { 
                return false 
            }
            let currentOverallStreak = StatsManager.shared.calculateOverallStreak(context: context)
            print("... requires Streak \(requiredStreak), current Streak \(currentOverallStreak)")
            return currentOverallStreak >= requiredStreak
        } 
        else if condition.starts(with: "Complete") && condition.contains("Quests in the") { 
            let parts = condition.components(separatedBy: CharacterSet.decimalDigits.inverted)
            guard let requiredCountString = parts.first(where: { Int($0) != nil }), 
                  let requiredCount = Int(requiredCountString), 
                  requiredCount > 0 else { 
                return false 
            }
            
            // Extract category name from the condition
            let categoryMatch = condition.range(of: "'(.*?)'", options: .regularExpression)
            guard let categoryName = categoryMatch.map({ String(condition[$0]).replacingOccurrences(of: "'", with: "") }) else { 
                return false 
            }
            
            print("... requires \(requiredCount) Quests in Category '\(categoryName)'.")
            
            // Get all habits in the specified category
            let habitFetchRequest: NSFetchRequest<Habit> = Habit.fetchRequest()
            habitFetchRequest.predicate = NSPredicate(format: "category == %@", categoryName)
            
            do {
                let habits = try context.fetch(habitFetchRequest)
                var totalCompletions = 0
                
                // Count completions for each habit in the category
                for habit in habits {
                    let logFetchRequest: NSFetchRequest<HabitLog> = HabitLog.fetchRequest()
                    logFetchRequest.predicate = NSPredicate(format: "habitID == %@", habit.id! as CVarArg)
                    let logs = try context.fetch(logFetchRequest)
                    totalCompletions += logs.count
                }
                
                print("... Current completions in category '\(categoryName)': \(totalCompletions)")
                return totalCompletions >= requiredCount
            } catch {
                print("Error checking category completions: \(error)")
                return false
            }
        } 
        else if condition.starts(with: "Spend") && condition.contains("Mana Crystals") { 
            let parts = condition.components(separatedBy: CharacterSet.decimalDigits.inverted)
            guard let requiredSpentString = parts.first(where: { Int($0) != nil }), 
                  let requiredSpent = Int(requiredSpentString), 
                  requiredSpent > 0 else { 
                print("... invalid mana spent format in condition."); 
                return false 
            }
            print("... requires spending \(requiredSpent) Mana Crystals.")
            let currentSpent = profile.totalManaSpent
            print("... Current mana spent: \(currentSpent)")
            return currentSpent >= Int64(requiredSpent)
        } 
        else if condition.starts(with: "Maintain a") && condition.contains("streak in any category") {
            let components = condition.components(separatedBy: CharacterSet.decimalDigits.inverted)
            guard let requiredStreakString = components.first(where: { Int($0) != nil }), 
                  let requiredStreak = Int(requiredStreakString), 
                  requiredStreak > 0 else { 
                return false 
            }
            
            // Check streaks for all categories
            let categories = ["Body", "Mind", "Spirit", "Social", "Emotional"]
            for category in categories {
                let streak = StatsManager.shared.calculateStreak(forCategory: category, context: context)
                if streak >= requiredStreak {
                    return true
                }
            }
            return false
        }
        else if condition.starts(with: "Complete") && condition.contains("quests across any categories") {
            let components = condition.components(separatedBy: CharacterSet.decimalDigits.inverted)
            guard let requiredCountString = components.first(where: { Int($0) != nil }), 
                  let requiredCount = Int(requiredCountString), 
                  requiredCount > 0 else { 
                return false 
            }
            
            // Count total completions across all categories
            let logFetchRequest: NSFetchRequest<HabitLog> = HabitLog.fetchRequest()
            do {
                let totalLogs = try context.count(for: logFetchRequest)
                return totalLogs >= requiredCount
            } catch {
                print("Error counting total completions: \(error)")
                return false
            }
        }
        else { 
            print("... unknown condition type, assuming false for now."); 
            return false 
        }
    }

    func clearGate(gate: GateStatus, profile: UserProfile) -> Bool {
        // (Code remains the same - Posts notification)
         guard gate.status == "Analyzed" else { print("Cannot clear gate: Not in 'Analyzed' state."); return false }
        print("Clearing Gate ID: \(gate.id?.uuidString ?? "N/A")")
        let viewContext = PersistenceController.shared.container.viewContext
        var grantedXP = 0; var grantedCrystals = 0; var profileDidChange = false
        // ... (reward parsing remains the same) ...
        if let rewardString = gate.rewardDescription { print("Parsing reward: '\(rewardString)'"); let components = rewardString.lowercased().components(separatedBy: CharacterSet.alphanumerics.inverted); let numbers = components.compactMap { Int($0) }; if rewardString.lowercased().contains("xp") { grantedXP = numbers.first ?? 0 }; if rewardString.lowercased().contains("mana crystal") { if let crystalIndex = components.firstIndex(where: { $0.contains("mana") }), crystalIndex > 0 { if let crystalVal = Int(components[crystalIndex-1]) { grantedCrystals = crystalVal } } else if numbers.count > 1 && grantedXP > 0 && numbers.indices.contains(1) { grantedCrystals = numbers[1] } else if numbers.count == 1 && grantedXP == 0 { grantedCrystals = numbers[0] } else { grantedCrystals = 0 } }; if rewardString.lowercased().contains("title:") { if let titlePart = rewardString.components(separatedBy: "Title:").last?.trimmingCharacters(in: .whitespaces), !titlePart.isEmpty { profile.title = titlePart; print("Granted Title: \(titlePart)") } } }
        if grantedXP > 0 { print("Granting \(grantedXP) XP."); _ = LevelingManager.shared.addXP(to: profile, amount: grantedXP, context: viewContext) } // Saves context if level up
        if grantedCrystals > 0 { profile.manaCrystals += Int64(grantedCrystals); print("Granted \(grantedCrystals) Mana Crystals. New total: \(profile.manaCrystals)"); profileDidChange = true }
        if profile.hasChanges { profileDidChange = true }
        gate.status = "Cleared"; gate.statusChangeDate = Date(); profileDidChange = true
        if profileDidChange && grantedXP == 0 { print("Saving context after clearing gate (no XP granted but other changes occurred)."); PersistenceController.shared.saveContext() // Save changes if needed
        } else if grantedXP > 0 { print("Context saving handled by LevelingManager.addXP or already saved.")
        } else { print("No changes detected that require saving after clearing gate.") }
        NotificationCenter.default.post(name: .didUpdateUserProfile, object: nil) // Post notification
        print("Gate Cleared: \(gate.id?.uuidString ?? "N/A")")
        self.spawnNewGate(clearedGate: gate, profile: profile, context: viewContext) // Spawns new gate (which also saves and posts notification)
        return true
    }

    func refreshGate(gate: GateStatus, profile: UserProfile, context: NSManagedObjectContext) -> (success: Bool, message: String?) {
        // (Code remains the same - Posts notification)
        print("Attempting to refresh Gate ID: \(gate.id?.uuidString ?? "N/A") (Status: \(gate.status ?? "Unknown"))")
        let cost: Int; if gate.status == "Locked" { cost = refreshLockedCost } else if gate.status == "Analyzed" { cost = refreshAnalyzedCost } else { let message = "Cannot refresh: Gate status is '\(gate.status ?? "Unknown")'."; print("    \(message)"); return (false, message) }
        print("    Refresh cost for status '\(gate.status!)': \(cost)")
        let currentCrystals = profile.manaCrystals; guard currentCrystals >= cost else { let message = "Cannot refresh: Insufficient Mana Crystals (\(currentCrystals)/\(cost))."; print("    \(message)"); return (false, message) }
        profile.manaCrystals -= Int64(cost); profile.totalManaSpent += Int64(cost)
        print("    Deducted \(cost) crystals. New total: \(profile.manaCrystals). New total spent: \(profile.totalManaSpent)")
        print("    Deleting old gate..."); context.delete(gate)
        print("    Saving context after deletion and cost deduction..."); PersistenceController.shared.saveContext()
        print("    Context saved.")
        NotificationCenter.default.post(name: .didUpdateUserProfile, object: nil) // Post notification
        spawnNewGate(clearedGate: gate, profile: profile, context: context) // Spawns new gate (which also saves and posts notification)
        return (true, nil)
    }


    // --- Helper Functions ---

    func createInitialGateIfNeeded(context: NSManagedObjectContext) {
        // (Code remains the same - Posts notification)
        let fetchRequest: NSFetchRequest<GateStatus> = GateStatus.fetchRequest(); fetchRequest.fetchLimit = 1
        do { let count = try context.count(for: fetchRequest); if count == 0 { print("No gates found, creating initial E-Rank Blue Gate."); let newGate = GateStatus(context: context); newGate.id = UUID(); newGate.gateRank = "E"; newGate.gateType = "Blue"; newGate.status = "Locked"; newGate.statusChangeDate = Date(); PersistenceController.shared.saveContext(); NotificationCenter.default.post(name: .didUpdateUserProfile, object: nil) }
        } catch { print("Error checking/creating initial gates: \(error)") }
    }

    // *** RESTORED Implementation ***
    private func generateClearCondition(rank: String) -> String {
        // Customize conditions based on rank later if needed
        let conditions = [
            "Achieve a 5-day Overall Streak.",
            "Reach Level 5.",
            "Reach Level \(Int.random(in: 6...15)).",
            "Complete 3 Quests in the 'Mind' category.",
            "Complete 2 Quests in the 'Body' category.",
            "Complete 2 Quests in the 'Skill' category.",
            "Complete 2 Quests in the 'Discipline' category.",
            "Complete 2 Quests in the 'Wellbeing' category.",
            "Spend 50 Mana Crystals.",
            "Spend \(Int.random(in: 2...8) * 10) Mana Crystals.",
            "Maintain a 3-day streak in any category.",
            "Complete 5 quests across any categories."
        ]
        // Ensure fallback is always valid
        return conditions.randomElement() ?? "Reach Level 3."
    }

    // *** RESTORED Implementation ***
    private func generateRewardDescription(rank: String) -> String {
         // Customize rewards based on rank later if needed
         let rewards = [
             "150 XP & 50 Mana Crystals",
             "Title: Gate Breaker",
             "100 Mana Crystals",
             "200 XP",
             "Title: E-Rank Slayer",
             "\(Int.random(in: 5...25) * 10) XP", // Example random XP
             "\(Int.random(in: 3...15) * 10) Mana Crystals" // Example random Crystals
         ]
         // Ensure fallback is always valid
         return rewards.randomElement() ?? "100 XP"
    }

    // *** RESTORED Implementation ***
    private func spawnNewGate(clearedGate: GateStatus, profile: UserProfile, context: NSManagedObjectContext) {
        print("Attempting to spawn new gate after clearing/refreshing Gate ID: \(clearedGate.id?.uuidString ?? "N/A") (Based on Rank: \(clearedGate.gateRank ?? "?"))")
        let fetchRequest: NSFetchRequest<GateStatus> = GateStatus.fetchRequest(); fetchRequest.predicate = NSPredicate(format: "status != %@", "Cleared")
        do { let activeCount = try context.count(for: fetchRequest); print("    Current active gates: \(activeCount)"); guard activeCount < maxActiveGates else { print("    Max active gates (\(maxActiveGates)) reached. Not spawning new gate."); return }
        } catch { print("    Error checking active gate count: \(error). Proceeding with spawn attempt.") }
        let userLevel = Int(profile.level); var possibleRanks = ["E"]
        if userLevel >= unlockLevelD { possibleRanks.append("D") }; if userLevel >= unlockLevelC { possibleRanks.append("C") }; if userLevel >= unlockLevelB { possibleRanks.append("B") }; if userLevel >= unlockLevelA { possibleRanks.append("A") }; if userLevel >= unlockLevelS { possibleRanks.append("S") }
        let newRank = possibleRanks.randomElement() ?? "E"
        let newGate = GateStatus(context: context); newGate.id = UUID(); newGate.gateRank = newRank; newGate.gateType = ["Blue", "Red"].randomElement() ?? "Blue"; newGate.status = "Locked"; newGate.statusChangeDate = Date()
        print("--> Spawning new \(newGate.gateRank ?? "?")-Rank \(newGate.gateType ?? "?") Gate (User Level: \(userLevel)).")
        PersistenceController.shared.saveContext()
        print("    New gate saved.")
        NotificationCenter.default.post(name: .didUpdateUserProfile, object: nil) // Post notification
    }

    // *** RESTORED Implementation ***
    private func countCompletionsAlternative(forCategory categoryName: String, context: NSManagedObjectContext) -> Int {
        print("--- Counting completions (Alternative) for category: \(categoryName) ---")
        var categoryCompletions = 0
        let habitFetchRequest: NSFetchRequest<Habit> = Habit.fetchRequest()
        habitFetchRequest.propertiesToFetch = ["id", "category"]
        var habitCategoryMap: [UUID: String] = [:]
        do {
            let allHabits = try context.fetch(habitFetchRequest)
            for habit in allHabits {
                if let id = habit.id, let category = habit.category {
                    habitCategoryMap[id] = category
                }
            }
             // print("    Fetched \(habitCategoryMap.count) habits into lookup map.")
        } catch {
            print("    Error fetching habits for category lookup: \(error)")
            return 0 // Return 0 on error
        }
        let logFetchRequest: NSFetchRequest<HabitLog> = HabitLog.fetchRequest()
        logFetchRequest.propertiesToFetch = ["habitID"]
        do {
            let allLogs = try context.fetch(logFetchRequest)
             // print("    Fetched \(allLogs.count) total habit logs.")
            for log in allLogs {
                if let habitID = log.habitID, let habitCategory = habitCategoryMap[habitID] {
                    if habitCategory == categoryName {
                        categoryCompletions += 1
                    }
                }
            }
        } catch {
            print("    Error fetching habit logs: \(error)")
            return 0 // Return 0 on error
        }
        print("    Found \(categoryCompletions) completions for category '\(categoryName)'.")
        // Ensure a value is always returned
        return categoryCompletions
    }
}
