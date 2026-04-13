import SwiftUI
import Charts

struct TimeTrialView: View {
    private let sessions = SampleData.standaloneHeats.sorted { $0.date > $1.date }
    private let raceEvents = SampleData.races

    @State private var selectedCombo: TrackKartCombo? = nil
    @State private var selectedRange: HistoryRange = .all

    var body: some View {
        NavigationSplitView {
            List {
                ForEach(filteredSessions) { heat in
                    NavigationLink {
                        SessionDetailView(heat: heat)
                    } label: {
                        SessionRow(heat: heat)
                    }
                }
            }
            .navigationTitle("Time Trials")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Picker("Combo", selection: $selectedCombo) {
                        Text("All Combos").tag(Optional<TrackKartCombo>.none)
                        ForEach(availableCombos) { combo in
                            Text(combo.displayName).tag(Optional(combo))
                        }
                    }
                    .pickerStyle(.menu)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Picker("Range", selection: $selectedRange) {
                        ForEach(HistoryRange.allCases) { range in
                            Text(range.label).tag(range)
                        }
                    }
                    .pickerStyle(.menu)
                }
            }
        } detail: {
            RaceHistoryView(raceEvents: raceEvents)
        }
    }

    private var availableCombos: [TrackKartCombo] {
        let combos = Set(sessions.map { TrackKartCombo(track: $0.track, kart: $0.kart) })
        return combos.sorted { $0.displayName < $1.displayName }
    }

    private var filteredSessions: [Heat] {
        sessions.filter { session in
            let comboMatches = selectedCombo == nil || (session.track == selectedCombo?.track && session.kart == selectedCombo?.kart)
            let rangeMatches = selectedRange.contains(session.date)
            return comboMatches && rangeMatches
        }
    }
}

private enum HistoryRange: String, CaseIterable, Identifiable {
    case all
    case last30Days
    case last90Days
    case thisYear

    var id: String { rawValue }

    var label: String {
        switch self {
        case .all: return "All Time"
        case .last30Days: return "Last 30 Days"
        case .last90Days: return "Last 90 Days"
        case .thisYear: return "This Year"
        }
    }

    func contains(_ date: Date) -> Bool {
        let calendar = Calendar.current
        let now = Date()

        switch self {
        case .all:
            return true
        case .last30Days:
            guard let cutoff = calendar.date(byAdding: .day, value: -30, to: now) else { return true }
            return date >= cutoff
        case .last90Days:
            guard let cutoff = calendar.date(byAdding: .day, value: -90, to: now) else { return true }
            return date >= cutoff
        case .thisYear:
            let currentYear = calendar.component(.year, from: now)
            let dateYear = calendar.component(.year, from: date)
            return dateYear == currentYear
        }
    }
}

struct SessionRow: View {
    let heat: Heat

