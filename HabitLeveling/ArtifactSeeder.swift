import Foundation
import CoreData

// The StatCategory enum is defined in Models/StatTypes.swift
// Add a simple import since we're in the same module
// Uncomment this local definition if import fails
struct ArtifactSeeder {
    // Local enum for use in seeding
    enum StatCategory: String {
        case mind = "Mind"
        case body = "Body"
        case skill = "Skill"
        case discipline = "Discipline"
        case wellbeing = "Wellbeing"
        case other = "Other"
    }

    static func seedInitialArtifacts(context: NSManagedObjectContext) {
        let fetchRequest: NSFetchRequest<Artifact> = Artifact.fetchRequest()
        fetchRequest.fetchLimit = 1
        do {
            let count = try context.count(for: fetchRequest)
            guard count == 0 else {
                print("INFO: Artifacts already seeded.")
                return
            }
        } catch {
            print("ERROR: Could not check for existing artifacts: \(error.localizedDescription)")
            return
        }

        print("INFO: Seeding initial artifacts...")

        // Artifact 1: Common Body Boost
        let artifact1 = Artifact(context: context)
        artifact1.id = UUID()
        artifact1.name = "Stone of Minor Vigor"
        artifact1.desc = "A rough, heavy stone that slightly enhances physical resilience."
        artifact1.imageName = "stone_body_common"
        artifact1.rarity = "Common"
        artifact1.statBoostType = StatCategory.body.rawValue
        artifact1.statBoostValue = 1.0
        artifact1.acquisitionCondition = "Complete 5 Body-based habits."

        // Artifact 2: Uncommon Skill Boost
        let artifact2 = Artifact(context: context)
        artifact2.id = UUID()
        artifact2.name = "Adept's Training Band"
        artifact2.desc = "A worn leather band that seems to improve technique."
        artifact2.imageName = "band_skill_uncommon"
        artifact2.rarity = "Uncommon"
        artifact2.statBoostType = StatCategory.skill.rawValue
        artifact2.statBoostValue = 2.0
        artifact2.acquisitionCondition = "Log 10 Skill-based habit completions."

        // Artifact 3: Rare Mind Boost
        let artifact3 = Artifact(context: context)
        artifact3.id = UUID()
        artifact3.name = "Circlet of Clarity"
        artifact3.desc = "A simple circlet that helps focus the mind."
        artifact3.imageName = "circlet_mind_rare"
        artifact3.rarity = "Rare"
        artifact3.statBoostType = StatCategory.mind.rawValue
        artifact3.statBoostValue = 5.0
        artifact3.acquisitionCondition = "Reach Level 10."

        // Artifact 4: No Stat Boost (Badge)
        let artifact4 = Artifact(context: context)
        artifact4.id = UUID()
        artifact4.name = "Badge of the Initiate"
        artifact4.desc = "Proof of taking the first steps on the path."
        artifact4.imageName = "badge_initiate_common"
        artifact4.rarity = "Common"
        artifact4.statBoostType = nil
        artifact4.statBoostValue = 0.0
        artifact4.acquisitionCondition = "Complete your first habit."

        // Save the Context
        do {
            try context.save()
            print("SUCCESS: Successfully seeded \(4) artifacts.")
        } catch {
            let nsError = error as NSError
            print("FATAL ERROR: Unresolved error during artifact seeding \(nsError), \(nsError.userInfo)")
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
    }
}
