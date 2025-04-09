// MARK: - ViewModels (Create a 'ViewModels' Group/Folder in Xcode)

// --- Habit List ViewModel (HabitListViewModel.swift) ---
// Manages the data and logic for the list of all habits.
import Combine // Needed for ObservableObject

class HabitListViewModel: ObservableObject {
    private let viewContext = PersistenceController.shared.container.viewContext

    // Function to delete habits
    func deleteHabits(offsets: IndexSet, habits: FetchedResults<Habit>) {
        withAnimation {
            offsets.map { habits[$0] }.forEach(viewContext.delete)
            PersistenceController.shared.saveContext() // Save changes
        }
    }
}

// --- Habit List View (HabitListView.swift) ---
struct HabitListView: View {
    @StateObject private var viewModel = HabitListViewModel()
    @Environment(\.managedObjectContext) private var viewContext

    // State variable to control showing the Add/Edit sheet
    @State private var showingAddHabitSheet = false
    @State private var habitToEdit: Habit? = nil // Track which habit to edit

    // Fetch all habits, sorted by creation date
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Habit.creationDate, ascending: true)],
        animation: .default)
    private var habits: FetchedResults<Habit>

    var body: some View {
        NavigationView {
            List {
                ForEach(habits) { habit in
                    // Basic display of habit details
                    VStack(alignment: .leading) {
                        Text(habit.name ?? "Unnamed Habit").font(.headline)
                        Text("Category: \(habit.category ?? "-") | XP: \(habit.xpValue) | Streak: \(habit.streak)")
                            .font(.caption)
                            .foregroundColor(.gray)
                        if let cue = habit.cue, !cue.isEmpty {
                             Text("Cue: \(cue)")
                                 .font(.caption2)
                                 .foregroundColor(.orange) // Example highlight
                        }
                         if habit.isTwoMinuteVersion {
                             Text("(2-Min Rule Version)")
                                 .font(.caption2)
                                 .foregroundColor(.yellow) // Example highlight
                        }

                    }
                     // Allow tapping row to edit
                    .contentShape(Rectangle()) // Make whole row tappable
                    .onTapGesture {
                        self.habitToEdit = habit // Set the habit to edit
                        self.showingAddHabitSheet = true // Show the sheet
                    }

                }
                .onDelete(perform: deleteItems) // Enable swipe to delete
                 .listRowBackground(Color.black.opacity(0.3)) // Themed row background
            }
            .navigationTitle("All Habits")
            .toolbar {
                // Edit button for list editing mode (optional)
                ToolbarItem(placement: .navigationBarLeading) {
                    EditButton()
                }
                // Add button to show the sheet
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        self.habitToEdit = nil // Ensure we are adding, not editing
                        self.showingAddHabitSheet = true
                    } label: {
                        Label("Add Habit", systemImage: "plus")
                    }
                }
            }
            // Sheet presentation for adding/editing habits
            .sheet(isPresented: $showingAddHabitSheet) {
                // Pass the habit to edit (if any) to the AddEditHabitView
                AddEditHabitView(habitToEdit: self.habitToEdit)
                    // Inject the context into the sheet's environment
                    .environment(\.managedObjectContext, self.viewContext)
            }
             .listStyle(InsetGroupedListStyle())
        }
    }

    // Function called by onDelete modifier
    private func deleteItems(offsets: IndexSet) {
        viewModel.deleteHabits(offsets: offsets, habits: habits)
    }
}
