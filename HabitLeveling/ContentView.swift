// ContentView.swift

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
                
            CalendarView()
                .tabItem {
                    Label("Calendar", systemImage: "calendar")
                }

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
