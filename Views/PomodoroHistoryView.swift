// MARK: - File: PomodoroHistoryView.swift
// Purpose: Displays history of completed Pomodoro sessions
// Dependencies: SwiftUI

import SwiftUI

// Local Session model just for this view
struct SessionItem: Identifiable {
    let id: UUID
    let date: Date
    let duration: Int
    let notes: String
    let taskCompleted: Bool
    
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

struct PomodoroHistoryView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var sessions: [SessionItem] = []
    @State private var savedSessions: [[String: Any]] = [] // Original data from UserDefaults
    @State private var totalFocusTime: Int = 0
    @State private var filterDays: Int = 7
    @State private var showingDeleteConfirmation = false
    
    var body: some View {
        NavigationView {
            ZStack {
                ThemeColors.background.ignoresSafeArea()
                
                VStack(spacing: 16) {
                    // Stats summary
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(ThemeColors.panelBackground.opacity(0.3))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(ThemeColors.primaryAccent.opacity(0.3), lineWidth: 1)
                            )
                            
                        VStack(spacing: 12) {
                            Text("Focus Time")
                                .font(.headline)
                                .foregroundColor(ThemeColors.secondaryText)
                            
                            Text("\(totalFocusTime) minutes")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(ThemeColors.primaryText)
                            
                            HStack(spacing: 16) {
                                VStack {
                                    Text("\(sessions.count)")
                                        .font(.title3)
                                        .fontWeight(.bold)
                                        .foregroundColor(ThemeColors.primaryAccent)
                                    Text("Sessions")
                                        .font(.caption)
                                        .foregroundColor(ThemeColors.secondaryText)
                                }
                                .help("Total number of Pomodoro sessions completed")
                                
                                VStack {
                                    Text("\(sessions.filter({ $0.taskCompleted }).count)")
                                        .font(.title3)
                                        .fontWeight(.bold)
                                        .foregroundColor(ThemeColors.success)
                                    Text("Completed")
                                        .font(.caption)
                                        .foregroundColor(ThemeColors.secondaryText)
                                }
                                .help("Sessions marked as completed using the Complete button")
                            }
                            
                            // Time period filter
                            Picker("Time Period", selection: $filterDays) {
                                Text("7 Days").tag(7)
                                Text("14 Days").tag(14)
                                Text("30 Days").tag(30)
                                Text("All Time").tag(365)
                            }
                            .pickerStyle(SegmentedPickerStyle())
                            .padding(.horizontal)
                            .onChange(of: filterDays) { newValue in
                                loadData()
                            }
                        }
                        .padding()
                    }
                    .padding(.horizontal)
                    .frame(height: 180)
                    
                    if sessions.isEmpty {
                        Spacer()
                        
                        VStack(spacing: 16) {
                            Image(systemName: "timer")
                                .font(.system(size: 50))
                                .foregroundColor(ThemeColors.secondaryText.opacity(0.7))
                            
                            Text("No Sessions Yet")
                                .font(.title3)
                                .foregroundColor(ThemeColors.secondaryText)
                            
                            Text("Complete a focus session to see your history here.")
                                .font(.subheadline)
                                .multilineTextAlignment(.center)
                                .foregroundColor(ThemeColors.secondaryText.opacity(0.8))
                                .padding(.horizontal, 40)
                        }
                        
                        Spacer()
                    } else {
                        // Session list with swipe-to-delete
                        List {
                            ForEach(sessions) { session in
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(session.formattedDate)
                                            .font(.subheadline)
                                            .foregroundColor(ThemeColors.secondaryText)
                                        
                                        if !session.notes.isEmpty {
                                            Text(session.notes)
                                                .font(.headline)
                                                .foregroundColor(ThemeColors.primaryText)
                                        } else {
                                            Text("Focus Session")
                                                .font(.headline)
                                                .foregroundColor(ThemeColors.primaryText)
                                        }
                                    }
                                    
                                    Spacer()
                                    
                                    VStack(alignment: .trailing, spacing: 4) {
                                        Text(session.formattedDuration)
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                            .foregroundColor(ThemeColors.primaryAccent)
                                        
                                        if session.taskCompleted {
                                            HStack(spacing: 4) {
                                                Image(systemName: "checkmark.circle.fill")
                                                    .foregroundColor(ThemeColors.success)
                                                    .font(.caption)
                                                
                                                Text("Completed")
                                                    .font(.caption)
                                                    .foregroundColor(ThemeColors.success)
                                            }
                                        }
                                    }
                                }
                                .padding(.vertical, 4)
                            }
                            .onDelete(perform: deleteSession)
                        }
                        .listStyle(PlainListStyle())
                    }
                }
                .padding(.top)
            }
            .navigationTitle("Session History")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                    .foregroundColor(ThemeColors.secondaryText)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingDeleteConfirmation = true
                    } label: {
                        Image(systemName: "trash")
                            .foregroundColor(ThemeColors.warning)
                    }
                    .disabled(sessions.isEmpty)
                }
            }
            .alert(isPresented: $showingDeleteConfirmation) {
                Alert(
                    title: Text("Clear All Sessions"),
                    message: Text("Are you sure you want to delete all session history? This cannot be undone."),
                    primaryButton: .destructive(Text("Delete All")) {
                        clearAllSessions()
                    },
                    secondaryButton: .cancel()
                )
            }
        }
        .onAppear {
            loadData()
        }
    }
    
    private func loadData() {
        // Get sessions from UserDefaults
        let defaults = UserDefaults.standard
        let sessionKey = "pomodoro.sessions"
        
        // Store original data for delete operations
        savedSessions = defaults.array(forKey: sessionKey) as? [[String: Any]] ?? []
        
        guard !savedSessions.isEmpty else {
            sessions = []
            totalFocusTime = 0
            return
        }
        
        // Filter by date range
        let calendar = Calendar.current
        let startDate = calendar.date(byAdding: .day, value: -filterDays, to: Date()) ?? Date()
        
        // Convert to SessionItem objects and filter
        let filteredSessions = savedSessions.compactMap { sessionDict -> SessionItem? in
            guard let idString = sessionDict["id"] as? String,
                  let date = sessionDict["date"] as? Date,
                  let duration = sessionDict["duration"] as? Int else {
                return nil
            }
            
            // Filter by date range
            if date < startDate && filterDays != 365 {
                return nil
            }
            
            // Directly access task completion status (default to true for backward compatibility)
            let isCompleted = sessionDict["taskCompleted"] as? Bool ?? true
            
            return SessionItem(
                id: UUID(uuidString: idString) ?? UUID(),
                date: date,
                duration: duration,
                notes: sessionDict["notes"] as? String ?? "",
                taskCompleted: isCompleted
            )
        }
        
        // Sort by date (newest first)
        sessions = filteredSessions.sorted { $0.date > $1.date }
        
        // Calculate total focus time
        totalFocusTime = sessions.reduce(0) { $0 + ($1.duration / 60) }
    }
    
    private func deleteSession(at offsets: IndexSet) {
        // Get the sessions to delete
        let sessionsToDelete = offsets.map { sessions[$0] }
        
        // Remove from UI list
        sessions.remove(atOffsets: offsets)
        
        // Update the saved sessions list by removing the matched IDs
        for sessionToDelete in sessionsToDelete {
            savedSessions.removeAll { sessionDict in
                guard let idString = sessionDict["id"] as? String,
                      let id = UUID(uuidString: idString) else {
                    return false
                }
                return id == sessionToDelete.id
            }
        }
        
        // Save the updated list back to UserDefaults
        UserDefaults.standard.set(savedSessions, forKey: "pomodoro.sessions")
        
        // Recalculate total focus time
        totalFocusTime = sessions.reduce(0) { $0 + ($1.duration / 60) }
    }
    
    private func clearAllSessions() {
        // Clear all sessions from UserDefaults
        UserDefaults.standard.removeObject(forKey: "pomodoro.sessions")
        
        // Clear UI
        sessions = []
        savedSessions = []
        totalFocusTime = 0
    }
}

struct PomodoroHistoryView_Previews: PreviewProvider {
    static var previews: some View {
        PomodoroHistoryView()
            .preferredColorScheme(.dark)
    }
} 
