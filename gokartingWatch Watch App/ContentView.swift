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
        TabView {
            WatchTimerView()
                .tabItem {
                    Label("Race", systemImage: "timer")
                }
            
            HistoryView()
                .tabItem {
                    Label("History", systemImage: "list.bullet")
                }
        }
    }
}

struct HistoryView: View {
    @Query(sort: \Session.date, order: .reverse) private var sessions: [Session]
    
    var body: some View {
        NavigationStack {
            List {
                if sessions.isEmpty {
                    Text("No sessions recorded yet.")
                        .foregroundStyle(.secondary)
                        .listRowBackground(Color.clear)
                } else {
                    ForEach(sessions) { session in
                        NavigationLink(destination: SessionDetailView(session: session)) {
                            VStack(alignment: .leading) {
                                Text(session.date.formatted(date: .abbreviated, time: .shortened))
                                    .font(.headline)
                                HStack {
                                    Text("\(session.laps.count) Laps")
                                    if let best = session.bestLap {
                                        Spacer()
                                        Text("Best: \(formatTime(best))")
                                    }
                                }
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .onDelete(perform: deleteSession)
                }
            }
            .navigationTitle("History")
        }
    }
    
    @Environment(\.modelContext) private var modelContext
    
    private func deleteSession(offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(sessions[index])
        }
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        let milliseconds = Int((time.truncatingRemainder(dividingBy: 1)) * 100)
        return String(format: "%02d:%02d.%02d", minutes, seconds, milliseconds)
    }
}

struct SessionDetailView: View {
    let session: Session
    
    var body: some View {
        List {
            Section(header: Text("Summary")) {
                LabeledContent("Total Laps", value: "\(session.laps.count)")
                if let best = session.bestLap {
                    LabeledContent("Best Lap", value: formatTime(best))
                }
                if let avg = session.averageLap {
                    LabeledContent("Avg Lap", value: formatTime(avg))
                }
            }
            
            Section(header: Text("Laps")) {
                ForEach(session.laps.sorted(by: { $0.lapNumber < $1.lapNumber })) { lap in
                    HStack {
                        Text("Lap \(lap.lapNumber)")
                        Spacer()
                        Text(formatTime(lap.duration))
                            .font(.monospacedDigit(.body)())
                    }
                }
            }
        }
        .navigationTitle("Session")
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        let milliseconds = Int((time.truncatingRemainder(dividingBy: 1)) * 100)
        return String(format: "%02d:%02d.%02d", minutes, seconds, milliseconds)
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Session.self, Lap.self], inMemory: true)
}
