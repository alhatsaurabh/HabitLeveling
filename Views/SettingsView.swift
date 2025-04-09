
import SwiftUI
import CoreData // Needed for FetchRequest

struct SettingsView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @State private var showingResetConfirm = false
    @State private var showingClearConfirm = false // State for clear confirmation
    @State private var clearResultMessage: String? = nil // To show success/failure message
    let themeAccentColor = ThemeColors.primaryAccent

    var body: some View {
        NavigationView {
            VStack {
                List {
                    Section("Debug Tools") {
                        // Reset Button
                        Button("Reset All Progress", role: .destructive) {
                            showingResetConfirm = true
                        }
                        .tint(.red)

                        // Add Crystals Button
                        Button("Add 50 Mana Crystals") {
                            ResetManager.shared.addManaCrystals(amount: 50, context: viewContext)
                            clearResultMessage = "Added 50 Mana Crystals." // Provide feedback
                        }
                        .tint(ThemeColors.secondaryAccent)

                        // --- NEW Button ---
                        Button("Force Clear First Analyzed Gate") {
                            // Show confirmation before clearing
                            showingClearConfirm = true
                        }
                        .tint(ThemeColors.warning) // Use warning color
                        // --- END NEW Button ---
                    }
                     .modifier(SoloPanelModifier())

                    // Display result message from debug actions
                    if let message = clearResultMessage {
                        Section {
                            Text(message)
                                .font(.footnote)
                                .foregroundColor(ThemeColors.secondaryText)
                        }
                        .modifier(SoloPanelModifier())
                        .onAppear {
                            // Clear message after a delay
                            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                                clearResultMessage = nil
                            }
                        }
                    }


                    Section("Coming Soon") { /* ... */ Text("App Version: 0.1.0").foregroundColor(ThemeColors.secondaryText); Text("More settings...").foregroundColor(ThemeColors.secondaryText) }
                     .modifier(SoloPanelModifier())
                }
                .listStyle(PlainListStyle())

                Spacer()
            }
            .background(ThemeColors.background.ignoresSafeArea())
            .navigationTitle("Settings")
            .preferredColorScheme(.dark)
            // Reset Confirmation Alert
            .alert("Confirm Reset", isPresented: $showingResetConfirm) { /* ... Reset Alert Buttons ... */
                Button("Cancel", role: .cancel) { }
                Button("Reset Data", role: .destructive) { ResetManager.shared.performReset(context: viewContext); clearResultMessage = "Reset Complete." }
            } message: { Text("Are you sure you want to reset all progress? This includes Level, XP, Mana Crystals, Completions, Streaks, and Gates. This action cannot be undone.") }
            // --- NEW Clear Confirmation Alert ---
            .alert("Confirm Force Clear", isPresented: $showingClearConfirm) {
                Button("Cancel", role: .cancel) { }
                Button("Force Clear", role: .destructive) {
                    forceClearFirstAnalyzedGate() // Call helper function
                }
            } message: {
                Text("Are you sure you want to force clear the first 'Analyzed' gate? This will bypass its Clear Condition.")
            }
            // --- END NEW Alert ---
        }
        .tint(themeAccentColor)
    }

    // --- NEW Helper function for Force Clear action ---
    private func forceClearFirstAnalyzedGate() {
        clearResultMessage = nil // Clear previous message
        let fetchRequest: NSFetchRequest<GateStatus> = GateStatus.fetchRequest()
        // Find gates that are specifically "Analyzed"
        fetchRequest.predicate = NSPredicate(format: "status == %@", "Analyzed")
        // Optional: sort by date to get the 'first' one consistently
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \GateStatus.statusChangeDate, ascending: true)]
        fetchRequest.fetchLimit = 1 // Only need one

        do {
            let results = try viewContext.fetch(fetchRequest)
            if let gateToClear = results.first {
                // Fetch user profile to pass to clearGate
                let profileFetchRequest: NSFetchRequest<UserProfile> = UserProfile.fetchRequest()
                profileFetchRequest.fetchLimit = 1
                if let profile = try viewContext.fetch(profileFetchRequest).first {
                    // Call the GateManager function
                    if GateManager.shared.clearGate(gate: gateToClear, profile: profile) {
                        clearResultMessage = "Gate force-cleared successfully!"
                    } else {
                        clearResultMessage = "Failed to force-clear gate (already cleared?)."
                    }
                } else {
                     clearResultMessage = "Error: UserProfile not found."
                }
            } else {
                clearResultMessage = "No 'Analyzed' gates found to clear."
            }
        } catch {
            print("Error fetching gate to force clear: \(error)")
            clearResultMessage = "Error finding gate to clear."
        }
    }
}

// MARK: - Previews
struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
            .preferredColorScheme(.dark)
    }
}
