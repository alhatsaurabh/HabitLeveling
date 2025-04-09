// MARK: - File: NotificationManager.swift
// Purpose: Manages scheduling and handling of local notifications for habit reminders and in-app notifications.
// Update: Added in-app notification system with modern design.

import UserNotifications
import CoreData // Needed to fetch Habits
import UIKit // Needed for UIApplication delegate example
import SwiftUI
import Combine

class NotificationManager: NSObject, ObservableObject { // Inherit from NSObject for UNUserNotificationCenterDelegate
    // Singleton pattern
    static let shared = NotificationManager()
    private override init() {
        super.init()
        // Set the delegate for the notification center
        notificationCenter.delegate = self
    }

    let notificationCenter = UNUserNotificationCenter.current() // Store reference
    
    // MARK: - In-App Notification System
    @Published var currentNotification: InAppNotification?
    private var notificationTimer: Timer?
    
    struct InAppNotification: Identifiable {
        let id = UUID()
        let title: String
        let message: String
        let type: NotificationType
        let duration: TimeInterval
        
        enum NotificationType {
            case success
            case warning
            case error
            case info
        }
    }
    
    func showInAppNotification(title: String, message: String, type: InAppNotification.NotificationType = .info, duration: TimeInterval = 3.0) {
        DispatchQueue.main.async {
            self.currentNotification = InAppNotification(title: title, message: message, type: type, duration: duration)
            
            // Cancel any existing timer
            self.notificationTimer?.invalidate()
            
            // Set up new timer
            self.notificationTimer = Timer.scheduledTimer(withTimeInterval: duration, repeats: false) { _ in
                withAnimation(.easeOut(duration: 0.3)) {
                    self.currentNotification = nil
                }
            }
        }
    }

    // MARK: - Authorization

