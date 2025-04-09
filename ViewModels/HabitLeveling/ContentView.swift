
import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            DashboardView()
                .tabItem {
                    Label("Dashboard", systemImage: "house.fill")
                }

            HabitListView()
                .tabItem {
                    Label("Habits", systemImage: "list.bullet")
                }

            // --- UPDATED Tab ---
            GatesView() // Use the renamed view
                .tabItem {
                    Label("Gates", systemImage: "shield.lefthalf.filled.slash") // Example icon for Gates
                }
            // --- END UPDATED Tab ---

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
        }
        .preferredColorScheme(.dark)
        .tint(ThemeColors.primaryAccent) // Use theme color
    }
}
