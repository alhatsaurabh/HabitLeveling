// MARK: - File: StatusSectionView.swift
// Purpose: Displays the user status summary section on the Dashboard.
// Dependencies: DashboardViewModel, ThemeColors, SoloPanelModifier,
//               CombinedLevelEssenceView, StatDistributionBarView
// Update: Redesigned layout for Solo Leveling aesthetic.
// Update 2: Added swipe gesture to show the calendar view
// Update 3: Added Pomodoro timer panel for productivity tracking

import SwiftUI
import CoreData
#if os(iOS)
import UIKit
#endif

struct StatusSectionView: View {
    // Accepts the DashboardViewModel to display its data
    @ObservedObject var viewModel: DashboardViewModel
    @State private var currentPanel: PanelType = .status
    @State private var showFullCalendar: Bool = false
    @State private var showPomodoroSettings: Bool = false
    @State private var showPomodoroHistory: Bool = false
    
    // Environment
    @Environment(\.managedObjectContext) private var viewContext
    
    // Calendar view model
    @StateObject private var calendarViewModel = CalendarViewModel()
    
    // Pomodoro Timer State
    @StateObject private var pomodoroViewModel = PomodoroViewModel()
    
    // State for button animation
    @State private var showGreenCheck: Bool = false
    
    // Enum for panel types
    private enum PanelType: Int {
        case pomodoro = 0
        case status = 1
        case calendar = 2
    }
    
