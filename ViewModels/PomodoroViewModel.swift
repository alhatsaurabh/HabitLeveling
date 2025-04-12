// MARK: - File: PomodoroViewModel.swift
// Purpose: Manages the Pomodoro timer functionality including work/break intervals and session tracking
// Dependencies: SwiftUI, Notifications framework

import Foundation
import SwiftUI
import UserNotifications

#if os(iOS)
import UIKit
#endif

// Import PomodoroSession model

// Action: Define Notification Name
extension Notification.Name {
    static let pomodoroLogDeleted = Notification.Name("pomodoroLogDeleted")
}

// MARK: - Pomodoro Timer ViewModel
class PomodoroViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var timeRemaining: TimeInterval = 25 * 60
    @Published var timerIsActive = false
    @Published var currentMode: PomodoroMode = .work
    @Published var sessionNotes: String = ""
    @Published var taskCompleted: Bool = false
    @Published var totalSessionsToday: Int = 0
    @Published var totalSessionsWeek: Int = 0
    @Published var dailyCompletedFocusSessions: Int = 0 // RENAMED

    // MARK: - Settings
    @Published var workDuration: TimeInterval = UserDefaults.standard.double(forKey: "pomodoro.workDuration") != 0 ? UserDefaults.standard.double(forKey: "pomodoro.workDuration") : 25 * 60
    @Published var shortBreakDuration: TimeInterval = UserDefaults.standard.double(forKey: "pomodoro.shortBreakDuration") != 0 ? UserDefaults.standard.double(forKey: "pomodoro.shortBreakDuration") : 5 * 60
    @Published var longBreakDuration: TimeInterval = UserDefaults.standard.double(forKey: "pomodoro.longBreakDuration") != 0 ? UserDefaults.standard.double(forKey: "pomodoro.longBreakDuration") : 15 * 60
    @Published var autoStartBreaks: Bool = UserDefaults.standard.bool(forKey: "pomodoro.autoStartBreaks")
    @Published var autoStartWork: Bool = UserDefaults.standard.bool(forKey: "pomodoro.autoStartWork")
    @Published var longBreakAfterCount: Int = UserDefaults.standard.integer(forKey: "pomodoro.longBreakAfterCount") != 0 ? UserDefaults.standard.integer(forKey: "pomodoro.longBreakAfterCount") : 4
    
    // MARK: - Private Properties
    private var timer: Timer?
    private var sessionStartTime: Date?
    private var completedSessions = 0 // Internal counter for long breaks cycle
    private var backgroundTaskID: UIBackgroundTaskIdentifier = .invalid
    private var notificationID: String?
    
    // MARK: - Initialization
    init() {
        // Action: Load counts first
        loadSessionCounts()
        resetTimer() // Resets dailyCompletedFocusSessions to 0 for the new block

        // Action: Add Observer for log deletion
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleLogDeletion),
            name: .pomodoroLogDeleted,
            object: nil
        )
    }

    // Action: Add handler for notification
    @objc private func handleLogDeletion() {
        loadSessionCounts()
    }
    
    // MARK: - Public Methods
    func startTimer() {
        if !timerIsActive {
            timerIsActive = true
            if sessionStartTime == nil {
                sessionStartTime = Date()
            }
            
            // Request notification permissions if not already granted
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
            
            // Start background task
            startBackgroundTask()
            
            // Schedule periodic timer
            timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
                guard let self = self else { return }
                if self.timeRemaining > 0 {
                    self.timeRemaining -= 1
                } else {
                    self.timerFinished()
                }
            }
            
            // Cancel any existing notifications first
            if let notificationID = notificationID {
                UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [notificationID])
            }
            
            // Create notification for when timer should end
            scheduleTimerEndNotification()
        }
    }
    
    func pauseTimer() {
        timerIsActive = false
        timer?.invalidate()
        timer = nil
        
        // Cancel any pending notifications
        if let notificationID = notificationID {
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [notificationID])
            self.notificationID = nil
        }
        
        // End background task
        endBackgroundTask()
    }
    
    func resetTimer() {
        pauseTimer()
        timeRemaining = currentMode == .work ? workDuration : (currentMode == .shortBreak ? shortBreakDuration : longBreakDuration)
        sessionStartTime = nil
        dailyCompletedFocusSessions = 0 // Action: Keep reset for current block
    }
    
    func skipToNext() {
        // Determine next mode based on internal completedSessions counter
        let nextMode: PomodoroMode = currentMode == .work ? (completedSessions % longBreakAfterCount == longBreakAfterCount - 1 ? .longBreak : .shortBreak) : .work
        
        // If skipping a work session, update internal counter and save to log (totals counted elsewhere)
        if currentMode == .work {
             completedSessions += 1 // Cycle counter
             self.taskCompleted = false // Ensure skipped work session isn't marked complete
             
             // Action: Save skipped work session to log
             let skippedSessionData: [String: Any] = [
                 "id": UUID().uuidString,
                 "date": Date(), // Use current time for skipped session
                 "duration": Int(workDuration - timeRemaining), // Log elapsed time before skip
                 "notes": sessionNotes, // Save notes entered before skipping
                 "taskCompleted": false // Mark as not completed
             ]
             let defaults = UserDefaults.standard
             let sessionKey = "pomodoro.sessions"
             var savedSessions = defaults.array(forKey: sessionKey) as? [[String: Any]] ?? []
             savedSessions.append(skippedSessionData)
             // Sort/limit logic (optional, but good practice)
             savedSessions.sort { 
                 guard let date1 = $0["date"] as? Date, 
                       let date2 = $1["date"] as? Date else { return false }
                 return date1 > date2
             }
             if savedSessions.count > 50 { savedSessions = Array(savedSessions.prefix(50)) }
             defaults.set(savedSessions, forKey: sessionKey)
             
             // Clear notes after saving skipped session
             self.sessionNotes = ""
        }
        
        switchMode(nextMode)
    }
    
    func saveSettings() {
        UserDefaults.standard.set(workDuration, forKey: "pomodoro.workDuration")
        UserDefaults.standard.set(shortBreakDuration, forKey: "pomodoro.shortBreakDuration")
        UserDefaults.standard.set(longBreakDuration, forKey: "pomodoro.longBreakDuration")
        UserDefaults.standard.set(autoStartBreaks, forKey: "pomodoro.autoStartBreaks")
        UserDefaults.standard.set(autoStartWork, forKey: "pomodoro.autoStartWork")
        UserDefaults.standard.set(longBreakAfterCount, forKey: "pomodoro.longBreakAfterCount")
        
        // Reset timer with new duration if not active
        if !timerIsActive {
            resetTimer()
        }
    }
    
    func toggleTimer() {
        if timerIsActive {
            pauseTimer()
        } else {
            startTimer()
        }
    }
    
    func skipSession() {
        // This might be called by UI, ensure it calls the correct skip logic
        skipToNext()
    }
    
    // Action: Modify saveCompletedSession - Only save work sessions
    func saveCompletedSession() {
        // Only save if it was a work session
        guard currentMode == .work else { return }
        
        let sessionCompleted = self.taskCompleted // Capture state at time of saving

        if let startTime = sessionStartTime {
            let duration = Int(Date().timeIntervalSince(startTime))
            let sessionData: [String: Any] = [
                "id": UUID().uuidString,
                "date": Date(),
                "duration": duration,
                "notes": sessionNotes,
                "taskCompleted": sessionCompleted // Save actual completion state
            ]
            
            let defaults = UserDefaults.standard
            let sessionKey = "pomodoro.sessions"
            var savedSessions = defaults.array(forKey: sessionKey) as? [[String: Any]] ?? []
            savedSessions.append(sessionData)
            
            // Sort and limit logic... (keep as is)
             savedSessions.sort {
                 guard let date1 = $0["date"] as? Date,
                       let date2 = $1["date"] as? Date else {
                     return false
                 }
                 return date1 > date2
             }
             if savedSessions.count > 50 {
                 savedSessions = Array(savedSessions.prefix(50))
             }
            
            defaults.set(savedSessions, forKey: sessionKey)
            
            // Update total counts
            totalSessionsToday += 1
            totalSessionsWeek += 1

            // Action: Increment daily count only if completed focus session
            if sessionCompleted && currentMode == .work {
                dailyCompletedFocusSessions += 1
            }
            
            self.sessionNotes = ""
            // Let caller reset taskCompleted state if needed (e.g., timerFinished or button action)
        } else {
            // Handle saving when no timer was active (e.g., quick manual log)
            // Also only save if current mode implies it was intended as a work session log
            guard currentMode == .work else { return } // Double check for manual log case

            let sessionData: [String: Any] = [
                "id": UUID().uuidString,
                "date": Date(),
                "duration": 60, // Default duration
                "notes": sessionNotes,
                "taskCompleted": sessionCompleted
            ]
            
            let defaults = UserDefaults.standard
            let sessionKey = "pomodoro.sessions"
            var savedSessions = defaults.array(forKey: sessionKey) as? [[String: Any]] ?? []
            savedSessions.append(sessionData)
            defaults.set(savedSessions, forKey: sessionKey)
            
            // Update total counts
            totalSessionsToday += 1
            totalSessionsWeek += 1

            // Action: Increment daily count only if completed focus session
            if sessionCompleted && currentMode == .work {
                dailyCompletedFocusSessions += 1
            }
            self.sessionNotes = ""
        }
    }
    
    // MARK: - Helper Methods
    private func timerFinished() {
        pauseTimer() // Pause first

        if currentMode == .work {
            // Action: Assume timer finishing means task is completed
            self.taskCompleted = true
            saveCompletedSession() // Saves work session, increments daily count & totals
            self.taskCompleted = false // Reset state AFTER saving for next session

            // Update internal counter for long breaks AFTER saving
            completedSessions += 1

            // Switch to break mode AFTER saving
            let nextMode: PomodoroMode = completedSessions % longBreakAfterCount == 0 ? .longBreak : .shortBreak
            switchMode(nextMode)

            if autoStartBreaks {
                startTimer()
            }
        } else {
            // Completed break session - DO NOT SAVE
            self.taskCompleted = false // Ensure breaks don't affect completed state
            switchMode(.work) // Switch back to work
            if autoStartWork {
                startTimer()
            }
        }
    }
    
    private func switchMode(_ mode: PomodoroMode) {
        // Only reset timer if mode actually changes
        if currentMode != mode {
            currentMode = mode
            timeRemaining = mode == .work ? workDuration : (mode == .shortBreak ? shortBreakDuration : longBreakDuration)
            sessionStartTime = nil
        } else {
             // If mode is the same, just reset time
             timeRemaining = mode == .work ? workDuration : (mode == .shortBreak ? shortBreakDuration : longBreakDuration)
             sessionStartTime = nil
        }
        self.taskCompleted = false
        pauseTimer() // Action: Explicitly pause timer after any mode switch
    }
    
    private func startBackgroundTask() {
        #if os(iOS) // Ensure background task logic is iOS-only
        if backgroundTaskID == .invalid {
            backgroundTaskID = UIApplication.shared.beginBackgroundTask { [weak self] in
                self?.endBackgroundTask()
            }
        }
        #endif
    }
    
    private func endBackgroundTask() {
         #if os(iOS)
        if backgroundTaskID != .invalid {
            UIApplication.shared.endBackgroundTask(backgroundTaskID)
            backgroundTaskID = .invalid
        }
        #endif
    }
    
    private func scheduleTimerEndNotification() {
        // Cancel existing...
        if let notificationID = notificationID {
             UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [notificationID])
         }

        // Create content...
        let content = UNMutableNotificationContent()
        content.title = "Pomodoro Timer"
         let body: String
         switch currentMode {
         case .work: body = "Focus session complete! Time for a break."
         case .shortBreak: body = "Short break finished. Back to focus!"
         case .longBreak: body = "Long break finished. Ready for the next focus session?"
         }
         content.body = body
        content.sound = .default

        // Schedule...
         // Ensure timeInterval is positive
         guard timeRemaining > 0 else { return }
         let trigger = UNTimeIntervalNotificationTrigger(timeInterval: timeRemaining, repeats: false)
         let identifier = UUID().uuidString
         let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error)")
            }
        }
        notificationID = identifier
    }

    // These seem redundant now as timerFinished handles the logic and scheduleTimerEndNotification handles the alert
    private func scheduleCompletionNotification() { }
    private func scheduleBreakEndNotification() { }

    // Action: Modify loadSessionCounts
    private func loadSessionCounts() {
        let defaults = UserDefaults.standard
        let sessionKey = "pomodoro.sessions"
        guard let savedSessions = defaults.array(forKey: sessionKey) as? [[String: Any]] else {
            totalSessionsToday = 0
            totalSessionsWeek = 0
            dailyCompletedFocusSessions = 0 // Reset if no saved data
            return
        }

        let calendar = Calendar.current
        let todayStart = calendar.startOfDay(for: Date())
        let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date())) ?? Date()

        // Calculate total counts
        totalSessionsToday = savedSessions.filter { sessionDict in
            guard let date = sessionDict["date"] as? Date else { return false }
            return calendar.isDate(date, inSameDayAs: todayStart) // Use isDate(_, inSameDayAs:)
        }.count

        totalSessionsWeek = savedSessions.filter { sessionDict in
            guard let date = sessionDict["date"] as? Date else { return false }
            return date >= weekStart
        }.count

        // Action: Calculate daily completed focus sessions
        dailyCompletedFocusSessions = savedSessions.filter { sessionDict in
            guard let date = sessionDict["date"] as? Date,
                  let completed = sessionDict["taskCompleted"] as? Bool else { return false }
            // Assumption: completed task implies focus session (mode not saved)
            // TODO: Consider saving mode with session for more accuracy
            return calendar.isDate(date, inSameDayAs: todayStart) && completed
        }.count
    }
    
    // MARK: - Computed Properties
    var isRunning: Bool {
        return timerIsActive
    }
    
    var currentSession: PomodoroSessionType {
        switch currentMode {
        case .work:
            return .focus
        case .shortBreak:
            return .shortBreak
        case .longBreak:
            return .longBreak
        }
    }
    
    var sessionsUntilLongBreak: Int {
        get { return longBreakAfterCount }
        set { longBreakAfterCount = newValue }
    }
    
    var autoStartFocus: Bool {
        get { return autoStartWork }
        set { autoStartWork = newValue }
    }
    
    var progress: CGFloat {
        let totalDuration: TimeInterval
        switch currentMode {
        case .work: totalDuration = workDuration
        case .shortBreak: totalDuration = shortBreakDuration
        case .longBreak: totalDuration = longBreakDuration
        }
        // Prevent division by zero or negative progress
        guard totalDuration > 0 else { return 0 }
        let currentProgress = (totalDuration - timeRemaining) / totalDuration
        return max(0, min(1, CGFloat(currentProgress))) // Clamp between 0 and 1
    }
    
    var timeRemainingFormatted: String {
        let minutes = Int(timeRemaining) / 60
        let seconds = Int(timeRemaining) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    var statusMessage: String { // Renamed from currentSession rawValue for clarity
        switch currentMode {
        case .work:
            return "Focus Session"
        case .shortBreak:
            return "Short Break"
        case .longBreak:
            return "Long Break"
        }
    }
    
    func checkTimerStatus() {
        #if os(iOS)
        if timerIsActive, let startTime = sessionStartTime {
            let elapsedTime = Date().timeIntervalSince(startTime)
            let totalDuration: TimeInterval
            switch currentMode {
             case .work: totalDuration = workDuration
             case .shortBreak: totalDuration = shortBreakDuration
             case .longBreak: totalDuration = longBreakDuration
             }
            
            let newTimeRemaining = max(0, totalDuration - elapsedTime)
            
            if abs(timeRemaining - newTimeRemaining) > 1.0 {
                 // Significant difference, update UI
                 timeRemaining = newTimeRemaining
                 
                 if timeRemaining <= 0 {
                     // Timer should have ended while app was in background
                     if let notificationID = notificationID {
                         UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [notificationID])
                         self.notificationID = nil
                     }
                     // Manually trigger timerFinished to handle state transition
                     timerFinished()
                 } else {
                     // Timer still running, reschedule notification for accurate remaining time
                     scheduleTimerEndNotification()
                 }
            }
        }
        #endif
    }
}

// MARK: - PomodoroMode Enum
enum PomodoroMode {
    case work
    case shortBreak
    case longBreak
}

// MARK: - PomodoroSessionType Enum (for UI display)
enum PomodoroSessionType: String {
    case focus = "Focus Session"
    case shortBreak = "Short Break"
    case longBreak = "Long Break"
} 