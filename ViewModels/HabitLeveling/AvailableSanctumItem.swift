import Foundation

// Represents an item that *can* be built in the Sanctum.
// Using a simple struct for now, not Core Data.
struct AvailableGateStatus: Identifiable, Hashable {
    let id = UUID() // Make it identifiable for lists
    let name: String
    let description: String
    let fragmentCost: Int
    let iconName: String // SF Symbol name for display
    let elementType: String // Matches the string saved in GateStatus.elementType

    // Static list of items available to build
    // Add more items here later!
    static let buildableItems: [AvailableGateStatus] = [
        AvailableGateStatus(name: "Training Post",
                             description: "A sturdy post for honing combat skills.",
                             fragmentCost: 25, // Example cost
                             iconName: "figure.martial.arts",
                             elementType: "Training Post"), // Must match SanctumManager unlock string if applicable
        AvailableGateStatus(name: "Meditation Rock",
                             description: "A smooth, flat rock ideal for focus.",
                             fragmentCost: 20,
                             iconName: "leaf.fill",
                             elementType: "Meditation Rock"),
        AvailableGateStatus(name: "Small Library",
                             description: "A shelf holding essential knowledge.",
                             fragmentCost: 50,
                             iconName: "books.vertical.fill",
                             elementType: "Small Library"),
        AvailableGateStatus(name: "Glowing Crystal",
                              description: "Emanates a faint, calming energy.",
                              fragmentCost: 75,
                              iconName: "sparkle",
                              elementType: "Glowing Crystal")
        // Note: "Foundation Stone" is unlocked automatically by level, so not listed here.
    ]
}
