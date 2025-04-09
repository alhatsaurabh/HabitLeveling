
import SwiftUI

@main
struct HabitLevelingApp: App {
    // Get the shared persistence controller
    let persistenceController = PersistenceController.shared

    // Initialize the app
    init() {
        // Request notification permission when the app initializes
        NotificationManager.shared.requestAuthorization()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                // Inject the managed object context into the SwiftUI environment
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