    var body: some View {
        VStack(alignment: .leading) {
            Text(heat.date.formatted(date: .abbreviated, time: .shortened))
                .font(.headline)

            Text("\(heat.track.rawValue) • \(heat.kart.rawValue)")
                .font(.subheadline)
                .foregroundStyle(.primary)

            HStack {
                if let best = heat.bestLap {
                    Label(String(format: "Best: %.2fs", best), systemImage: "stopwatch")
                }
                Text("• \(heat.laps.count) Laps")
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
    }
}

struct SessionDetailView: View {
    let heat: Heat

    private var sortedLaps: [Lap] {
        heat.laps.sorted(by: { $0.lapNumber < $1.lapNumber })
    }

    var body: some View {
        List {
            Section {
                Chart(sortedLaps) { lap in
                    LineMark(
                        x: .value("Lap", lap.lapNumber),
                        y: .value("Time", lap.duration)
                    )
                    .interpolationMethod(.catmullRom)

                    PointMark(
                        x: .value("Lap", lap.lapNumber),
                        y: .value("Time", lap.duration)
                    )
                }
                .frame(height: 200)
                .chartYScale(domain: .automatic(includesZero: false))
            } header: {
                Text("Lap Progression")
            }

            Section("Stats") {
                LabeledContent("Track", value: heat.track.rawValue)
                LabeledContent("Kart", value: heat.kart.rawValue)
                LabeledContent("Best Lap", value: format(heat.bestLap))
                LabeledContent("Avg Lap", value: format(heat.averageLap))
                LabeledContent("Median Lap", value: format(heat.medianLap))
                LabeledContent("Consistency (StdDev)", value: format(heat.consistency))
                LabeledContent("Opening Pace (First 5)", value: format(heat.firstLapsAverage(count: 5)))
                LabeledContent("Closing Pace (Last 5)", value: format(heat.lastLapsAverage(count: 5)))
            }

            Section("Laps") {
                ForEach(sortedLaps) { lap in
                    HStack {
                        Text("\(lap.lapNumber)")
                            .monospacedDigit()
                            .foregroundStyle(.secondary)
                            .frame(width: 30)
                        Text(format(lap.duration))
                            .monospaced()
                        Spacer()
                        if lap.duration == heat.bestLap {
                            Image(systemName: "trophy.fill")
                                .foregroundStyle(.yellow)
                        }
                    }
                }
            }
        }
        .navigationTitle(heat.identifier)
    }

    private func format(_ value: TimeInterval?) -> String {
        guard let value = value else { return "--" }
        return String(format: "%.3f s", value)
    }

    private func format(_ value: TimeInterval) -> String {
        String(format: "%.3f s", value)
    }
}

struct RaceHistoryView: View {
    let raceEvents: [Race]

    var body: some View {
        NavigationSplitView {
            List {
                if raceEvents.isEmpty {
                    ContentUnavailableView(
                        "No Race Events",
                        systemImage: "flag.checkered.2.crossed",
                        description: Text("No races loaded in SampleData.")
                    )
                } else {
                    ForEach(raceEvents) { race in
                        NavigationLink {
                            RaceEventDetailView(race: race)
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("\(race.track.rawValue) • \(race.kart.rawValue)")
                                    .font(.headline)
                                Text("\(race.heats.count) heats")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Race History")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink {
                        ProgressionView(initialSource: .races)
                    } label: {
                        Label("Progression", systemImage: "chart.line.uptrend.xyaxis")
                    }
                }
            }
        } detail: {
            Text("Select an event")
        }
    }
}

struct RaceEventDetailView: View {
    let race: Race

    private var sortedHeats: [Heat] {
        race.heats.sorted(by: { $0.date < $1.date })
    }

    var body: some View {
        List {
            Section("Event") {
                LabeledContent("Track", value: race.track.rawValue)
                LabeledContent("Kart", value: race.kart.rawValue)
                LabeledContent("Heats", value: "\(race.heats.count)")
            }

            Section("Sessions") {
                if sortedHeats.isEmpty {
                    Text("No sessions")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(sortedHeats) { heat in
                        NavigationLink {
                            RaceSessionDetailView(heat: heat)
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(heat.identifier)
                                    .font(.headline)
                                Text(heat.date.formatted(date: .abbreviated, time: .shortened))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text(heat.type.label)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle(race.track.rawValue)
    }
}

struct RaceSessionDetailView: View {
    let heat: Heat

    private var sortedResults: [DriverAggregate] {
        Dictionary(grouping: heat.laps, by: { ($0.competitorID ?? $0.driverNumber ?? $0.driverName ?? "unknown") })
            .values
            .compactMap { laps in
                guard !laps.isEmpty else { return nil }
                let sorted = laps.sorted(by: { $0.lapNumber < $1.lapNumber })
                let bestLap = sorted.map(\.duration).min()
                let total = sorted.reduce(0.0) { $0 + $1.duration }
                return DriverAggregate(
                    id: sorted[0].competitorID ?? sorted[0].driverNumber ?? sorted[0].id.uuidString,
                    driverNumber: sorted[0].driverNumber,
                    driverName: sorted[0].driverName ?? "Unknown Driver",
                    lapsCompleted: sorted.count,
                    bestLapTime: bestLap,
                    totalTime: total
                )
            }
            .sorted { lhs, rhs in
                switch (lhs.bestLapTime, rhs.bestLapTime) {
                case let (l?, r?):
                    return l < r
                case (_?, nil):
                    return true
                case (nil, _?):
                    return false
                case (nil, nil):
                    return lhs.driverName < rhs.driverName
                }
            }
    }

    var body: some View {
        List {
            Section("Session") {
                LabeledContent("Heat", value: heat.identifier)
                LabeledContent("Type", value: heat.type.label)
                LabeledContent("Start", value: heat.date.formatted(date: .abbreviated, time: .shortened))
                LabeledContent("Track", value: heat.track.rawValue)
                LabeledContent("Kart", value: heat.kart.rawValue)
                LabeledContent("Best Lap", value: format(heat.bestLap))
            }

            Section("Results") {
                if sortedResults.isEmpty {
                    Text("No results")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(Array(sortedResults.enumerated()), id: \.element.id) { index, result in
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text("#\(index + 1)")
                                    .font(.subheadline)
                                    .bold()
                                Text(result.displayName)
                                    .font(.subheadline)
                                Spacer()
                                Text(format(result.totalTime))
                                    .font(.caption)
                                    .monospacedDigit()
                                    .foregroundStyle(.secondary)
                            }
                            HStack(spacing: 12) {
                                Text("Best: \(format(result.bestLapTime))")
                                Text("Laps: \(result.lapsCompleted)")
                            }
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .navigationTitle(heat.identifier)
    }

    private func format(_ value: TimeInterval?) -> String {
        guard let value else { return "--" }
        return String(format: "%.3f s", value)
    }
}

private struct DriverAggregate: Identifiable {
    let id: String
    let driverNumber: String?
    let driverName: String
    let lapsCompleted: Int
    let bestLapTime: TimeInterval?
    let totalTime: TimeInterval

    var displayName: String {
        if let driverNumber, !driverNumber.isEmpty {
            return "#\(driverNumber) \(driverName)"
        }
        return driverName
    }
}

#Preview {
    TimeTrialView()
}
