// MARK: - File: LevelingManager.swift
// Update: Modified addXP to return the new level achieved (Int?) instead of Bool.
// Update 2: Removed unused 'originalLevel' variable.

import Foundation
import CoreData

class LevelingManager {
    static let shared = LevelingManager()
    private init() {}

    /**
     Adds XP to the profile, handles level ups, assigns titles/jobs, saves context,
     and returns the new level if a level up occurred, otherwise nil.

     - Parameters:
        - profile: The UserProfile to modify.
        - amount: The amount of XP to add.
        - context: The managed object context.
     - Returns: The new level (Int) if a level up occurred, otherwise nil.
     */
    func addXP(to profile: UserProfile, amount: Int, context: NSManagedObjectContext) -> Int? { // Changed return type
        guard amount > 0 else { return nil } // No XP added, no level up possible

        // let originalLevel = Int(profile.level) // REMOVED: Was never used
        profile.xp += Int64(amount)
        print("Added \(amount) XP. New total: \(profile.xp)")

        var xpForNextLevel = calculateXPForNextLevel(level: Int(profile.level))
        var leveledUp = false

        print("--> Checking level up loop (Current XP: \(profile.xp), Needed: \(xpForNextLevel))")
        while profile.xp >= xpForNextLevel && xpForNextLevel > 0 { // Add check for xpForNextLevel > 0 to prevent infinite loop if formula returns 0/negative
            profile.level += 1
            profile.xp -= xpForNextLevel
            print("    Leveled Up! New Level: \(profile.level)")
            leveledUp = true
            xpForNextLevel = calculateXPForNextLevel(level: Int(profile.level))
            print("    Recalculated xpForNextLevel: \(xpForNextLevel)")

            // --- Assign Titles based on Level ---
            var levelBasedTitle: String? = nil
            switch profile.level {
                case 5: levelBasedTitle = "E-Rank Hunter"
                case 10: levelBasedTitle = "Wolf Slayer"
                case 20: levelBasedTitle = "D-Rank Hunter"
                case 30: levelBasedTitle = "Naga Hunter"
                case 50: levelBasedTitle = "C-Rank Hunter"
                // Add more ranks...
                default: break
            }
            if let titleToAssign = levelBasedTitle {
                profile.title = titleToAssign
                print("    Title Granted (Level Up): \(titleToAssign)")
            }

            // --- Assign Job based on Level ---
            if profile.level == 20 && profile.job == "Unspecialized" {
                profile.job = "Hunter - Awakened"
                print("    Job Assigned: \(profile.job ?? "Error")")
            }
            print("    End of level up loop iteration. Current XP: \(profile.xp)")
        } // End while loop
        print("<-- Finished level up loop check.")

        let finalLevel = Int(profile.level) // Get final level after loop

        // --- Save Context ---
        // Save only if XP was added or level changed
        if leveledUp || amount > 0 {
            print("--> Attempting save (leveledUp: \(leveledUp), xpAdded: \(amount > 0))...")
            PersistenceController.shared.saveContext() // Use shared save helper
            print("<-- Save finished.")
            if leveledUp { print("UserProfile saved after level up.") }
        }

        print("--> Returning from addXP (leveledUp: \(leveledUp))")
        // --- UPDATED: Return new level if leveledUp, else nil ---
        return leveledUp ? finalLevel : nil
    }

    // --- calculateXPForNextLevel remains the same ---
    func calculateXPForNextLevel(level: Int) -> Int64 {
        guard level >= 1 else { return 100 }
        let baseXP: Double = 100; let multiplier: Double = 1.5
        let exponent = Double(max(0, level - 1)); let xpNeeded = baseXP * pow(multiplier, exponent)
        if xpNeeded.isInfinite || xpNeeded.isNaN || xpNeeded > Double(Int64.max) { print("Warning: Calculated XP requirement is excessively large or invalid for level \(level). Returning max value."); return Int64.max }
        // Ensure minimum XP needed is at least 1 to prevent issues if baseXP or multiplier are <= 0
        return max(1, Int64(round(xpNeeded)))
    }

    // --- getProgressTowardsNextLevel remains the same ---
    func getProgressTowardsNextLevel(profile: UserProfile) -> (currentXP: Int64, neededXP: Int64, progress: Float) {
        let currentLevel = Int(profile.level); let needed = calculateXPForNextLevel(level: currentLevel); var xpAtLevelStart: Int64 = 0
        // This calculation might be inaccurate if xpForNextLevel was capped at Int64.max previously
        // Consider simplifying or storing total XP needed per level if precision is critical
        if currentLevel > 1 { for i in 1..<currentLevel { xpAtLevelStart += calculateXPForNextLevel(level: i); if xpAtLevelStart < 0 { xpAtLevelStart = Int64.max / 2; break } } }
        let currentLevelXP = max(0, profile.xp); // Simplified: just use current XP for progress bar display relative to next level need
        let progress: Float
        if needed <= 0 { progress = (currentLevelXP > 0) ? 1.0 : 0.0 } else { progress = Float(currentLevelXP) / Float(needed) }
        return (currentXP: currentLevelXP, neededXP: needed, progress: min(max(progress, 0.0), 1.0))
    }
}
