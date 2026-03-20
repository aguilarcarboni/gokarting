import SwiftUI
import SwiftData
import Charts

struct HistoryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Session.date, order: .reverse) private var sessions: [Session]
    @StateObject private var syncMonitor = CloudSyncMonitor()
    @State private var selectedCombo: TrackKartCombo? = nil
    
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
            .navigationTitle("History")
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
            }
        } detail: {
            Text("Select a session")
        }
    }
    
    private var filteredSessions: [Session] {
        guard let selectedCombo else { return sessions }
        return sessions.filter { $0.trackKartCombo == selectedCombo }
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

#Preview {
    HistoryView()
}
