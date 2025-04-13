// MARK: - File: HabitListView.swift
// Purpose: Displays the list of user's habits.
// Update: Corrected completeHabit call (removed context argument).
// Update 2: Added swipe-to-dismiss and close button for better navigation from Dashboard.

import SwiftUI
import CoreData

struct HabitListView: View {
    // MARK: - Properties

    // Access Core Data managed object context
    @Environment(\.managedObjectContext) private var viewContext
    
    // Environment to dismiss the view when opened as a sheet
    @Environment(\.dismiss) private var dismiss

    // Fetch Request to get Habit entities
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Habit.creationDate, ascending: true)],
        animation: .default
    )
    private var habits: FetchedResults<Habit>

    // State variables
    @State private var showingAddHabitSheet = false
    @State private var showingTemplatePicker = false
    @State private var showingAddHabitOptions = false
    @State private var isMultiSelectMode = false
    @State private var selectedHabits = Set<UUID>()
    @State private var selectedCategory: StatCategory?
    @State private var selectedTemplate: HabitTemplate? = nil
    
    // Gesture state
    @State private var offset: CGFloat = 0
    @State private var isDragging = false

    // MARK: - Body

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Category Filter ScrollView
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: 12) {
                        Button(action: { selectedCategory = nil }) {
                            Text("All")
                                .font(.subheadline)
                                .fontWeight(selectedCategory == nil ? .semibold : .regular)
                                .foregroundColor(selectedCategory == nil ? .white : ThemeColors.secondaryText)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(
                                    Capsule()
                                        .fill(selectedCategory == nil ? ThemeColors.primaryAccent : Color.clear)
                                )
                                .overlay(
                                    Capsule()
                                        .stroke(selectedCategory == nil ? Color.clear : ThemeColors.secondaryText.opacity(0.3), lineWidth: 1)
                                )
                        }
                        .buttonStyle(.plain)
                        
                        ForEach(StatCategory.allCases) { category in
                            Button(action: { 
                                selectedCategory = selectedCategory == category ? nil : category 
                            }) {
                                Text(category.rawValue)
                                    .font(.subheadline)
                                    .fontWeight(selectedCategory == category ? .semibold : .regular)
                                    .foregroundColor(selectedCategory == category ? .white : ThemeColors.secondaryText)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(
                                        Capsule()
                                            .fill(selectedCategory == category ? ThemeColors.primaryAccent : Color.clear)
                                    )
                                    .overlay(
                                        Capsule()
                                            .stroke(selectedCategory == category ? Color.clear : ThemeColors.secondaryText.opacity(0.3), lineWidth: 1)
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                    .frame(minWidth: UIScreen.main.bounds.width * 2) // Force content to be wider than screen
                }
                .background(ThemeColors.panelBackground.opacity(0.3))
                
                // Habits List
                List {
                    ForEach(filteredHabits) { habit in
                        HabitRowView(habit: habit, onComplete: { completedHabit in
                            HabitTrackingManager.shared.completeHabit(completedHabit)
                        }, isMultiSelectMode: isMultiSelectMode)
                        .contentShape(Rectangle()) // Make entire row tappable
                        .onTapGesture {
                            if isMultiSelectMode, let id = habit.id {
                                if selectedHabits.contains(id) {
                                    selectedHabits.remove(id)
                                } else {
                                    selectedHabits.insert(id)
                                }
                            }
                        }
                        .overlay(alignment: .trailing) {
                            if isMultiSelectMode, let id = habit.id {
                                Image(systemName: selectedHabits.contains(id) ? "checkmark.circle.fill" : "circle")
                                    .foregroundColor(selectedHabits.contains(id) ? ThemeColors.primaryAccent : ThemeColors.secondaryText)
                                    .padding(.trailing, 16)
                            }
                        }
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                    }
                    .onDelete(perform: deleteHabits)
                }
                .listStyle(.plain)
                .background(ThemeColors.background)
                
                // Confirmation buttons for multi-select mode
                if isMultiSelectMode {
                    HStack {
                        Button(action: {
                            isMultiSelectMode = false
                            selectedHabits.removeAll()
                        }) {
                            Text("Cancel")
                                .foregroundColor(ThemeColors.secondaryText)
                                .padding(.vertical, 12)
                                .frame(maxWidth: .infinity)
                                .background(ThemeColors.panelBackground.opacity(0.5))
                                .cornerRadius(8)
                        }
                        
                        Button(action: {
                            deleteSelectedHabits()
                            isMultiSelectMode = false
                        }) {
                            Text("Delete \(selectedHabits.count)")
                                .foregroundColor(.white)
                                .padding(.vertical, 12)
                                .frame(maxWidth: .infinity)
                                .background(Color.red.opacity(0.8))
                                .cornerRadius(8)
                        }
                        .disabled(selectedHabits.isEmpty)
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                    .background(ThemeColors.background)
                    .transition(.move(edge: .bottom))
                }
            }
            .navigationTitle("Habits")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(ThemeColors.secondaryText)
                            .font(.headline)
                    }
                }
                
                if !isMultiSelectMode && !habits.isEmpty {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button {
                            withAnimation {
                                isMultiSelectMode = true
                            }
                        } label: {
                            Image(systemName: "checkmark.circle")
                                .foregroundColor(ThemeColors.secondaryText)
                        }
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    if !isMultiSelectMode {
                        Button {
                            showingAddHabitOptions = true
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .font(.title2)
                                .foregroundColor(ThemeColors.primaryAccent)
                        }
                    } else {
                        Button("Select All") {
                            selectedHabits = Set(filteredHabits.compactMap { $0.id })
                        }
                    }
                }
            }
            .confirmationDialog("Add New Quest", isPresented: $showingAddHabitOptions, titleVisibility: .visible) {
                Button("Choose from Template") { 
                    showingTemplatePicker = true
                }
                Button("Create Custom Habit") { 
                    showingAddHabitSheet = true
                }
                Button("Cancel", role: .cancel) { }
            } message: { 
                Text("Select a method to add a new quest.")
            }
            .sheet(isPresented: $showingAddHabitSheet, onDismiss: {
                // Refresh data when sheet is dismissed
            }) {
                AddEditHabitView(habitToEdit: nil, template: selectedTemplate)
                    .environment(\.managedObjectContext, viewContext)
            }
            .sheet(isPresented: $showingTemplatePicker) {
                HabitTemplatePickerView { template in
                    // Save the selected template
                    selectedTemplate = template
                    showingTemplatePicker = false
                    showingAddHabitSheet = true
                }
                .environment(\.managedObjectContext, viewContext)
            }
            .overlay {
                if habits.isEmpty {
                    noHabitsView
                }
            }
        }
        .tint(ThemeColors.primaryAccent)
        .navigationViewStyle(.stack)
        .highPriorityGesture(
            DragGesture()
                .onChanged { gesture in
                    if gesture.startLocation.x < 50 && gesture.translation.width > 0 && !isDragging {
                        isDragging = true
                    }
                    
                    if isDragging {
                        offset = max(0, gesture.translation.width)
                    }
                }
                .onEnded { gesture in
                    if isDragging {
                        if gesture.predictedEndTranslation.width > 100 {
                            dismiss()
                        } else {
                            withAnimation(.spring()) {
                                offset = 0
                            }
                        }
                        isDragging = false
                    }
                }
        )
        .offset(x: offset)
        .background(ThemeColors.background.ignoresSafeArea())
        .overlay(
            HStack {
                Spacer()
                Text("Swipe to return")
                    .font(.caption)
                    .foregroundColor(ThemeColors.secondaryText.opacity(0.7))
                    .padding(.vertical, 4)
                    .padding(.horizontal, 8)
                    .background(ThemeColors.panelBackground.opacity(0.5))
                    .clipShape(Capsule())
                    .padding(.bottom, 8)
                    .opacity(isDragging ? min(1.0, offset / 50.0) : 0)
                    .animation(.easeInOut, value: isDragging)
            }
            .padding(.horizontal)
            , alignment: .bottom
        )
        .onAppear {
            // Refresh data when view appears
        }
    }

    // MARK: - Computed Properties & Views
    
    private var noHabitsView: some View {
        VStack(spacing: 12) {
            Image(systemName: "scroll")
                .font(.system(size: 60))
                .foregroundColor(ThemeColors.secondaryText.opacity(0.7))
            Text("No habits yet")
                .font(.headline)
                .foregroundColor(ThemeColors.secondaryText)
            Text("Tap '+' to add your first quest")
                .font(.subheadline)
                .foregroundColor(ThemeColors.secondaryText.opacity(0.8))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
    }
    
    private var filteredHabits: [Habit] {
        guard let selectedCategory = selectedCategory else { return Array(habits) }
        return habits.filter { habit in
            guard let habitCategory = habit.statCategory else { return false }
            return habitCategory == selectedCategory.rawValue
        }
    }

    // MARK: - Functions

    private func deleteHabits(offsets: IndexSet) {
        withAnimation {
            offsets.map { filteredHabits[$0] }.forEach(viewContext.delete)
            PersistenceController.shared.saveContext()
        }
    }
    
    private func deleteSelectedHabits() {
        withAnimation {
            // Delete all habits that are in the selectedHabits set
            for habit in habits {
                if let id = habit.id, selectedHabits.contains(id) {
                    viewContext.delete(habit)
                }
            }
            PersistenceController.shared.saveContext()
            selectedHabits.removeAll()
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
