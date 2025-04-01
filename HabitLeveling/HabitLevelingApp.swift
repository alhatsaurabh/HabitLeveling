//
//  HabitLevelingApp.swift
//  HabitLeveling
//
//  Created by Saurabh on 01.04.25.
//

import SwiftUI

@main
struct HabitLevelingApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
