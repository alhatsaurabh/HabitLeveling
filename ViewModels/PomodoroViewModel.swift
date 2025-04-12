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
    private var completedSessions = 0
    private var backgroundTaskID: UIBackgroundTaskIdentifier = .invalid
    private var notificationID: String?
    
    // MARK: - Initialization
    init() {
        resetTimer()
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
    }
    
    func skipToNext() {
        switchMode(currentMode == .work ? (completedSessions % longBreakAfterCount == longBreakAfterCount - 1 ? .longBreak : .shortBreak) : .work)
    }
    
    func saveSettings() {
        UserDefaults.standard.set(workDuration, forKey: "pomodoro.workDuration")
        UserDefaults.standard.set(shortBreakDuration, forKey: "pomodoro.shortBreakDuration")
        UserDefaults.standard.set(longBreakDuration, forKey: "pomodoro.longBreakDuration")
        UserDefaults.standard.set(autoStartBreaks, forKey: "pomodoro.autoStartBreaks")
        UserDefaults.standard.set(autoStartWork, forKey: "pomodoro.autoStartWork")
        UserDefaults.standard.set(longBreakAfterCount, forKey: "pomodoro.longBreakAfterCount")
        
        // Reset timer with new duration
        if !timerIsActive {
            resetTimer()
        }
    }
    
    // Add toggleTimer method
    func toggleTimer() {
        if timerIsActive {
            pauseTimer()
        } else {
            startTimer()
        }
    }
    
    // Add skipSession method (equivalent to skipToNext)
    func skipSession() {
        skipToNext()
    }
    
    // Add method to save completed session with a taskCompleted parameter
    func saveCompletedSession(taskCompleted: Bool) {
        self.taskCompleted = taskCompleted
        
        if let startTime = sessionStartTime {
            let duration = Int(Date().timeIntervalSince(startTime))
            // Create session data
            let sessionData: [String: Any] = [
                "id": UUID().uuidString,
                "date": Date(),
                "duration": duration,
                "notes": sessionNotes,
                "taskCompleted": self.taskCompleted
            ]
            
            // Get existing sessions
            let defaults = UserDefaults.standard
            let sessionKey = "pomodoro.sessions"
            var savedSessions = defaults.array(forKey: sessionKey) as? [[String: Any]] ?? []
            
            // Add new session
            savedSessions.append(sessionData)
            
            // Sort by date (newest first) and limit to 50 most recent
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
            
            // Save to UserDefaults
            defaults.set(savedSessions, forKey: sessionKey)
            
            // Update counts
            totalSessionsToday += 1
            totalSessionsWeek += 1
            
            // Clear for next session
            self.sessionNotes = ""
            self.taskCompleted = false
        } else {
            // If no session was active, save with minimum duration of 1 minute
            // Create session with minimal duration
            let sessionData: [String: Any] = [
                "id": UUID().uuidString,
                "date": Date(),
                "duration": 60, // 1 minute default
                "notes": sessionNotes,
                "taskCompleted": self.taskCompleted
            ]
            
            // Get existing sessions
            let defaults = UserDefaults.standard
            let sessionKey = "pomodoro.sessions"
            var savedSessions = defaults.array(forKey: sessionKey) as? [[String: Any]] ?? []
            
            // Add new session
            savedSessions.append(sessionData)
            
            // Save to UserDefaults
            defaults.set(savedSessions, forKey: sessionKey)
            
            // Update counts
            totalSessionsToday += 1
            totalSessionsWeek += 1
            
            // Clear for next session
            self.sessionNotes = ""
            self.taskCompleted = false
        }
        
        // Reset timer after saving
        resetTimer()
    }
    
    // MARK: - Helper Methods
    private func timerFinished() {
        pauseTimer()
        
        if currentMode == .work {
            // Completed work session
            completedSessions += 1
            
            // Schedule local notification for session completion
            scheduleCompletionNotification()
            
            // Save completed session
            if let startTime = sessionStartTime {
                let duration = Int(Date().timeIntervalSince(startTime))
                // Directly create and save the session here
                let sessionData: [String: Any] = [
                    "id": UUID().uuidString,
                    "date": Date(),
                    "duration": duration,
                    "notes": sessionNotes,
                    "taskCompleted": taskCompleted
                ]
                
                // Get existing sessions
                let defaults = UserDefaults.standard
                let sessionKey = "pomodoro.sessions"
                var savedSessions = defaults.array(forKey: sessionKey) as? [[String: Any]] ?? []
                
                // Add new session
                savedSessions.append(sessionData)
                
                // Save to UserDefaults
                defaults.set(savedSessions, forKey: sessionKey)
            }
            
            // Update counts
            totalSessionsToday += 1
            totalSessionsWeek += 1
            
            // Switch to break mode
            let nextMode: PomodoroMode = completedSessions % longBreakAfterCount == 0 ? .longBreak : .shortBreak
            switchMode(nextMode)
            
            // Auto-start break if enabled
            if autoStartBreaks {
                startTimer()
            }
        } else {
            // Completed break session
            switchMode(.work)
            
            // Schedule notification for break end
            scheduleBreakEndNotification()
            
            // Auto-start work if enabled
            if autoStartWork {
                startTimer()
            }
        }
    }
    
    private func switchMode(_ mode: PomodoroMode) {
        currentMode = mode
        timeRemaining = mode == .work ? workDuration : (mode == .shortBreak ? shortBreakDuration : longBreakDuration)
        sessionStartTime = nil
    }
    
    private func startBackgroundTask() {
        if backgroundTaskID == .invalid {
            backgroundTaskID = UIApplication.shared.beginBackgroundTask { [weak self] in
                self?.endBackgroundTask()
            }
            
            if currentMode == .work {
                scheduleTimerEndNotification()
            }
        }
    }
    
    private func endBackgroundTask() {
        if backgroundTaskID != .invalid {
            UIApplication.shared.endBackgroundTask(backgroundTaskID)
            backgroundTaskID = .invalid
        }
    }
    
    private func scheduleTimerEndNotification() {
        // Cancel any existing notifications
        if let notificationID = notificationID {
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [notificationID])
        }
        
        // Create new notification
        let content = UNMutableNotificationContent()
        content.title = "Pomodoro Timer"
        content.body = "Your work session is complete! Time for a break."
        content.sound = .default
        
        // Schedule for when timer ends
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: timeRemaining, repeats: false)
        let identifier = UUID().uuidString
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        // Add to notification center
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error)")
            }
        }
        
        // Save notification ID
        notificationID = identifier
    }
    
    private func scheduleCompletionNotification() {
        let content = UNMutableNotificationContent()
        content.title = "Pomodoro Completed"
        content.body = "Great job! You've completed a focus session."
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.1, repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling completion notification: \(error)")
            }
        }
    }
    
    private func scheduleBreakEndNotification() {
        let content = UNMutableNotificationContent()
        content.title = "Break Time Over"
        content.body = "Time to get back to work!"
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.1, repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling break end notification: \(error)")
            }
        }
    }
    
    private func loadSessionCounts() {
        // Get all sessions from UserDefaults
        let defaults = UserDefaults.standard
        let sessionKey = "pomodoro.sessions"
        guard let savedSessions = defaults.array(forKey: sessionKey) as? [[String: Any]] else {
            totalSessionsToday = 0
            totalSessionsWeek = 0
            return
        }
        
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date())) ?? Date()
        
        // Calculate counts
        totalSessionsToday = savedSessions.filter { sessionDict in
            guard let date = sessionDict["date"] as? Date else { return false }
            return calendar.isDate(calendar.startOfDay(for: date), inSameDayAs: today)
        }.count
        
        totalSessionsWeek = savedSessions.filter { sessionDict in
            guard let date = sessionDict["date"] as? Date else { return false }
            return date >= weekStart
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
        let total = currentMode == .work ? workDuration : (currentMode == .shortBreak ? shortBreakDuration : longBreakDuration)
        return CGFloat(total - timeRemaining) / CGFloat(total)
    }
    
    var timeRemainingFormatted: String {
        let minutes = Int(timeRemaining) / 60
        let seconds = Int(timeRemaining) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    var statusMessage: String {
        switch currentMode {
        case .work:
            return "Focus Session"
        case .shortBreak:
            return "Short Break"
        case .longBreak:
            return "Long Break"
        }
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