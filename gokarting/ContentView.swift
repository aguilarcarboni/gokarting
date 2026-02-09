import SwiftUI
import SwiftData

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
                    Button(action: addSampleSession) {
                        Label("Add Test", systemImage: "plus")
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
    
    private func addSampleSession() {
        let session = Session(date: Date(), note: "Practice at Local Track")
        let lapsData = [45.2, 44.8, 44.5, 45.0, 44.2]
        for (i, d) in lapsData.enumerated() {
            let lap = Lap(lapNumber: i+1, duration: d)
            lap.session = session
        }
        modelContext.insert(session)
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
