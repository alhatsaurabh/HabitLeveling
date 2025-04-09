// ContentView.swift

import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            DashboardView()
                .tabItem {
                    Label("Dashboard", systemImage: "house.fill")
                }

            // --- UPDATED Tab ---
            GatesView()
                .tabItem {
                    Label("Gates", systemImage: "shield.lefthalf.filled.slash")
                }

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
        }
        .preferredColorScheme(.dark)
        .tint(ThemeColors.primaryAccent)
    }
}
