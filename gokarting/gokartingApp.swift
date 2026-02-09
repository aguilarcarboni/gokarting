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
    init() {
        // Initialize connectivity
        _ = ConnectivityManager.shared
    }

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Session.self,
            Lap.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
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
