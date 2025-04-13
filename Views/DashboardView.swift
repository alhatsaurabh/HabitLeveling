// MARK: - File: DashboardView.swift
// Update: Using .sheet(item:) for presenting AddEditHabitView to fix template bug.
// Update 2: Refactored body using @ViewBuilder properties to potentially fix type-checking error.

import SwiftUI
import CoreData
import Combine

// Assume Notification Names are defined elsewhere (e.g., HabitTrackingManager)
// Assume HabitTemplate struct exists and is Identifiable (has an 'id' property of UUID)
// Assume ThemeColors exists globally
// Assume placeholder views (StatusSectionView, ActiveQuestsSectionView, LevelUpView, ArtifactEarnedView) exist
// Assume HabitTemplatePickerView exists
// Assume AddEditHabitView exists
// Assume StatsView exists
// Assume DashboardViewModel exists

struct DashboardView: View {
    // MARK: - Properties & State
    @StateObject private var viewModel = DashboardViewModel()
    @Environment(\.managedObjectContext) private var viewContext

    // Sheet Presentation State
    enum SheetType: Identifiable {
        case custom
        case template(HabitTemplate)
        var id: String {
            switch self {
            case .custom: return "custom"
            case .template(let template): return template.id.uuidString
            }
        }
    }
    @State private var sheetToShow: SheetType? = nil
    @State private var showingStatsSheet = false
    @State private var showingTemplatePicker = false
    @State private var habitToEdit: Habit? = nil

    // Add Habit Options State
    @State private var showingAddHabitOptions = false

    // Overlay State
    @State private var levelUpInfo: Int? = nil
    @State private var showLevelUpOverlay = false
    @State private var earnedArtifactName: String? = nil
    @State private var showArtifactOverlay = false

    // Theme
    let themeAccentColor = ThemeColors.primaryAccent

    // MARK: - Body
    var body: some View {
        NavigationView {
            ZStack { // Use ZStack for layering
                ThemeColors.background.ignoresSafeArea() // Layer 1: Background, edge-to-edge

                mainContent // Layer 2: Content, respects safe areas
            }
            .overlay(alignment: .center) { levelUpOverlayContent } // Apply modifiers to ZStack
            .overlay(alignment: .center) { artifactEarnedOverlayContent } // Apply modifiers to ZStack
            .navigationTitle("Dashboard")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { navigationToolbarContent }
            .onAppear { viewModel.fetchAllData() }
            .confirmationDialog("Add New Quest", isPresented: $showingAddHabitOptions, titleVisibility: .visible) {
                Button("Choose from Template") { self.showingTemplatePicker = true }
                Button("Create Custom Habit") { self.sheetToShow = .custom }
                Button("Cancel", role: .cancel) { }
            } message: { Text("Select a method to add a new quest.") }
            // --- Sheet Presenters --- Applied to ZStack
            .sheet(isPresented: $showingStatsSheet) { StatsView() }
            .sheet(isPresented: $showingTemplatePicker) { templatePickerSheet }
            .sheet(item: $sheetToShow, onDismiss: { viewModel.fetchHabits() }) { sheetContent(for: $0) }
            .sheet(item: $habitToEdit, onDismiss: { viewModel.fetchHabits() }) { editSheetContent(for: $0) }
            // --- .onReceive modifiers --- Applied to ZStack
            .onReceive(viewModel.levelUpSubject) { level in handleLevelUp(level) }
            .onReceive(NotificationCenter.default.publisher(for: .didEarnArtifact)) { notification in handleArtifactEarned(notification) }
        }
        .tint(themeAccentColor)
    }

    // MARK: - @ViewBuilder Helper Properties

    /// The main content stack of the dashboard.
    @ViewBuilder private var mainContent: some View {
        VStack(alignment: .leading, spacing: 0) {
            StatusSectionView(viewModel: viewModel)
                .padding(.bottom, 15) // Keep spacing between sections

            ActiveQuestsSectionView(
                viewModel: viewModel,
                onAddTapped: { self.showingAddHabitOptions = true },
                habitToEdit: $habitToEdit
            )
            // No explicit bottom padding here, let safe area handle it

            Spacer() // Pushes content to the top
        }
        // .background(ThemeColors.background) // REMOVE background from VStack
    }

