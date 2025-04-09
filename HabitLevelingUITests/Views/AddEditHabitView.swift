/ --- Add/Edit Habit ViewModel (AddEditHabitViewModel.swift) ---
// Manages the data and logic for the habit creation/editing form.
class AddEditHabitViewModel: ObservableObject {
    // Properties bound to the form fields
    @Published var name: String = ""
    @Published var description: String = ""
    @Published var frequency: String = "Daily" // Default value
    @Published var category: String = "Mind"    // Default value
    @Published var xpValue: Int = 10             // Default value
    @Published var cue: String = ""
    @Published var isTwoMinuteVersion: Bool = false

    let frequencies = ["Daily", "Weekly"] // Options for frequency picker
    let categories = ["Mind", "Health", "Discipline", "Skill", "Creative", "Other"] // Example categories

    private var viewContext = PersistenceController.shared.container.viewContext
    private var habitToEdit: Habit? // Holds the habit if we are editing

    // Initialize for editing an existing habit
    init(habit: Habit? = nil) {
        if let habit = habit {
            self.habitToEdit = habit
            // Populate fields with existing habit data
            self.name = habit.name ?? ""
            self.description = habit.habitDescription ?? ""
            self.frequency = habit.frequency ?? "Daily"
            self.category = habit.category ?? "Mind"
            self.xpValue = Int(habit.xpValue)
            self.cue = habit.cue ?? ""
            self.isTwoMinuteVersion = habit.isTwoMinuteVersion
        }
    }

    // Function to save the habit (either new or edited)
    func saveHabit() -> Bool {
        // Basic validation
        guard !name.isEmpty else {
            print("Habit name cannot be empty.")
            return false // Indicate failure
        }

        let habit: Habit
        if let habitToEdit = habitToEdit {
            // Editing existing habit
            habit = habitToEdit
        } else {
            // Creating new habit
            habit = Habit(context: viewContext)
            habit.id = UUID() // Assign unique ID only for new habits
            habit.creationDate = Date()
            habit.streak = 0 // Start streak at 0
        }

        // Update habit properties from form fields
        habit.name = name
        habit.habitDescription = description.isEmpty ? nil : description // Store nil if empty
        habit.frequency = frequency
        habit.category = category
        habit.xpValue = Int64(xpValue)
        habit.cue = cue.isEmpty ? nil : cue
        habit.isTwoMinuteVersion = isTwoMinuteVersion
        // lastCompletedDate is handled by completion logic, not here

        PersistenceController.shared.saveContext() // Save changes
        return true // Indicate success
    }
}



// --- Add/Edit Habit View (AddEditHabitView.swift) ---
struct AddEditHabitView: View {
    // Use StateObject because this view owns its ViewModel instance
    @StateObject private var viewModel: AddEditHabitViewModel

    // Environment variable to dismiss the sheet
    @Environment(\.dismiss) var dismiss
    @Environment(\.managedObjectContext) private var viewContext // Needed if VM doesn't hold it

    // Initialize with an optional habit to edit
    init(habitToEdit: Habit? = nil) {
        _viewModel = StateObject(wrappedValue: AddEditHabitViewModel(habit: habitToEdit))
    }

    var body: some View {
        NavigationView {
            Form {
                Section("Habit Details") {
                    TextField("Habit Name (e.g., Read for 10 mins)", text: $viewModel.name)
                    TextField("Description (Optional)", text: $viewModel.description)
                    TextField("Cue (Optional: What triggers this?)", text: $viewModel.cue) // Atomic Habits Cue
                    Picker("Frequency", selection: $viewModel.frequency) {
                        ForEach(viewModel.frequencies, id: \.self) { Text($0) }
                    }
                    Picker("Category", selection: $viewModel.category) {
                        ForEach(viewModel.categories, id: \.self) { Text($0) }
                    }
                    Stepper("XP Value: \(viewModel.xpValue)", value: $viewModel.xpValue, in: 5...100, step: 5) // Allow setting XP
                }
                 .listRowBackground(Color.gray.opacity(0.2)) // Themed row background

                 Section("Make it Easy (Atomic Habits)") {
                     Toggle("Start with 2-Minute Version?", isOn: $viewModel.isTwoMinuteVersion)
                 }
                 .listRowBackground(Color.gray.opacity(0.2)) // Themed row background

            }
            .navigationTitle(viewModel.habitToEdit == nil ? "Add New Habit" : "Edit Habit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss() // Dismiss the sheet
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        if viewModel.saveHabit() {
                            dismiss() // Dismiss the sheet on successful save
                        } else {
                            // Optionally show an alert if validation fails
                            print("Validation failed.")
                        }
                    }
                    // Disable save button if name is empty (basic validation)
                    .disabled(viewModel.name.isEmpty)
                }
            }
        }
         .preferredColorScheme(.dark) // Ensure sheet is also dark
         .tint(.cyan) // Match accent color
    }
}
