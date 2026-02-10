import SwiftUI
import SwiftData
import Charts

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Session.date, order: .reverse) private var sessions: [Session]
    
    var body: some View {
        NavigationSplitView {
            List {
                ForEach(sessions) { session in
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
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton()
                }
                // Temporary button to test without Watch
                ToolbarItem {
                    Button(action: addTemplateData) {
                        Label("Add Template Data", systemImage: "plus")
                    }
                }
            }
        } detail: {
            Text("Select a session")
        }
        .onReceive(NotificationCenter.default.publisher(for: .didReceiveWatchSession)) { notification in
            if let transfer = notification.userInfo?["data"] as? ConnectivityManager.SessionTransfer {
                saveReceivedSession(transfer)
            }
        }
    }
    
    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(sessions[index])
            }
        }
    }
    
    private func addTemplateData() {
        let calendar = Calendar.current
        var dateComponents = DateComponents()
        dateComponents.year = 2025
        dateComponents.month = 11
        dateComponents.day = 22
        
        // Heat 1
        dateComponents.hour = 15
        dateComponents.minute = 46

        let date1 = calendar.date(from: dateComponents) ?? Date()
        let session1 = Session(date: date1, note: "Heat 1", track: .fik)
        let laps1 = [
            39.158, 33.545, 33.860, 33.734, 30.998,
            31.876, 30.742, 30.274, 30.577, 29.371,
            27.504, 26.786, 26.486
        ]
        addLaps(laps1, to: session1)
        modelContext.insert(session1)

        // Heat 2
        dateComponents.hour = 16
        dateComponents.minute = 23

        let date2 = calendar.date(from: dateComponents) ?? Date()
        let session2 = Session(date: date2, note: "Heat 2", track: .fik)
        let laps2 = [
            51.24, 83.753, 26.593, 26.486, 31.18,
            28.913, 30.397, 60.457, 31.132, 26.614
        ]
        addLaps(laps2, to: session2)
        modelContext.insert(session2)

        // Heat 3
        dateComponents.hour = 16
        dateComponents.minute = 30

        let date3 = calendar.date(from: dateComponents) ?? Date()
        let session3 = Session(date: date3, note: "Heat 3", track: .fik)
        let laps3 = [
            41.484, 26.394, 28.327, 28.798, 27.210,
            30.373, 61.250, 25.888, 25.446, 26.495,
            26.91, 25.925, 31.807
        ]
        addLaps(laps3, to: session3)
        modelContext.insert(session3)
                
        // Heat 4
        dateComponents.hour = 17
        dateComponents.minute = 21
        let date4 = calendar.date(from: dateComponents) ?? Date()
        let session4 = Session(date: date4, note: "Heat 4", track: .fik)
        let laps4 = [
            55.334, 27.439, 26.324, 26.917, 25.306,
            25.990, 25.553, 24.785, 25.940, 25.809,
            24.899, 27.180, 26.240, 25.561
        ]
        addLaps(laps4, to: session4)
        modelContext.insert(session4)

        // Heat 5
        dateComponents.hour = 17
        dateComponents.minute = 28
        let date5 = calendar.date(from: dateComponents) ?? Date()
        let session5 = Session(date: date5, note: "Heat 5", track: .fik)
        let laps5 = [
            26.725, 24.995, 25.359, 26.574, 25.695,
            27.897, 40.433, 24.882, 24.364, 25.12,
            24.644, 39.677, 25.300, 26.315
        ]
        addLaps(laps5, to: session5)
        modelContext.insert(session5)

        // MARK: - Dec 15, 2025 Data
        dateComponents.year = 2025
        dateComponents.month = 12
        dateComponents.day = 15
        
        // Heat 1
        dateComponents.hour = 15
        dateComponents.minute = 06
        let dateDec1 = calendar.date(from: dateComponents) ?? Date()
        let sessionDec1 = Session(date: dateDec1, note: "Heat 1", track: .fik)
        let lapsDec1 = [
            30.214, 29.396, 28.486, 25.894, 28.864,
            25.989, 25.562, 24.472, 27.734, 25.557,
            24.934, 25.82, 41.801, 25.518
        ]
        addLaps(lapsDec1, to: sessionDec1)
        modelContext.insert(sessionDec1)

        // Heat 2
        dateComponents.hour = 16
        dateComponents.minute = 17
        let dateDec2 = calendar.date(from: dateComponents) ?? Date()
        let sessionDec2 = Session(date: dateDec2, note: "Heat 2", track: .fik)
        let lapsDec2 = [
            26.210, 51.805, 30.304, 28.278, 26.129,
            29.500, 25.896, 25.410, 53.220, 24.263,
            25.929, 25.670, 26.102, 31.428, 30.358,
            25.841, 44.787, 23.893, 24.603, 25.503,
            24.388, 24.591, 24.493, 25.812, 25.832,
            27.35, 26.234, 24.160
        ]
        addLaps(lapsDec2, to: sessionDec2)
        modelContext.insert(sessionDec2)

        // MARK: - January 29, 2025 Data
        dateComponents.year = 2025
        dateComponents.month = 1
        dateComponents.day = 2
        
        // Heat 1
        dateComponents.hour = 16
        dateComponents.minute = 56
        let dateJan1 = calendar.date(from: dateComponents) ?? Date()
        let sessionJan1 = Session(date: dateJan1, note: "Heat 1", track: .fik)
        let lapsJan1 = [
            38.156, 41.551, 24.468, 23.850, 23.588,
            24.547, 23.893, 24.202, 23.760, 23.882,
            23.300, 23.352, 23.138, 23.521, 23.643,
            24.446
        ]
        addLaps(lapsJan1, to: sessionJan1)
        modelContext.insert(sessionJan1)

        // Heat 2
        dateComponents.hour = 17
        dateComponents.minute = 24
        let dateJan2 = calendar.date(from: dateComponents) ?? Date()
        let sessionJan2 = Session(date: dateJan2, note: "Heat 2", track: .fik)
        let lapsJan2 = [
            24.609, 24.157, 24.74, 23.714, 23.85,
            23.692, 23.251, 23.144, 23.158, 22.812,
            22.975, 24.12, 23.443, 23.484, 23.278,
            23.530, 39.369, 23.757, 24.318, 23.361,
            23.207, 24.553, 24.562, 23.940, 24.359,
            56.21, 23.719, 24.731, 27.248, 24.690,
            23.500
        ]
        addLaps(lapsJan2, to: sessionJan2)
        modelContext.insert(sessionJan2)
    }

    private func addLaps(_ durations: [Double], to session: Session) {
        for (i, d) in durations.enumerated() {
            let lap = Lap(lapNumber: i+1, duration: d)
            lap.session = session
        }
    }
    
    private func saveReceivedSession(_ transfer: ConnectivityManager.SessionTransfer) {
        let session = Session(date: transfer.date, note: "Imported from Watch")
        for lapT in transfer.laps {
            let lap = Lap(lapNumber: lapT.lapNumber, duration: lapT.duration, timestamp: lapT.timestamp)
            lap.session = session
        }
        modelContext.insert(session)
    }
    
    private func exportCSV() {
        // Simple print to console or share sheet logic
        // For brevity, just constructing the string
        var csv = "Session Date,Lap Number,Duration\n"
        for session in sessions {
            for lap in session.laps {
                csv += "\(session.date),\(lap.lapNumber),\(lap.duration)\n"
            }
        }
        print("CSV Export:\n\(csv)")
        
        // In real app, present ShareSheet
        let filename = FileManager.default.temporaryDirectory.appendingPathComponent("laps.csv")
        do {
            try csv.write(to: filename, atomically: true, encoding: .utf8)
            let av = UIActivityViewController(activityItems: [filename], applicationActivities: nil)
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let root = windowScene.windows.first?.rootViewController {
                root.present(av, animated: true, completion: nil)
            }
        } catch {
            print("Failed to write CSV")
        }
    }
}

struct SessionRow: View {
    let session: Session
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(session.date.formatted(date: .abbreviated, time: .shortened))
                .font(.headline)
            
            if let track = session.track {
                Text(track.rawValue)
                    .font(.subheadline)
                    .foregroundStyle(.primary)
            }
            
            HStack {
                if let best = session.bestLap {
                    Label(String(format: "Best: %.2fs", best), systemImage: "stopwatch")
                }
                if session.laps.count > 0 {
                    Text("• \(session.laps.count) Laps")
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
                Chart(session.laps.sorted(by: { $0.lapNumber < $1.lapNumber })) { lap in
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
                LabeledContent("Best Lap", value: format(session.bestLap))
                LabeledContent("Avg Lap", value: format(session.averageLap))
                LabeledContent("Consistency (StdDev)", value: format(session.consistency))
            }
            
            Section("Laps") {
                ForEach(session.laps.sorted(by: { $0.lapNumber < $1.lapNumber })) { lap in
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

#Preview {
    ContentView()
}