    // Requests permission to send notifications
    func requestAuthorization(completion: @escaping (Bool) -> Void = {_ in }) {
        notificationCenter.requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            DispatchQueue.main.async { // Ensure completion handler runs on main thread
                if let error = error {
                    print("❌ Error requesting notification authorization: \(error.localizedDescription)")
                    completion(false)
                    return
                }

                if granted {
                    print("✅ Notification permission granted.")
                    // Optional: Schedule immediately after permission granted,
                    // or rely on calls from save/delete/app launch.
                    // self.scheduleNotificationsForAllHabits() // Consider if needed here
                    completion(true)
                } else {
                    print("⚠️ Notification permission denied.")
                    // Handle denial if needed (e.g., show alert explaining benefits)
                    completion(false)
                }
            }
        }
    }

    // MARK: - Scheduling

    // Schedules notifications for all habits that have a reminder time set.
    // NOTE: This currently schedules DAILY repeating notifications at the set time.
    // Proper weekly/monthly scheduling requires data model changes (e.g., storing weekdays).
    func scheduleNotificationsForAllHabits() {
        // Use the main view context from PersistenceController
        let viewContext = PersistenceController.shared.container.viewContext
        let fetchRequest: NSFetchRequest<Habit> = Habit.fetchRequest()
        // Only fetch habits that have a notification time set
        fetchRequest.predicate = NSPredicate(format: "notificationTime != nil")

        print("🔄 Scheduling notifications for all habits...")

        // Ensure we have permission before proceeding
        notificationCenter.getNotificationSettings { [weak self] settings in
            guard let self = self else { return }
            guard settings.authorizationStatus == .authorized else {
                print("⚠️ Cannot schedule notifications: Authorization not granted.")
                return
            }

            // Perform Core Data fetch and notification scheduling on a background thread
            // to avoid blocking the main thread, but ensure notificationCenter calls are safe.
            // UNUserNotificationCenter is thread-safe, CoreData fetch should be background.
             viewContext.perform { // Perform fetch on context's queue
                do {
                    let habitsToSchedule = try viewContext.fetch(fetchRequest)
                    print("  Found \(habitsToSchedule.count) habits with reminder times.")

                    // First, remove all previously scheduled notifications managed by this app
                    self.notificationCenter.removeAllPendingNotificationRequests()
                    print("  Removed all pending notifications.")

                    var scheduledCount = 0

                    // Iterate through habits and schedule notification if time is set
                    for habit in habitsToSchedule {
                        guard let notificationTime = habit.notificationTime,
                              let habitID = habit.id, // Ensure habit has an ID
                              let habitName = habit.name, !habitName.isEmpty // Ensure habit has a name
                        else {
                            continue // Skip if essential data is missing
                        }

                        // --- Create Notification Content ---
                        let content = UNMutableNotificationContent()
                        content.title = "Quest Reminder: \(habitName)"
                        content.body = habit.habitDescription?.isEmpty == false ? habit.habitDescription! : "Time for your quest: \(habitName)!"
                        content.sound = UNNotificationSound.default
                        content.userInfo = ["habitID": habitID.uuidString]

                        // --- Create Trigger ---
                        let components = Calendar.current.dateComponents([.hour, .minute], from: notificationTime)

                        // TODO: Enhance trigger logic for Frequency
                        // Currently, this schedules a DAILY repeating notification at the specified time.
                        // To handle "Weekly", we need to know WHICH day(s) of the week.
                        // This likely requires changes to the Habit data model (e.g., add a 'reminderWeekdays' attribute).
                        // For now, we schedule daily.
                        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
                        print("    Scheduling trigger for \(habitName) at \(components.hour ?? -1):\(components.minute ?? -1) (Daily Repeat)")


                        // --- Create Request with Unique ID ---
                        let requestIdentifier = "habit-\(habitID.uuidString)"
                        let request = UNNotificationRequest(identifier: requestIdentifier, content: content, trigger: trigger)

                        // --- Add Request to Notification Center ---
                        self.notificationCenter.add(request) { error in
                            // This completion handler executes on a background thread
                            if let error = error {
                                print("❌ Error scheduling notification for habit \(habitName): \(error.localizedDescription)")
                            }
                            // Note: Can't reliably track count here due to async nature for each add.
                        }
                        scheduledCount += 1
                    } // End loop

                    // This count reflects requests added, confirmation is async.
                    print("✅ Attempted to schedule \(scheduledCount) notifications.")
                    // Optional: Verify pending requests after a short delay for debugging
                     DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                         self.notificationCenter.getPendingNotificationRequests { requests in print("  Pending requests count: \(requests.count)") }
                     }

                } catch {
                    print("❌ Error fetching habits for notification scheduling: \(error)")
                }
            } // End viewContext.perform
        } // End getNotificationSettings
    }

    // MARK: - Cancellation

    // Cancels all scheduled notifications for this app
    func cancelAllNotifications() {
         notificationCenter.removeAllPendingNotificationRequests()
         print("🗑️ All pending notifications cancelled.")
    }

    // Cancels notification for a specific habit
    func cancelNotification(for habit: Habit) {
        guard let habitID = habit.id else {
            print("⚠️ Cannot cancel notification for habit without ID.")
            return
        }
        let requestIdentifier = "habit-\(habitID.uuidString)"
        notificationCenter.removePendingNotificationRequests(withIdentifiers: [requestIdentifier])
        print("🗑️ Removed pending notification request with ID: \(requestIdentifier)")
    }
}

// MARK: - UNUserNotificationCenterDelegate
// Implement delegate methods to handle notifications when the app is in the foreground

extension NotificationManager: UNUserNotificationCenterDelegate {

    // Handle notification presentation when app is in the foreground
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        print("🔔 Notification received while app in foreground: \(notification.request.identifier)")
        // Show notification as banner and play sound while app is active
        completionHandler([.banner, .sound, .list]) // Use .list on iOS 14+
    }

    // Handle user tapping on the notification
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        let identifier = response.notification.request.identifier
        print("🔔 User tapped notification with ID: \(identifier)")

        if let habitIDString = response.notification.request.content.userInfo["habitID"] as? String {
            print("  Related Habit ID: \(habitIDString)")
            // Post notification to handle navigation
            NotificationCenter.default.post(name: .didTapHabitNotification, object: nil, userInfo: ["habitID": habitIDString])
        }

        completionHandler()
    }
}

// MARK: - Notification Names
extension Notification.Name {
    static let didTapHabitNotification = Notification.Name("didTapHabitNotification")
}
