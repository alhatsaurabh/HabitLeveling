// MARK: - File: PomodoroSession.swift
// Purpose: Model for storing completed Pomodoro sessions
// Dependencies: Foundation

import Foundation

struct PomodoroSession: Identifiable, Codable {
    let id: UUID
    let date: Date
    let duration: Int // in seconds
    let notes: String
    let taskCompleted: Bool
    
    init(id: UUID = UUID(), date: Date = Date(), duration: Int, notes: String, taskCompleted: Bool = false) {
        self.id = id
        self.date = date
        self.duration = duration
        self.notes = notes
        self.taskCompleted = taskCompleted
    }
    
    // Computed properties for display
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    var formattedDuration: String {
        let minutes = duration / 60
        return "\(minutes) min"
    }
}

// Extension to handle session storage and retrieval
extension PomodoroSession {
    private static let storageKey = "pomodoro.sessions"
    
    // Save a session to UserDefaults
    static func saveSession(_ session: PomodoroSession) {
        var sessions = loadSessions()
        sessions.append(session)
        
        // Keep only the last 50 sessions to avoid storage issues
        if sessions.count > 50 {
            sessions = Array(sessions.sorted { $0.date > $1.date }.prefix(50))
        }
        
        if let data = try? JSONEncoder().encode(sessions) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }
    
    // Load all saved sessions
    static func loadSessions() -> [PomodoroSession] {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let sessions = try? JSONDecoder().decode([PomodoroSession].self, from: data) else {
            return []
        }
        return sessions.sorted { $0.date > $1.date }
    }
    
    // Clear all session history
    static func clearSessions() {
        UserDefaults.standard.removeObject(forKey: storageKey)
    }
    
    // Get total focus time (in minutes) for a given time period
    static func totalFocusTime(days: Int = 7) -> Int {
        let calendar = Calendar.current
        let startDate = calendar.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        
        let sessions = loadSessions().filter { $0.date >= startDate }
        let totalSeconds = sessions.reduce(0) { $0 + $1.duration }
        
        return totalSeconds / 60 // Convert to minutes
    }
    
    // Get sessions grouped by day for a given time period
    static func sessionsGroupedByDay(days: Int = 7) -> [Date: [PomodoroSession]] {
        let calendar = Calendar.current
        let startDate = calendar.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        
        let filteredSessions = loadSessions().filter { $0.date >= startDate }
        
        var groupedSessions: [Date: [PomodoroSession]] = [:]
        
        for session in filteredSessions {
            // Strip time components to group by day
            let components = calendar.dateComponents([.year, .month, .day], from: session.date)
            if let dayDate = calendar.date(from: components) {
                var sessionsForDay = groupedSessions[dayDate] ?? []
                sessionsForDay.append(session)
                groupedSessions[dayDate] = sessionsForDay
            }
        }
        
        return groupedSessions
    }
} 