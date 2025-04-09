// --- Dashboard ViewModel (DashboardViewModel.swift) ---
class DashboardViewModel: ObservableObject {
    // Placeholder for user profile data (we'll fetch this properly later)
    @Published var userLevel: Int = 1
    @Published var userXP: Int = 0
    @Published var xpGoal: Int = 100 // Example goal for level 1
    @Published var essenceCoreState: String = "Dim" // Example state
    @Published var fragmentCount: Int = 0 // Display collected fragments

    // TODO: Fetch UserProfile from Core Data
    // TODO: Fetch Habits due today

    init() {
        // Placeholder: Initialize or fetch user profile data here
        fetchUserProfile()
    }

     func fetchUserProfile() {
        // In a real app, fetch the UserProfile entity from Core Data
        // For now, using placeholder values or preview data if available
        let context = PersistenceController.preview.container.viewContext // Use preview context for example
        let fetchRequest: NSFetchRequest<UserProfile> = UserProfile.fetchRequest()
        fetchRequest.fetchLimit = 1 // Expecting only one profile

        do {
            if let profile = try context.fetch(fetchRequest).first {
                self.userLevel = Int(profile.level)
                self.userXP = Int(profile.xp)
                // Calculate xpGoal based on level (example: level * 100)
                self.xpGoal = Int(profile.level) * 100
                self.essenceCoreState = profile.essenceCoreState ?? "Dim"
                self.fragmentCount = Int(profile.fragmentCount)
            } else {
                // Handle case where no profile exists (e.g., create one)
                print("No UserProfile found, using defaults.")
            }
        } catch {
            print("Error fetching UserProfile: \(error)")
            // Use default values if fetch fails
        }
    }


    // Function to be called when a habit is completed
    func completeHabit(habit: Habit) {
        print("Completing habit: \(habit.name ?? "Unknown")")
        // 1. Call HabitTrackingManager to update streak, log completion
        // 2. Call LevelingManager to add XP, check for level up
        // 3. Call EssenceCoreManager to potentially update core state
        // 4. Update published properties if needed (XP, Level, Core State, Fragments)

        // --- Placeholder Logic ---
        let xpGained = Int(habit.xpValue)
        let fragmentsGained = 1 // Simple gain for now

        self.userXP += xpGained
        self.fragmentCount += fragmentsGained
        print("Gained \(xpGained) XP. Total XP: \(self.userXP)")
        print("Gained \(fragmentsGained) Fragment. Total Fragments: \(self.fragmentCount)")


        // Basic Level Up Check (Placeholder)
        if self.userXP >= self.xpGoal {
            self.userLevel += 1
            self.userXP -= self.xpGoal // Reset XP carrying over excess
             // Recalculate goal for new level
            self.xpGoal = self.userLevel * 100
            print("LEVEL UP! Reached Level \(self.userLevel)")
            // TODO: Trigger level up animation/feedback
            // TODO: Involve SanctumManager for potential unlocks
        }
        // Update Core State (Placeholder)
        self.essenceCoreState = "Bright" // Assume completion makes it bright for now

        // TODO: Save UserProfile changes to Core Data
        // --- End Placeholder Logic ---
    }
}

// MARK: - Views (Place these in the 'Views' Group/Folder)

// --- Dashboard View (DashboardView.swift) ---
struct DashboardView: View {
    // Use @StateObject for the ViewModel owned by this view
    @StateObject private var viewModel = DashboardViewModel()
    // Access the managed object context
    @Environment(\.managedObjectContext) private var viewContext

    // Fetch request for habits (can be filtered later for 'today')
    // TODO: Add predicate to fetch only habits due today
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Habit.creationDate, ascending: true)],
        animation: .default)
    private var habits: FetchedResults<Habit>

    var body: some View {
        NavigationView { // Embed in NavigationView for a title bar
            List {
                // --- User Stats Section ---
                Section("Status") {
                    VStack(alignment: .leading) {
                        Text("Level: \(viewModel.userLevel)")
                            .font(.title2)
                            .fontWeight(.bold)

                        ProgressView("XP: \(viewModel.userXP) / \(viewModel.xpGoal)", value: Double(viewModel.userXP), total: Double(viewModel.xpGoal))
                            .tint(.cyan) // Match accent color

                        Text("Fragments: \(viewModel.fragmentCount)")
                             .font(.footnote)
                             .foregroundColor(.gray)

                        // --- Essence Core Placeholder ---
                         HStack {
                             Spacer()
                             EssenceCoreView(state: viewModel.essenceCoreState)
                                 .padding(.vertical)
                             Spacer()
                         }
                    }
                }
                .listRowBackground(Color.black.opacity(0.3)) // Themed row background


                // --- Today's Habits Section ---
                // TODO: Filter this list properly for habits due today
                Section("Daily Quests") {
                    if habits.isEmpty {
                         Text("No habits added yet. Go to the Habits tab!")
                             .foregroundColor(.gray)
                    } else {
                        // Display habits fetched
                        ForEach(habits) { habit in
                            HabitRowView(habit: habit) { completedHabit in
                                // Action closure called when checkmark is tapped
                                viewModel.completeHabit(habit: completedHabit)
                            }
                        }
                    }
                }
                 .listRowBackground(Color.black.opacity(0.3)) // Themed row background

            }
            .navigationTitle("Dashboard")
             // Apply list style for better appearance
            .listStyle(InsetGroupedListStyle())
            .onAppear {
                // Fetch latest user profile data when view appears
                 viewModel.fetchUserProfile()
            }
        }
    }
}