    // Calculate progress for the CombinedLevelEssenceView
    private var xpProgress: Double {
        guard viewModel.xpGoal > 0 else { return 0.0 }
        // Ensure progress doesn't exceed 1.0 if xp somehow goes over goal temporarily
        return min(1.0, max(0.0, Double(viewModel.userXP) / Double(viewModel.xpGoal)))
    }

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                if currentPanel == .status {
                    // Show status panel
                    statusPanel
                        .transition(
                            .asymmetric(
                                insertion: .move(edge: currentPanel == .pomodoro ? .trailing : .leading),
                                removal: .move(edge: currentPanel == .pomodoro ? .trailing : .leading)
                            )
                        )
                } else if currentPanel == .calendar {
                    // Show calendar panel
                    calendarPanel
                        .transition(
                            .asymmetric(
                                insertion: .move(edge: .trailing),
                                removal: .move(edge: .trailing)
                            )
                        )
                } else {
                    // Show pomodoro panel
                    pomodoroPanel
                        .transition(
                            .asymmetric(
                                insertion: .move(edge: .leading),
                                removal: .move(edge: .leading)
                            )
                        )
                }
            }
            .frame(maxWidth: .infinity)
            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: currentPanel)
            
            // Navigation dots - 3 dots now
            HStack(spacing: 4) {
                Circle()
                    .fill(currentPanel == .pomodoro ? ThemeColors.primaryAccent : ThemeColors.secondaryText.opacity(0.7))
                    .frame(width: currentPanel == .pomodoro ? 6 : 4, height: currentPanel == .pomodoro ? 6 : 4)
                Circle()
                    .fill(currentPanel == .status ? ThemeColors.primaryAccent : ThemeColors.secondaryText.opacity(0.7))
                    .frame(width: currentPanel == .status ? 6 : 4, height: currentPanel == .status ? 6 : 4)
                Circle()
                    .fill(currentPanel == .calendar ? ThemeColors.primaryAccent : ThemeColors.secondaryText.opacity(0.7))
                    .frame(width: currentPanel == .calendar ? 6 : 4, height: currentPanel == .calendar ? 6 : 4)
            }
            .padding(.top, 8)
        }
        .gesture(
            DragGesture()
                .onEnded { gesture in
                    // Determine swipe direction and distance
                    let threshold: CGFloat = 50
                    
                    if gesture.translation.width < -threshold {
                        // Swiped left - move to next panel (right)
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                            switch currentPanel {
                            case .pomodoro:
                                currentPanel = .status
                            case .status:
                                currentPanel = .calendar
                                // Load calendar data
                                DispatchQueue.main.async {
                                    calendarViewModel.loadAllCompletions(context: viewContext)
                                }
                            case .calendar:
                                // Already at last panel, do nothing
                                break
                            }
                        }
                    } else if gesture.translation.width > threshold {
                        // Swiped right - move to previous panel (left)
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                            switch currentPanel {
                            case .pomodoro:
                                // Already at first panel, do nothing
                                break
                            case .status:
                                currentPanel = .pomodoro
                            case .calendar:
                                currentPanel = .status
                            }
                        }
                    }
                }
        )
        .fullScreenCover(isPresented: $showFullCalendar) {
            CalendarView()
                .environment(\.managedObjectContext, viewContext)
        }
        .onAppear {
            // Set default panel to status on appear
            currentPanel = .status
            
            // Initial load
            calendarViewModel.loadAllCompletions(context: viewContext)
            
            // Register for habit completion notifications
            NotificationCenter.default.addObserver(forName: .habitCompleted, object: nil, queue: .main) { _ in
                calendarViewModel.loadAllCompletions(context: viewContext)
            }
        }
        .onChange(of: calendarViewModel.selectedDay) { _ in
            // Refresh the view when the selected day changes
            calendarViewModel.loadAllCompletions(context: viewContext)
        }
    }
    
    // Pomodoro panel content
    private var pomodoroPanel: some View {
        VStack(spacing: 0) {
            // Fixed Header
            HStack {
                Text("Pomodoro Timer")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(ThemeColors.primaryText)
                
                Spacer()
                
                // History button (now first)
                Button(action: {
                    showPomodoroHistory = true
                }) {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.headline)
                        .foregroundColor(ThemeColors.secondaryText)
                }
                .padding(.trailing, 8)
                
                // Settings button (now second)
                Button(action: {
                    showPomodoroSettings = true
                }) {
                    Image(systemName: "gearshape")
                        .font(.headline)
                        .foregroundColor(ThemeColors.secondaryText)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .padding(.top, 4)
            .background(ThemeColors.panelBackground.opacity(0.3))

            // Fixed Content Area with proper spacing
            VStack(spacing: 0) {
                // Timer display
                VStack(spacing: 12) {
                    // Timer circle
                    ZStack {
                        // Background circle
                        Circle()
                            .stroke(ThemeColors.secondaryText.opacity(0.2), lineWidth: 6)
                            .frame(width: 150, height: 150)
                        
                        // Progress circle with glow
                        Circle()
                            .trim(from: 0, to: pomodoroViewModel.progress)
                            .stroke(
                                LinearGradient(
                                    colors: [timerColor(), timerColor().opacity(0.7)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                ),
                                style: StrokeStyle(lineWidth: 6, lineCap: .round)
                            )
                            .frame(width: 150, height: 150)
                            .rotationEffect(.degrees(-90))
                            .shadow(color: timerColor().opacity(pomodoroViewModel.progress > 0.7 ? (pomodoroViewModel.progress - 0.7) / 0.3 * 0.8 : 0), 
                                    radius: pomodoroViewModel.progress > 0.7 ? 5 * (pomodoroViewModel.progress - 0.7) / 0.3 : 0)
                        
                        // Timer text
                        VStack(spacing: 4) {
                            Text(pomodoroViewModel.timeRemainingFormatted)
                                .font(.system(size: 36, weight: .bold, design: .monospaced))
                                .foregroundColor(ThemeColors.primaryText)
                            
                            Text(pomodoroViewModel.isRunning ? "Running" : "Paused")
                                .font(.caption)
                                .foregroundColor(ThemeColors.secondaryText)
                        }
                    }
                    .padding(.top, 20)
                    
                    // Session type
                    Text(pomodoroViewModel.currentSession.rawValue)
                        .font(.headline)
                        .foregroundColor(timerColor())
                        .padding(.top, 4)
                    
                    // Control buttons
                    HStack(spacing: 30) {
                        Button(action: {
                            pomodoroViewModel.resetTimer()
                        }) {
                            Image(systemName: "arrow.clockwise")
                                .font(.title2)
                                .foregroundColor(ThemeColors.secondaryText)
                        }
                        
                        Button(action: {
                            pomodoroViewModel.toggleTimer()
                        }) {
                            Image(systemName: pomodoroViewModel.isRunning ? "pause.fill" : "play.fill")
                                .font(.title)
                                .foregroundColor(ThemeColors.primaryAccent)
                        }
                        
                        Button(action: {
                            pomodoroViewModel.skipSession()
                        }) {
                            Image(systemName: "forward.fill")
                                .font(.title2)
                                .foregroundColor(ThemeColors.secondaryText)
                        }
                    }
                    .padding(.vertical, 12)
                }
                
                // Show divider only during work mode
                if pomodoroViewModel.currentMode == .work {
                    Divider()
                        .background(ThemeColors.secondaryText.opacity(0.3))
                        .padding(.horizontal)
                        .padding(.vertical, 8)
                }
                
                // Combined Notes and Complete Action Row
                HStack(alignment: .center, spacing: 10) { // Use HStack
                    // Notes TextField (Show only during work mode)
                    if pomodoroViewModel.currentMode == .work {
                        TextField("What are you working on?", text: $pomodoroViewModel.sessionNotes)
                            .font(.subheadline)
                            .padding(8)
                            .background(ThemeColors.panelBackground.opacity(0.6))
                            .cornerRadius(8)
                            .frame(maxWidth: .infinity) // Allow TextField to expand
                    }
                    
                    // Compact Complete Button (Icon only) - Show only during work mode
                    if pomodoroViewModel.currentMode == .work {
                        Button(action: {
                            // Set completed state before saving
                            pomodoroViewModel.taskCompleted = true
                            
                            // Trigger save and visual feedback
                            pomodoroViewModel.saveCompletedSession() // No longer needs parameter
                            showGreenCheck = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                                pomodoroViewModel.skipToNext() // Execute mode switch AFTER delay
                                withAnimation { // Optional: Add animation for fade
                                    showGreenCheck = false
                                    // Let view model handle state reset in switchMode/timerFinished
                                }
                            }
                        }) {
                            // Determine button content based on state
                            Group { // Use Group for conditional content
                                if showGreenCheck {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(ThemeColors.success)
                                } else if pomodoroViewModel.dailyCompletedFocusSessions > 0 { // Use renamed counter
                                    ZStack {
                                        Circle().fill(ThemeColors.secondaryText.opacity(0.3))
                                        Text("\(pomodoroViewModel.dailyCompletedFocusSessions)") // Use renamed counter
                                            .font(.caption) // Smaller font for number
                                            .fontWeight(.bold)
                                            .foregroundColor(ThemeColors.secondaryText)
                                    }
                                } else {
                                    Image(systemName: "circle")
                                        .foregroundColor(ThemeColors.secondaryText)
                                }
                            }
                            .font(.title2) // Apply font size to the Group
                            .frame(width: 28, height: 28) // Give the icon area a fixed size
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal) // Padding for the HStack
                .padding(.top, 4)
                .padding(.bottom, 16) // Bottom padding for the row
            }
            .padding(.top, 4)
            .frame(height: 340)
        }
        .padding(.horizontal)
        .background(ThemeColors.panelBackground.opacity(0.3))
        .clipShape(RoundedRectangle(cornerRadius: 15))
        .overlay(
            RoundedRectangle(cornerRadius: 15)
                .stroke(ThemeColors.primaryAccent.opacity(0.3), lineWidth: 1)
        )
        .sheet(isPresented: $showPomodoroSettings) {
            PomodoroSettingsView(pomodoroViewModel: pomodoroViewModel)
        }
        .sheet(isPresented: $showPomodoroHistory) {
            PomodoroHistoryView()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            // Only check status when app comes back to foreground
            if pomodoroViewModel.isRunning {
                pomodoroViewModel.checkTimerStatus()
            }
        }
        // Action: Add onChange to trigger animation on timer completion
        .onChange(of: pomodoroViewModel.timeRemaining) { newValue in
            if newValue <= 0 && pomodoroViewModel.currentMode == .work && !pomodoroViewModel.isRunning {
                 // Timer just finished a work session naturally
                 showGreenCheck = true
                 DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                     withAnimation {
                         showGreenCheck = false
                     }
                 }
             }
         }
    }
    
    // Helper function for timer color
    private func timerColor() -> Color {
        switch pomodoroViewModel.currentSession {
        case .focus:
            return ThemeColors.primaryAccent
        case .shortBreak:
            return ThemeColors.warning // Changed from secondaryAccent to warning (orange)
        case .longBreak:
            return ThemeColors.success // This is already green - keeping as is
        }
    }
    
    // Calendar panel content
    private var calendarPanel: some View {
        VStack(spacing: 0) {
            // Fixed Header
            HStack {
                Text("Recent Progress")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(ThemeColors.primaryText)
                
                Spacer()
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .padding(.top, 4)
            .background(ThemeColors.panelBackground.opacity(0.3))

            // Fixed Content Area
            VStack(spacing: 12) {
                // Mini heat map calendar
                VStack(spacing: 8) {
                    // Month display
                    Text(calendarViewModel.currentMonthTitle)
                        .font(.subheadline)
                        .foregroundColor(ThemeColors.secondaryText)
                    
                    // Weekday headers
                    HStack {
                        ForEach(calendarViewModel.weekdaySymbols, id: \.self) { symbol in
                            Text(symbol)
                                .font(.system(size: 10))
                                .fontWeight(.medium)
                                .foregroundColor(ThemeColors.secondaryText)
                                .frame(maxWidth: .infinity)
                        }
                    }
                    
                    // Calendar grid
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 4) {
                        ForEach(calendarViewModel.days) { day in
                            MiniCalendarDayCell(day: day, completionIntensity: calendarViewModel.completionIntensity(for: day.date))
                                .onTapGesture {
                                    calendarViewModel.selectDay(day, context: viewContext)
                                }
                        }
                    }
                }
                .padding(.horizontal)
                
                // Stats summary
                HStack {
                    VStack(alignment: .center) {
                        Text("\(calendarViewModel.totalCompletions)")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(ThemeColors.primaryText)
                        Text("Total")
                            .font(.system(size: 10))
                            .foregroundColor(ThemeColors.secondaryText)
                    }
                    .frame(maxWidth: .infinity)
                    
                    Divider()
                        .frame(height: 30)
                        .background(ThemeColors.secondaryText.opacity(0.3))
                    
                    VStack(alignment: .center) {
                        Text("\(calendarViewModel.mostActiveDay.0)")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(ThemeColors.primaryText)
                        Text("Best Day")
                            .font(.system(size: 10))
                            .foregroundColor(ThemeColors.secondaryText)
                    }
                    .frame(maxWidth: .infinity)
                }
                .padding(.horizontal)
                
                // View Full Calendar button
                Button(action: {
                    showFullCalendar = true
                }) {
                    Text("View Full Calendar")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .padding(.vertical, 8)
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(ThemeColors.primaryAccent.opacity(0.2))
                        )
                        .foregroundColor(ThemeColors.primaryAccent)
                }
                .padding(.horizontal)
                .padding(.bottom, 16)
            }
            .padding(.top, 8)
            .frame(height: 320)
        }
        .padding(.horizontal)
        .background(ThemeColors.panelBackground.opacity(0.3))
        .clipShape(RoundedRectangle(cornerRadius: 15))
        .overlay(
            RoundedRectangle(cornerRadius: 15)
                .stroke(ThemeColors.primaryAccent.opacity(0.3), lineWidth: 1)
        )
    }
    
    // Status panel content
    private var statusPanel: some View {
        ZStack(alignment: .topTrailing) { // Main container with mana overlay
            VStack(alignment: .leading, spacing: 15) {
                // Top Row: Level/XP + Rank/Title
                HStack(alignment: .center, spacing: 15) {
                    // Level/XP Circle with Essence Core
                    CombinedLevelEssenceView(
                        level: viewModel.userLevel,
                        progress: xpProgress,
                        essenceState: viewModel.essenceCoreState
                    )
                    .frame(width: 100, height: 100)
                    .padding(.top, 4) // Add padding above the circular indicator

                    // User Info
                    VStack(alignment: .leading, spacing: 2) {
                        Text(viewModel.hunterRank)
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(ThemeColors.primaryText)
                            .shadow(color: ThemeColors.glowColor, radius: 2)
                        Text(viewModel.title)
                            .font(.headline)
                            .fontWeight(.medium)
                            .foregroundColor(ThemeColors.tertiaryAccent ?? ThemeColors.primaryAccent)
                        Text("Job: \(viewModel.job)")
                            .font(.subheadline)
                            .foregroundColor(ThemeColors.secondaryText)
                    }
                    Spacer()
                }

                // Middle Row: Stat Focus
                VStack(alignment: .leading, spacing: 4) {
                    Text("Stat Focus")
                        .font(.caption)
                        .foregroundColor(ThemeColors.secondaryText)
                    StatDistributionBarView(statPoints: viewModel.statPoints)
                        .frame(height: 12)
                        .clipShape(Capsule())
                }

                // Bottom Row: Stats
                VStack(alignment: .leading, spacing: 8) {
                    SimpleStatRow(
                        icon: "flame.fill",
                        label: "Streak:",
                        value: "\(viewModel.overallStreak) days",
                        iconColor: ThemeColors.warning
                    )
                    SimpleStatRow(
                        icon: "checkmark.circle.fill",
                        label: "Completions:",
                        value: "\(viewModel.totalCompletions)",
                        iconColor: ThemeColors.success
                    )
                }
                
            }
            .padding(20)
            .frame(height: 260)

            // Mana Crystals Overlay
            HStack(spacing: 4) {
                Image(systemName: "circle.hexagongrid.fill")
                    .imageScale(.small)
                    .foregroundColor(ThemeColors.secondaryAccent)
                Text("\(viewModel.manaCrystals)")
                    .font(.callout)
                    .fontWeight(.bold)
                    .foregroundColor(ThemeColors.secondaryAccent)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(ThemeColors.panelBackground.opacity(0.85))
                    .blur(radius: 3)
            )
            .padding(12)
        }
        .padding(.horizontal)
        .background(ThemeColors.panelBackground.opacity(0.3))
        .clipShape(RoundedRectangle(cornerRadius: 15))
        .overlay(
            RoundedRectangle(cornerRadius: 15)
                .stroke(ThemeColors.primaryAccent.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - Mini Calendar Day Cell
struct MiniCalendarDayCell: View {
    let day: CalendarDay
    let completionIntensity: Double // 0.0 to 1.0
    
    var body: some View {
        ZStack {
            // Background
            RoundedRectangle(cornerRadius: 4)
                .fill(
                    day.isToday ? ThemeColors.secondaryAccent.opacity(0.3) :
                    !day.isCurrentMonth ? ThemeColors.panelBackground.opacity(0.3) : Color.clear
                )
            
            // Heat map background
            if completionIntensity > 0 {
                RoundedRectangle(cornerRadius: 4)
                    .fill(heatMapColor(for: completionIntensity))
            }
            
            // Day content
            Text(day.number)
                .font(.system(size: 10, weight: day.isToday ? .bold : .regular))
                .foregroundColor(dayTextColor())
        }
        .frame(height: 24)
        .overlay(
            RoundedRectangle(cornerRadius: 4)
                .stroke(day.isSelected ? ThemeColors.primaryAccent : Color.clear, lineWidth: 1)
        )
    }
    
    // Helper function to determine text color based on state
    private func dayTextColor() -> Color {
        if day.isToday {
            return ThemeColors.primaryText
        } else if !day.isCurrentMonth {
            return ThemeColors.secondaryText.opacity(0.5)
        } else {
            return ThemeColors.primaryText
        }
    }
    
    // Helper function to get heat map color based on intensity
    private func heatMapColor(for intensity: Double) -> Color {
        if intensity <= 0 {
            return Color.clear
        } else if intensity < 0.25 {
            return Color.green.opacity(0.2)
        } else if intensity < 0.5 {
            return Color.green.opacity(0.4)
        } else if intensity < 0.75 {
            return Color.green.opacity(0.6)
        } else {
            return Color.green.opacity(0.8)
        }
    }
}

struct SimpleStatRow: View {
    let icon: String
    let label: String
    let value: String
    let iconColor: Color
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.callout)
                .foregroundColor(iconColor)
                .frame(width: 20)
            Text(label)
                .font(.callout)
                .foregroundColor(ThemeColors.secondaryText)
            Text(value)
                .font(.callout)
                .fontWeight(.medium)
                .foregroundColor(ThemeColors.primaryText)
            Spacer()
        }
    }
}

// MARK: - Mana Crystal View (Helper)
struct ManaCrystalView: View {
    let mana: Int

    var body: some View {
        HStack(spacing: 3) { // Reduced spacing
            Image(systemName: "hexagon.fill")
                .font(.subheadline) // Smaller
                .foregroundStyle(
                    .linearGradient(
                        colors: [ThemeColors.secondaryAccent, ThemeColors.primaryAccent],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    Image(systemName: "sparkle")
                        .font(.system(size: 7)) // Smaller sparkle
                        .foregroundColor(.white.opacity(0.8))
                        .offset(x: 0, y: 0.5)
                )
                .shadow(color: ThemeColors.glowColor, radius: 2, x: 0, y: 0)
            Text("\(mana)")
                .font(.subheadline)
                .fontWeight(.bold)
                .foregroundColor(ThemeColors.primaryText)
                .monospacedDigit()
        }
        .padding(.horizontal, 8) // Reduced padding
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(ThemeColors.panelBackground.opacity(0.6))
                .overlay(Capsule().stroke(ThemeColors.primaryAccent.opacity(0.3), lineWidth: 1))
        )
    }
}

// MARK: - Preview (Optional)
struct StatusSectionView_Previews: PreviewProvider {
    // Mock ThemeColors for preview if needed
    struct PreviewThemeColors {
        static let background = Color.black; static let primaryText = Color.white; static let secondaryText = Color.gray; static let panelBackground = Color.gray.opacity(0.2); static let glowColor = Color.cyan.opacity(0.5); static let primaryAccent = Color.purple; static let secondaryAccent = Color.blue; static let tertiaryAccent: Color? = .yellow; static let warning = Color.orange; static let success = Color.green
        // Mock Stat Colors
        static let strengthStat: Color? = .red; static let vitalityStat: Color? = .green; static let agilityStat: Color? = .blue; static let intelligenceStat: Color? = .purple; static let perceptionStat: Color? = .orange
    }
    static let ThemeColors = PreviewThemeColors.self

    // --- REMOVED Local SoloPanelModifier struct ---
    // --- REMOVED Local extension View { func soloPanelStyle()... } ---
    // Preview relies on GLOBAL SoloPanelModifier.swift

    // Mock Child Views for preview
    struct CombinedLevelEssenceView: View { var level: Int; var progress: Double; var essenceState: String; var body: some View { ZStack { Circle().strokeBorder(.white, lineWidth: 2); Text("\(level)").foregroundColor(.white) } } }
    struct StatDistributionBarView: View { var statPoints: [String: Int64]; var body: some View { HStack { Rectangle().fill(.red); Rectangle().fill(.green) }.frame(height: 10) } }

    // Mock DashboardViewModel for preview
    // NOTE: This needs to match the actual DashboardViewModel structure
    // If DashboardViewModel itself relies on complex managers, mocking might need adjustment
    class MockDashboardViewModel: DashboardViewModel {
        override init() {
            super.init()
            // Set some default values for preview
            self.userLevel = 12
            self.userXP = 350
            self.xpGoal = 800
            self.hunterRank = "Rank D"
            self.title = "Wolf Slayer"
            self.job = "Hunter - Awakened"
            self.essenceCoreState = "Bright"
            self.manaCrystals = 42
            self.statPoints = ["STR": 150, "VIT": 120, "AGI": 110, "INT": 180, "PER": 90]
            self.overallStreak = 7
            self.totalCompletions = 55
        }
    }

    static var previews: some View {
        StatusSectionView(viewModel: MockDashboardViewModel())
            .padding()
            .background(PreviewThemeColors.background)
            .preferredColorScheme(.dark)
    }
}
