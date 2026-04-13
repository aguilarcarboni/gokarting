import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            DashboardView()
                .tabItem {
                    Label("Dashboard", systemImage: "gauge.with.dots.needle.33percent")
                }
            TimeTrialView()
                .tabItem {
                    Label("Time Trials", systemImage: "clock")
                }
            RaceHistoryView()
                .tabItem {
                    Label("Races", systemImage: "flag.checkered.2.crossed")
                }
            ProgressionView()
                .tabItem {
                    Label("Progression", systemImage: "chart.line.uptrend.xyaxis")
                }
            TracksView()
                .tabItem {
                    Label("Tracks", systemImage: "map")
                }
        }
    }
}

private struct TracksView: View {
    var body: some View {
        NavigationStack {
            List {
                if Track.allCases.isEmpty {
                    ContentUnavailableView(
                        "No Tracks",
                        systemImage: "map",
                        description: Text("No tracks are available yet.")
                    )
                    .listRowBackground(Color.clear)
                } else {
                    Section("Available Tracks") {
                        ForEach(Track.allCases, id: \.self) { track in
                            NavigationLink {
                                TrackDetailView(track: track)
                            } label: {
                                Text(track.rawValue)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Tracks")
        }
    }
}

private struct TrackDetailView: View {
    let track: Track

    var body: some View {
        List {
            Section("Track") {
                Text(track.rawValue)
            }

            Section("Map") {
                Label(
                    track.supportsTrackMap ? "Track map available" : "Track map not available",
                    systemImage: track.supportsTrackMap ? "checkmark.circle.fill" : "xmark.circle"
                )
                .foregroundStyle(track.supportsTrackMap ? .green : .secondary)
            }

            Section("Available Karts") {
                ForEach(track.availableKarts, id: \.self) { kart in
                    Text(kart.rawValue)
                }
            }
        }
        .navigationTitle(track.rawValue)
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    ContentView()
}
