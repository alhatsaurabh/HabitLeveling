// MARK: - File: StatusSectionView.swift
// Purpose: Displays the user status summary section on the Dashboard.
// Dependencies: DashboardViewModel, ThemeColors, SoloPanelModifier,
//               CombinedLevelEssenceView, StatDistributionBarView
// Update: Redesigned layout for Solo Leveling aesthetic.
// Update 2: Added swipe gesture to show the calendar view

import SwiftUI

struct StatusSectionView: View {
    // Accepts the DashboardViewModel to display its data
    @ObservedObject var viewModel: DashboardViewModel
    @State private var showingCalendar: Bool = false
    @State private var dragOffset: CGFloat = 0
    
    // Calculate progress for the CombinedLevelEssenceView
    private var xpProgress: Double {
        guard viewModel.xpGoal > 0 else { return 0.0 }
        // Ensure progress doesn't exceed 1.0 if xp somehow goes over goal temporarily
        return min(1.0, max(0.0, Double(viewModel.userXP) / Double(viewModel.xpGoal)))
    }

    var body: some View {
        ZStack {
            // Mini Calendar View (shown when swiped)
            if showingCalendar {
                MiniCalendarView()
            }
            
            // Status Panel (main view)
            statusPanel
                .offset(x: showingCalendar ? -UIScreen.main.bounds.width : 0)
                .animation(.spring(response: 0.3, dampingFraction: 0.8), value: showingCalendar)
        }
        .gesture(
            DragGesture()
                .onChanged { gesture in
                    if !showingCalendar {
                        // Only allow left swipe (negative values) when showing status
                        self.dragOffset = min(0, gesture.translation.width)
                    } else {
                        // Only allow right swipe (positive values) when showing calendar
                        self.dragOffset = max(0, gesture.translation.width)
                    }
                }
                .onEnded { gesture in
                    // Determine if we should switch views based on drag distance
                    if !showingCalendar && gesture.translation.width < -50 {
                        // Swiped left enough to show calendar
                        self.showingCalendar = true
                    } else if showingCalendar && gesture.translation.width > 50 {
                        // Swiped right enough to show status
                        self.showingCalendar = false
                    }
                    
                    // Reset drag offset
                    self.dragOffset = 0
                }
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
                
                // Swipe indicator
                HStack {
                    Spacer()
                    Image(systemName: "chevron.left")
                        .font(.caption)
                        .foregroundColor(ThemeColors.secondaryText.opacity(0.7))
                    Text("Swipe for calendar")
                        .font(.caption)
                        .foregroundColor(ThemeColors.secondaryText.opacity(0.7))
                    Spacer()
                }
                .padding(.top, 5)
            }
            .padding(20)

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
        .background(ThemeColors.panelBackground.opacity(0.3))
        .clipShape(RoundedRectangle(cornerRadius: 15))
        .overlay(
            RoundedRectangle(cornerRadius: 15)
                .stroke(ThemeColors.primaryAccent.opacity(0.3), lineWidth: 1)
        )
        .padding(.horizontal)
        .offset(x: dragOffset) // Apply drag offset while dragging
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
