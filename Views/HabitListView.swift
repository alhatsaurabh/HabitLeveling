// MARK: - File: HabitListView.swift
// Purpose: Displays the list of user's habits.
// Update: Corrected completeHabit call (removed context argument).

import SwiftUI
import CoreData

struct HabitListView: View {
    // MARK: - Properties

    // Access Core Data managed object context
    @Environment(\.managedObjectContext) private var viewContext

    // Fetch Request to get Habit entities, sorted by creation date
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Habit.creationDate, ascending: true)],
        animation: .default // Animate changes to the list
    )
    private var habits: FetchedResults<Habit>

    // State variable to control the presentation of the Add/Edit sheet
    @State private var showingAddHabitSheet = false

    // State variable to control the selected category for filtering
    @State private var selectedCategory: StatCategory?

    // MARK: - Body

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Category Filter
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(StatCategory.allCases) { category in
                            CategoryFilterButton(
                                category: category,
                                isSelected: selectedCategory == category,
                                action: { selectedCategory = selectedCategory == category ? nil : category }
                            )
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                }
                .background(ThemeColors.panelBackground.opacity(0.3))
                
                // Habits List
                List {
                    ForEach(filteredHabits) { habit in
                        HabitRowView(habit: habit, onComplete: { completedHabit in
                            print("Completing habit: \(completedHabit.name ?? "Unknown") from HabitListView")
                            HabitTrackingManager.shared.completeHabit(completedHabit)
                        })
                    }
                    .onDelete(perform: deleteHabits)
                }
                .listStyle(.plain)
            }
            .navigationTitle("Habits")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingAddHabitSheet = true
                    } label: {
                        Label("Add Habit", systemImage: "plus")
                    }
                    .tint(ThemeColors.primaryAccent)
                }
            }
            .sheet(isPresented: $showingAddHabitSheet) {
                AddEditHabitView(habitToEdit: nil)
            }
            .overlay {
                if habits.isEmpty {
                    Text("No habits yet. Tap '+' to add your first quest!")
                        .font(.callout)
                        .foregroundColor(ThemeColors.secondaryText)
                        .padding()
                        .multilineTextAlignment(.center)
                }
            }
        }
        .navigationViewStyle(.stack)
    }

    // MARK: - Computed Properties
    private var filteredHabits: [Habit] {
        guard let selectedCategory = selectedCategory else { return Array(habits) }
        return habits.filter { habit in
            guard let habitCategory = habit.statCategory else { return false }
            return habitCategory == selectedCategory.rawValue
        }
    }

    // MARK: - Functions

    // Function to handle deleting habits from the list
    private func deleteHabits(offsets: IndexSet) {
        withAnimation {
            // Map the offsets to the actual Habit objects
            offsets.map { habits[$0] }.forEach(viewContext.delete)

            // Save the context after deletion
            PersistenceController.shared.saveContext()
        }
    }
}

// MARK: - Category Filter Button
struct CategoryFilterButton: View {
    let category: StatCategory
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(category.rawValue)
                .font(.subheadline)
                .fontWeight(isSelected ? .semibold : .regular)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(isSelected ? ThemeColors.primaryAccent : ThemeColors.panelBackground)
                )
                .foregroundColor(isSelected ? .white : ThemeColors.secondaryText)
        }
    }
}

// MARK: - Previews
struct HabitListView_Previews: PreviewProvider {
    static var previews: some View {
        HabitListView()
            // Provide the preview context for Core Data
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
            .preferredColorScheme(.dark)
            // Ensure ThemeColors is available for preview
            // Ensure HabitRowView is available for preview
            // Ensure HabitTrackingManager is available or mock its function for preview if needed
    }
}

// MARK: - Assumptions for Compilation
// - HabitRowView struct exists and takes 'habit: Habit' and 'onComplete: (Habit) -> Void' parameters.
// - PersistenceController exists with 'preview' and 'shared' instances.
// - AddEditHabitView struct exists.
// - ThemeColors struct exists.
// - Habit Core Data entity exists.
// - HabitTrackingManager class exists with a shared instance and a 'completeHabit(_:)' method (that does NOT take a context argument).
