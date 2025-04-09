import SwiftUI // Needed for withAnimation
import CoreData // Needed for FetchedResults
import Combine // Needed for ObservableObject

// Manages the data and logic for the list of all habits.
class HabitListViewModel: ObservableObject {
    // Get the main view context (can also be passed in via initializer if preferred)
    private let viewContext = PersistenceController.shared.container.viewContext

    // Function to delete habits using offsets from a ForEach loop
    func deleteHabits(offsets: IndexSet, habits: FetchedResults<Habit>) {
        // Use withAnimation for smooth UI updates if the list animates deletions
        withAnimation {
            // Map the offsets to the actual Habit objects in the fetched results
            offsets.map { habits[$0] }.forEach(viewContext.delete)
            // Save the context after deleting
            PersistenceController.shared.saveContext()
        }
    }
}
