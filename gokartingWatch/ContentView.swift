//
//  ContentView.swift
//  gokartingWatch Watch App
//
//  Created by Andres on 8/2/2026.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    var body: some View {
        WatchTimerView()
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Session.self, Lap.self], inMemory: true)
}
