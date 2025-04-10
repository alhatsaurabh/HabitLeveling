import SwiftUI

@main
struct HabitLevelingApp: App {
    // Get the shared persistence controller
    let persistenceController = PersistenceController.shared

    // Initialize the app
    init() {
        // Request notification permission when the app initializes
        NotificationManager.shared.requestAuthorization { granted in
            if granted {
                print("Notification permission granted, scheduling habit reminders")
                // If permission granted, schedule notifications for all habits with reminders
                NotificationManager.shared.scheduleNotificationsForAllHabits()
            } else {
                print("Notification permission not granted")
            }
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                // Inject the managed object context into the SwiftUI environment
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .onAppear {
                    // Ensure notifications are scheduled when app appears
                    NotificationManager.shared.notificationCenter.getNotificationSettings { settings in
                        if settings.authorizationStatus == .authorized {
                            DispatchQueue.main.async {
                                NotificationManager.shared.scheduleNotificationsForAllHabits()
                            }
                        }
                    }
                }
        }
    }
}
