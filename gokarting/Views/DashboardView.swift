//
//  DashboardView.swift
//  gokarting
//
//  Created by Andres on 13/4/2026.
//

import SwiftUI
import SwiftData

struct DashboardView: View {
    @Query(sort: \RaceEvent.date, order: .reverse) private var raceEvents: [RaceEvent]
    @Query(sort: \Session.date, order: .reverse) private var sessions: [Session]

    private var latestRace: RaceEvent? {
        raceEvents.first
    }

    private var latestTimeTrial: Session? {
        sessions.first
    }

    private var favoriteTrackName: String? {
        var counts: [String: Int] = [:]

        for session in sessions {
            guard let trackName = session.track?.rawValue else { continue }
            counts[trackName, default: 0] += 1
        }

        for event in raceEvents {
            let trackName = event.track?.rawValue ?? event.trackName
            guard let trackName else { continue }
            counts[trackName, default: 0] += 1
        }

        return counts.max(by: { lhs, rhs in
            if lhs.value == rhs.value {
                return lhs.key > rhs.key
            }
            return lhs.value < rhs.value
        })?.key
    }

    var body: some View {
        NavigationStack {
            List {
                Section("Latest Race") {
                    if let latestRace {
                        LabeledContent("Event", value: latestRace.name)
                        LabeledContent("Date", value: latestRace.date.formatted(date: .abbreviated, time: .shortened))
                        LabeledContent("Track", value: latestRace.track?.rawValue ?? latestRace.trackName ?? "--")
                    } else {
                        Text("No race data yet")
                            .foregroundStyle(.secondary)
                    }
                }

                Section("Latest Time Trial") {
                    if let latestTimeTrial {
                        LabeledContent("Date", value: latestTimeTrial.date.formatted(date: .abbreviated, time: .shortened))
                        LabeledContent("Track", value: latestTimeTrial.track?.rawValue ?? "--")
                        LabeledContent("Best Lap", value: formatLapTime(latestTimeTrial.bestLap))
                    } else {
                        Text("No time trial data yet")
                            .foregroundStyle(.secondary)
                    }
                }

                Section("Favorite Track") {
                    if let favoriteTrackName {
                        Text(favoriteTrackName)
                    } else {
                        Text("Not enough data yet")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Dashboard")
        }
    }

    private func formatLapTime(_ value: TimeInterval?) -> String {
        guard let value else { return "--" }
        return String(format: "%.3f s", value)
    }
}
