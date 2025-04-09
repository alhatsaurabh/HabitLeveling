// MARK: - File: EssenceCoreManager.swift (Updated April 3, 2025)
// Fixed saveContext call to pass no arguments

import Foundation
import CoreData // Needed for UserProfile

// Determines the state of the Essence Core.
class EssenceCoreManager {
    // Singleton pattern
    static let shared = EssenceCoreManager()
    private init() {}

    // --- UPDATED Function: updateCoreState ---
    // Uses getProgressTowardsNextLevel for more accurate progress check
    // Fixed saveContext call
    func updateCoreState(for profile: UserProfile) {
        let previousState = profile.essenceCoreState ?? "Dim" // Get current state before changing

        // Get progress within the current level
        let progressData = LevelingManager.shared.getProgressTowardsNextLevel(profile: profile)
        let progressPercent = progressData.progress // This is a Float between 0.0 and 1.0

        var newState = "Dim" // Default to Dim

        // Simple logic: Bright if progress > 50%, otherwise Dim
        if progressPercent > 0.5 { // Check if more than halfway through the current level's XP bar
            newState = "Bright"
        } else if progressPercent > 0.1 { // Example: Dim if > 10% but <= 50%
             newState = "Dim" // Keep it Dim but could add 'Flickering' later
        } else {
             newState = "Off" // Example: Maybe an 'Off' state if very little progress?
        }

        // Add conditions for "Flickering" later if needed (e.g., if streak was lost, or progress is low)

        // --- End Placeholder ---

        // Only save if the state actually changed
        if newState != previousState {
             profile.essenceCoreState = newState
             print("Updating Core State to: \(newState)")
             // *** CORRECTED: Call saveContext() without arguments ***
             PersistenceController.shared.saveContext()
        } else {
             // print("Core State remains: \(previousState)") // Optional: Log if no change
        }
    }
}
