//
//  gokartingWatchApp.swift
//  gokartingWatch Watch App
//
//  Created by Andres on 8/2/2026.
//

import SwiftUI
import SwiftData

@main
struct gokartingWatch_Watch_AppApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Session.self,
            Lap.self,
        ])

        let container: ModelContainer

        // Try with iCloud sync first, fall back to local-only storage
        do {
            let cloudConfig = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false,
                cloudKitDatabase: .automatic
            )
            container = try ModelContainer(for: schema, configurations: [cloudConfig])
        } catch {
            print("⚠️ iCloud sync unavailable (\(error)), using local storage.")
            let storeURL = URL.applicationSupportDirectory.appending(path: "default.store")
            try? FileManager.default.removeItem(at: storeURL)
            do {
                let localConfig = ModelConfiguration(
                    schema: schema,
                    isStoredInMemoryOnly: false
                )
                container = try ModelContainer(for: schema, configurations: [localConfig])
            } catch {
                fatalError("Could not create ModelContainer: \(error)")
            }
        }

        return container
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}
