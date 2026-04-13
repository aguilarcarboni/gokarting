import SwiftUI
import SwiftData
import Charts

struct TimeTrialView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Session.date, order: .reverse) private var sessions: [Session]
    @StateObject private var syncMonitor = CloudSyncMonitor()
    @State private var selectedCombo: TrackKartCombo? = nil
    @State private var selectedRange: HistoryRange = .all
    
    var body: some View {
        NavigationSplitView {
            List {
                ForEach(filteredSessions) { session in
                    NavigationLink {
                        SessionDetailView(session: session)
                    } label: {
                        SessionRow(session: session)
                    }
                }
                .onDelete(perform: deleteItems)
            }
            .navigationTitle("Time Trials")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    SyncStatusDot(state: syncMonitor.syncState)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Picker("Combo", selection: $selectedCombo) {
                        Text("All Combos").tag(Optional<TrackKartCombo>.none)
                        ForEach(TrackKartCombo.allCases) { combo in
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
            Text("Select a session")
        }
    }
    
    private var filteredSessions: [Session] {
        sessions.filter { session in
            let comboMatches = selectedCombo == nil || session.trackKartCombo == selectedCombo
            let rangeMatches = selectedRange.contains(session.date)
            return comboMatches && rangeMatches
        }
    }
    
    private func deleteItems(offsets: IndexSet) {
        let source = filteredSessions
        withAnimation {
            for index in offsets {
                modelContext.delete(source[index])
            }
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
    let session: Session
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(session.date.formatted(date: .abbreviated, time: .shortened))
                .font(.headline)
            
            if let combo = session.trackKartCombo {
                Text(combo.displayName)
                    .font(.subheadline)
                    .foregroundStyle(.primary)
            } else if let track = session.track {
                Text(track.rawValue)
                    .font(.subheadline)
                    .foregroundStyle(.primary)
            }
            
            HStack {
                if let best = session.bestLap {
                    Label(String(format: "Best: %.2fs", best), systemImage: "stopwatch")
                }
                if session.safeLaps.count > 0 {
                    Text("• \(session.safeLaps.count) Laps")
                }
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
    }
}

struct SessionDetailView: View {
    let session: Session
    
    var body: some View {
        List {
            Section {
                Chart(session.safeLaps.sorted(by: { $0.lapNumber < $1.lapNumber })) { lap in
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
                if let combo = session.trackKartCombo {
                    LabeledContent("Setup", value: combo.displayName)
                } else if let track = session.track {
                    LabeledContent("Track", value: track.rawValue)
                }
                LabeledContent("Best Lap", value: format(session.bestLap))
                LabeledContent("Avg Lap", value: format(session.averageLap))
                LabeledContent("Avg Lap (No Outliers)", value: format(session.averageLapClean))
                LabeledContent("Consistency (StdDev)", value: format(session.consistency))
            }

            Section("Performance Intelligence") {
                LabeledContent("Median Lap", value: format(session.medianLap))
                LabeledContent("Opening Pace (First 5)", value: format(session.firstLapsAverage(count: 5)))
                LabeledContent("Closing Pace (Last 5)", value: format(session.lastLapsAverage(count: 5)))
                LabeledContent("Pace Delta (Last 5 vs First 5)") {
                    if let delta = session.paceDeltaLastVsFirstFive {
                        Text(formatDelta(delta))
                            .foregroundStyle(delta <= 0 ? .green : .red)
                    } else {
                        Text("--")
                    }
                }
                LabeledContent("Clean Lap Ratio") {
                    if let ratio = session.cleanLapRatio {
                        Text("\(Int((ratio * 100).rounded()))%")
                    } else {
                        Text("--")
                    }
                }
            }
            
            Section("Laps") {
                ForEach(session.safeLaps.sorted(by: { $0.lapNumber < $1.lapNumber })) { lap in
                    HStack {
                        Text("\(lap.lapNumber)")
                            .monospacedDigit()
                            .foregroundStyle(.secondary)
                            .frame(width: 30)
                        Text(format(lap.duration))
                            .monospaced()
                        Spacer()
                        // Highlight best lap
                        if lap.duration == session.bestLap {
                            Image(systemName: "trophy.fill")
                                .foregroundStyle(.yellow)
                        }
                    }
                }
            }
        }
        .navigationTitle("Session Details")
    }
    
    func format(_ value: TimeInterval?) -> String {
        guard let value = value else { return "--" }
        return String(format: "%.3f s", value)
    }

    func formatDelta(_ value: TimeInterval) -> String {
        let sign = value > 0 ? "+" : ""
        return String(format: "%@%.3f s", sign, value)
    }
}

struct SyncStatusDot: View {
    let state: SyncState

    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(dotColor)
                .frame(width: 8, height: 8)
                .overlay {
                    if state == .syncing {
                        Circle()
                            .stroke(dotColor.opacity(0.4), lineWidth: 2)
                            .scaleEffect(1.8)
                            .opacity(0)
                            .animation(
                                .easeOut(duration: 1.2)
                                    .repeatForever(autoreverses: false),
                                value: state
                            )
                    }
                }
        }
    }

    private var dotColor: Color {
        switch state {
        case .synced:       return .green
        case .syncing:      return .orange
        case .error:        return .red
        case .notAvailable: return .gray
        }
    }

    private var label: String {
        switch state {
        case .synced:       return "iCloud"
        case .syncing:      return "Syncing"
        case .error:        return "Sync Error"
        case .notAvailable: return "Offline"
        }
    }
}

struct RaceHistoryView: View {
    @Query(sort: \RaceEvent.date, order: .reverse) private var raceEvents: [RaceEvent]

    var body: some View {
        NavigationSplitView {
            List {
                if raceEvents.isEmpty {
                    ContentUnavailableView(
                        "No Race Events",
                        systemImage: "flag.checkered.2.crossed",
                        description: Text("Seed race CSV data to see events here.")
                    )
                } else {
                    ForEach(raceEvents) { event in
                        NavigationLink {
                            RaceEventDetailView(event: event)
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(event.name)
                                    .font(.headline)
                                Text(event.date.formatted(date: .abbreviated, time: .shortened))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                if let track = event.track {
                                    Text(track.rawValue)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
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
    let event: RaceEvent

    private var sortedSessions: [RaceSession] {
        (event.sessions ?? []).sorted(by: { $0.startTime < $1.startTime })
    }

    var body: some View {
        List {
            Section("Event") {
                LabeledContent("Name", value: event.name)
                LabeledContent("Date", value: event.date.formatted(date: .abbreviated, time: .shortened))
                if let location = event.location {
                    LabeledContent("Location", value: location)
                }
                if let track = event.track {
                    LabeledContent("Track", value: track.rawValue)
                } else if let trackName = event.trackName {
                    LabeledContent("Track", value: trackName)
                }
                if let trackLengthKM = event.trackLengthKM {
                    LabeledContent("Length", value: String(format: "%.2f km", trackLengthKM))
                }
            }

            Section("Sessions") {
                if sortedSessions.isEmpty {
                    Text("No sessions")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(sortedSessions) { session in
                        NavigationLink {
                            RaceSessionDetailView(session: session)
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(session.runName)
                                    .font(.headline)
                                Text(session.startTime.formatted(date: .abbreviated, time: .shortened))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text(session.runType.displayName)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle(event.name)
    }
}

struct RaceSessionDetailView: View {
    let session: RaceSession

    private var sortedResults: [RaceResult] {
        (session.results ?? []).sorted { lhs, rhs in
            switch (lhs.position, rhs.position) {
            case let (l?, r?):
                return l < r
            case (_?, nil):
                return true
            case (nil, _?):
                return false
            case (nil, nil):
                return (lhs.driverName ?? "") < (rhs.driverName ?? "")
            }
        }
    }

    var body: some View {
        List {
            Section("Session") {
                LabeledContent("Run", value: session.runName)
                LabeledContent("Type", value: session.runType.displayName)
                LabeledContent("Day", value: session.day ?? "--")
                LabeledContent("Start", value: session.startTime.formatted(date: .abbreviated, time: .shortened))
                LabeledContent("Best Lap", value: format(session.bestLapTime))
            }

            if let stats = session.stats {
                Section("Stats") {
                    LabeledContent("Best Driver", value: stats.bestLapDriver ?? "--")
                    LabeledContent("Best Lap", value: format(stats.bestLapTime))
                    LabeledContent("Total Laps", value: format(stats.totalLaps))
                    LabeledContent("Leader Laps", value: format(stats.totalLapsLeader))
                    LabeledContent("Participants", value: format(stats.numParticipants))
                    LabeledContent("Positions", value: format(stats.numPositions))
                }
            }

            Section("Results") {
                if sortedResults.isEmpty {
                    Text("No results")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(sortedResults) { result in
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(result.position.map { "#\($0)" } ?? "--")
                                    .font(.subheadline)
                                    .bold()
                                Text(result.driverName ?? "Unknown Driver")
                                    .font(.subheadline)
                                Spacer()
                                Text(format(result.totalTime))
                                    .font(.caption)
                                    .monospacedDigit()
                                    .foregroundStyle(.secondary)
                            }
                            HStack(spacing: 12) {
                                Text("Best: \(format(result.bestLapTime))")
                                Text("Laps: \(format(result.lapsCompleted))")
                                Text(result.finished ? "Finished" : "DNF")
                            }
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .navigationTitle(session.runName)
    }

    private func format(_ value: TimeInterval?) -> String {
        guard let value else { return "--" }
        return String(format: "%.3f s", value)
    }

    private func format(_ value: Int?) -> String {
        guard let value else { return "--" }
        return "\(value)"
    }
}

private extension RaceSessionType {
    var displayName: String {
        switch self {
        case .race:
            return "Race"
        case .practice:
            return "Practice"
        case .quali:
            return "Qualifying"
        case .unknown:
            return "Unknown"
        }
    }
}

#Preview {
    TimeTrialView()
}
