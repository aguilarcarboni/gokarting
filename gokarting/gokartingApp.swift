//
//  gokartingApp.swift
//  gokarting
//
//  Created by Andres on 8/2/2026.
//

import SwiftUI
import SwiftData

@main
struct gokartingApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Session.self,
            Lap.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)

        do {
            let container = try ModelContainer(for: schema, configurations: [modelConfiguration])
            Task { @MainActor in
                DataSeeder.seed(context: container.mainContext)
            }
            return container
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            #if os(watchOS)
            WatchTimerView()
            #else
            ContentView()
            #endif
        }
        .modelContainer(sharedModelContainer)
    }
}
