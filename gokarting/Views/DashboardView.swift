//
//  DashboardView.swift
//  gokarting
//
//  Created by Andres on 13/4/2026.
//

import SwiftUI

struct DashboardView: View {
    private let standaloneHeats = SampleData.standaloneHeats
    private let races = SampleData.races

    private var raceHeats: [Heat] {
        races
            .flatMap(\.heats)
            .sorted { $0.date > $1.date }
    }

    private var latestRaceHeat: Heat? {
        raceHeats.first(where: { $0.type == .race })
    }

    private var latestTimeTrial: Heat? {
        standaloneHeats.sorted { $0.date > $1.date }.first
    }

    private var favoriteTrackName: String? {
        var counts: [Track: Int] = [:]

        for heat in standaloneHeats {
            counts[heat.track, default: 0] += 1
        }

        for heat in raceHeats {
            counts[heat.track, default: 0] += 1
        }

        return counts.max(by: { lhs, rhs in
            if lhs.value == rhs.value {
                return lhs.key.rawValue > rhs.key.rawValue
            }
            return lhs.value < rhs.value
        })?.key.rawValue
    }

    var body: some View {
        NavigationStack {
            List {
                Section("Latest Race") {
                    if let latestRaceHeat {
                        LabeledContent("Heat", value: latestRaceHeat.identifier)
                        LabeledContent("Date", value: latestRaceHeat.date.formatted(date: .abbreviated, time: .shortened))
                        LabeledContent("Track", value: latestRaceHeat.track.rawValue)
                        LabeledContent("Kart", value: latestRaceHeat.kart.rawValue)
                        LabeledContent("Best Lap", value: formatLapTime(latestRaceHeat.bestLap))
                    } else {
                        Text("No race data yet")
                            .foregroundStyle(.secondary)
                    }
                }

                Section("Latest Time Trial") {
                    if let latestTimeTrial {
                        LabeledContent("Heat", value: latestTimeTrial.identifier)
                        LabeledContent("Date", value: latestTimeTrial.date.formatted(date: .abbreviated, time: .shortened))
                        LabeledContent("Track", value: latestTimeTrial.track.rawValue)
                        LabeledContent("Kart", value: latestTimeTrial.kart.rawValue)
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