    /// The content for the level up overlay.
    @ViewBuilder private var levelUpOverlayContent: some View {
        if showLevelUpOverlay {
            LevelUpView(level: levelUpInfo ?? viewModel.userLevel)
                .transition(.opacity.combined(with: .scale(scale: 0.8)))
                .zIndex(1) // Ensure it's above main content
        }
    }

    /// The content for the artifact earned overlay.
    @ViewBuilder private var artifactEarnedOverlayContent: some View {
        if showArtifactOverlay {
            ArtifactEarnedView(artifactName: earnedArtifactName ?? "?")
                .transition(.opacity.combined(with: .scale(scale: 0.8)))
                .zIndex(2) // Ensure it's above level up overlay
        }
    }

    /// The content for the template picker sheet.
    @ViewBuilder private var templatePickerSheet: some View {
         HabitTemplatePickerView { selectedTemplate in
             // Set the state variable to trigger the .sheet(item:) modifier for templates
             self.sheetToShow = .template(selectedTemplate)
         }
    }

    // MARK: - @ToolbarContentBuilder Helper Property

    /// The content for the navigation bar toolbar.
    @ToolbarContentBuilder private var navigationToolbarContent: some ToolbarContent {
        ToolbarItem(placement: .navigationBarTrailing) {
            Button {
                self.showingStatsSheet = true
            } label: {
                Image(systemName: "list.bullet.rectangle.portrait")
                    .font(.title3)
            }
            .foregroundColor(themeAccentColor) // Apply color here if needed, or rely on .tint
        }
    }

    // MARK: - Helper Functions for Sheet Content

    /// Provides the content view for the Add/Template sheet based on the SheetType item.
    @ViewBuilder private func sheetContent(for item: SheetType) -> some View {
        // Pass the context explicitly if AddEditHabitView needs it
        // Otherwise, it might inherit from the environment if this sheet is within the NavigationView hierarchy
        switch item {
        case .custom:
            AddEditHabitView(template: nil)
                .environment(\.managedObjectContext, viewContext)
        case .template(let selectedTemplate):
            AddEditHabitView(template: selectedTemplate)
                .environment(\.managedObjectContext, viewContext)
        }
    }

    /// Provides the content view for the Edit sheet based on the Habit item.
    @ViewBuilder private func editSheetContent(for habit: Habit) -> some View {
         AddEditHabitView(habitToEdit: habit)
             .environment(\.managedObjectContext, viewContext)
    }

    // MARK: - Helper Functions for Event Handling

    /// Handles the logic when a level up occurs.
    private func handleLevelUp(_ level: Int) {
        self.levelUpInfo = level
        withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) { // Example animation
            self.showLevelUpOverlay = true
        }
        // Hide overlay after delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                self.showLevelUpOverlay = false
            }
        }
    }

    /// Handles the logic when an artifact earned notification is received.
    private func handleArtifactEarned(_ notification: Notification) {
        guard let name = notification.userInfo?["artifactName"] as? String else { return }
        self.earnedArtifactName = name
        withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) { // Example animation
            self.showArtifactOverlay = true
        }
        // Hide overlay after delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                self.showArtifactOverlay = false
            }
        }
    }
}

// MARK: - Previews (Ensure mocks/placeholders are available if needed)
struct DashboardView_Previews: PreviewProvider {
    // Mock necessary components if global ones aren't suitable/available
    struct PreviewThemeColors { static let background = Color.black; static let primaryAccent = Color.cyan }
    static let ThemeColors = PreviewThemeColors.self
    struct StatusSectionView: View { var viewModel: DashboardViewModel; var body: some View { Text("Status Placeholder").foregroundColor(.white) } }
    struct ActiveQuestsSectionView: View { var viewModel: DashboardViewModel; var onAddTapped: () -> Void; @Binding var habitToEdit: Habit?; var body: some View { Text("Quests Placeholder").foregroundColor(.white) } }
    struct LevelUpView: View { var level: Int; var body: some View { Text("Level Up! \(level)").foregroundColor(.white) } }
    struct ArtifactEarnedView: View { var artifactName: String; var body: some View { Text("Got \(artifactName)").foregroundColor(.white) } }
    struct StatsView: View { var body: some View { Text("Stats View Placeholder").foregroundColor(.white) } }
    // Removed duplicate declarations that conflict with the real implementations
    // Mock DashboardViewModel if needed
    class MockDashboardViewModel: DashboardViewModel { }


    static var previews: some View {
        DashboardView()
            // Use preview context
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
            .preferredColorScheme(.dark)
    }
}
