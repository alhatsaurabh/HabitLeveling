// MARK: - File: AddEditHabitView.swift
// Purpose: View for adding or editing habits.
// Update: Cleaned to rely on external AddEditHabitSubviews.swift and ViewModifiers.swift.
//         Removed .onAppear logic for template configuration (handled by ViewModel init).

import SwiftUI
import CoreData

struct AddEditHabitView: View {
    // MARK: - Properties
    @StateObject private var viewModel: AddEditHabitViewModel
    @Environment(\.dismiss) var dismiss
    @Environment(\.managedObjectContext) private var viewContext

    // Assume ThemeColors exists globally
    let themeAccentColor = ThemeColors.primaryAccent

    // Local state for UI elements tied to this view instance
    @State private var notificationsEnabled: Bool = false
    @State private var selectedTime: Date = Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: Date())!

    // Focus state management
    @FocusState private var focusedField: Field?
    enum Field: Hashable { case title, description, cue, xp }

    // Store the template passed during init (Used for Navigation Title)
    private let initialTemplate: HabitTemplate?

    // MARK: - Initializer
    init(habitToEdit: Habit? = nil, template: HabitTemplate? = nil) {
        self.initialTemplate = template
        // Initialize ViewModel - it handles habitToEdit or template internally
        _viewModel = StateObject(wrappedValue: AddEditHabitViewModel(habit: habitToEdit, template: template))
         // print("AddEditHabitView init - Template provided: \(template?.name ?? "nil")") // Keep for debugging if needed
    }

    // MARK: - Body
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // --- Use Subviews defined in AddEditHabitSubviews.swift ---
                    // Ensure these subviews exist in that separate file
                    QuestTitleInput(name: $viewModel.name, focusedField: $focusedField)
                    DescriptionInput(description: $viewModel.description, focusedField: $focusedField)
                    StatCategoryPicker(selection: $viewModel.statCategory)
                    XPInput(xpValue: $viewModel.xpValue, focusedField: $focusedField)
                    FrequencyPicker(selection: $viewModel.frequency, frequencies: viewModel.frequencies)
                    // CueInput(cue: $viewModel.cue, focusedField: $focusedField) // Uncomment if CueInput is defined
                    ReminderSection(
                        notificationsEnabled: $notificationsEnabled,
                        selectedTime: $selectedTime,
                        notificationTime: $viewModel.notificationTime
                    )
                    MakeItEasyToggle(isTwoMinuteVersion: $viewModel.isTwoMinuteVersion)
                }
                .padding()
            }
            .background(ThemeColors.background.ignoresSafeArea())
            .navigationTitle(viewModel.habitToEdit == nil ? (initialTemplate == nil ? "Add Custom Quest" : "Add Template Quest") : "Edit Quest")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                 // Top trailing dismiss button
                 ToolbarItem(placement: .navigationBarTrailing) {
                     Button { dismiss() } label: { Image(systemName: "xmark").font(.headline) }
                     .tint(ThemeColors.secondaryText)
                 }
                 // Bottom bar with Cancel and Save/Update buttons
                 ToolbarItemGroup(placement: .bottomBar) {
                     Button("Cancel") { dismiss() }
                     .buttonStyle(.bordered).tint(ThemeColors.secondaryText)
                     Spacer()
                     Button(viewModel.habitToEdit == nil ? "Create Quest" : "Update Quest") {
                         if viewModel.saveHabit() { dismiss() } else { print("AddEditHabitView: Validation failed.") /* TODO: Show alert? */ }
                     }
                     .buttonStyle(GradientButtonStyle()) // Assumes GradientButtonStyle exists globally
                     .disabled(viewModel.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                 }
                  // Keyboard toolbar
                  ToolbarItemGroup(placement: .keyboard) {
                     Spacer()
                     Button("Done") {
                         focusedField = nil // Dismiss keyboard
                     }
                     .tint(themeAccentColor) // Use theme color for Done button
                 }
             }
            .onAppear {
                syncReminderState() // Sync reminder UI state
                // ViewModel handles template logic in its init.
            }
            .preferredColorScheme(.dark)
        } // End NavigationView
    }

    // MARK: - Helper Functions
    private func syncReminderState() {
        if let time = viewModel.notificationTime {
            notificationsEnabled = true
            selectedTime = time
        } else {
            notificationsEnabled = false
        }
    }
}

// --- REMOVED Embedded Subview Definitions ---
// --- REMOVED Embedded Custom View Modifier Definitions ---

// MARK: - Previews
struct AddEditHabitView_Previews_Separate: PreviewProvider {
    // Define temporary mocks for Preview if needed
    struct PreviewThemeColors { static let background = Color.black; static let primaryText = Color.white; static let secondaryText = Color.gray; static let tertiaryText = Color.gray; static let primaryAccent = Color.blue; static let warning = Color.orange; static let success = Color.green; static let panelBackground = Color.gray.opacity(0.15) }
    static let ThemeColors = PreviewThemeColors.self
    struct GradientButtonStyle: ButtonStyle { func makeBody(configuration: Configuration) -> some View { configuration.label.padding(.vertical, 10).padding(.horizontal, 20).background(LinearGradient(colors: [.blue, .purple], startPoint: .leading, endPoint: .trailing)).foregroundColor(.white).cornerRadius(8).opacity(configuration.isPressed ? 0.8 : 1.0).scaleEffect(configuration.isPressed ? 0.98 : 1.0) } }
    enum StatCategory: String, CaseIterable, Identifiable { case body = "Body"; case mind = "Mind"; var id: String { rawValue } } // Mock enum
    struct HabitTemplate: Identifiable { let id = UUID(); var name: String; var description: String?; var category: StatCategory; var xpValue: Int64; var frequency: String } // Mock struct

    // Mock Subviews/Modifiers for Preview (if not globally accessible in preview context)
    // You might need to copy the definitions from AddEditHabitSubviews.swift and ViewModifiers.swift
    // into this preview provider struct if Xcode previews complain.
    // For example:
    // struct QuestTitleInput: View { @Binding var name: String; var focusedField: FocusState<AddEditHabitView.Field?>.Binding; let themeAccentColor = Color.blue; var body: some View { TextField("Title", text: $name) } }
    // struct InputLabelStyle: ViewModifier { func body(content: Content) -> some View { content.font(.caption) } }
    // extension View { func inputLabelStyle() -> some View { modifier(InputLabelStyle()) } func inputFieldStyle(isFocused: Bool, accentColor: Color) -> some View { self } }


    static var previews: some View {
        AddEditHabitView()
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext) // Assume PersistenceController exists
            .preferredColorScheme(.dark)
            .previewDisplayName("Add New (Separate Files)")
    }
}

// MARK: - Assumptions for Compilation
// This View now critically depends on:
// 1. `AddEditHabitSubviews.swift` being included in the target and defining all necessary subviews (QuestTitleInput, etc.).
// 2. `ViewModifiers.swift` being included in the target and defining InputLabelStyle, InputFieldStyle, and the View extensions.
// 3. Global availability of: ThemeColors, GradientButtonStyle, PersistenceController, AddEditHabitViewModel, StatCategory enum, HabitTemplate struct.
// 4. Correct CoreData entity definitions (Habit, etc.).
