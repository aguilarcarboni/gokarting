import SwiftUI
import SwiftData
import Charts

struct ProgressionView: View {
    @Query(sort: \Session.date) private var allSessions: [Session]
    @State private var selectedTrack: Track = Track.allCases.first!

    private var filteredSessions: [Session] {
        allSessions
            .filter { $0.track == selectedTrack && !$0.safeLaps.isEmpty }
            .sorted { $0.date < $1.date }
    }

    private var chartData: [DayPoint] {
        let calendar = Calendar.current

        // Group sessions by calendar day
        let grouped = Dictionary(grouping: filteredSessions) { session in
            calendar.startOfDay(for: session.date)
        }

        return grouped.compactMap { day, sessions in
            let averages = sessions.compactMap(\.averageLap)
            let bests = sessions.compactMap(\.bestLap)
            guard !averages.isEmpty, !bests.isEmpty else { return nil }

            let avgOfAverages = averages.reduce(0, +) / Double(averages.count)
            let bestOfBests = bests.min()!

            return DayPoint(date: day, averageLap: avgOfAverages, bestLap: bestOfBests, sessionCount: sessions.count)
        }
        .sorted { $0.date < $1.date }
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Picker("Track", selection: $selectedTrack) {
                        ForEach(Track.allCases, id: \.self) { track in
                            Text(track.rawValue).tag(track)
                        }
                    }
                    .pickerStyle(.menu)
                }

                if chartData.isEmpty {
                    ContentUnavailableView(
                        "No Sessions",
                        systemImage: "chart.line.downtrend.xyaxis",
                        description: Text("Record some sessions at \(selectedTrack.rawValue) to see your progression.")
                    )
                    .listRowBackground(Color.clear)
                } else {
                    Section {
                        averageLapChart
                    } header: {
                        Text("Average Lap Over Time")
                    }

                    Section {
                        bestLapChart
                    } header: {
                        Text("Best Lap Over Time")
                    }

                    Section("Summary") {
                        LabeledContent("Days", value: "\(chartData.count)")
                        LabeledContent("Total Heats", value: "\(chartData.reduce(0) { $0 + $1.sessionCount })")
                        if let first = chartData.first, let last = chartData.last, chartData.count >= 2 {
                            let avgDelta = last.averageLap - first.averageLap
                            let bestDelta = last.bestLap - first.bestLap
                            LabeledContent("Avg Lap Change") {
                                Text(formatDelta(avgDelta))
                                    .foregroundStyle(avgDelta <= 0 ? .green : .red)
                            }
                            LabeledContent("Best Lap Change") {
                                Text(formatDelta(bestDelta))
                                    .foregroundStyle(bestDelta <= 0 ? .green : .red)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Progression")
        }
    }

    // MARK: - Average Lap Chart

    private var averageLapChart: some View {
        Chart(chartData) { point in
            LineMark(
                x: .value("Date", point.date),
                y: .value("Avg Lap", point.averageLap)
            )
            .interpolationMethod(.catmullRom)
            .foregroundStyle(.blue)

            PointMark(
                x: .value("Date", point.date),
                y: .value("Avg Lap", point.averageLap)
            )
            .foregroundStyle(.blue)
            .annotation(position: .top, spacing: 4) {
                Text(format(point.averageLap))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .chartYScale(domain: .automatic(includesZero: false))
        .chartYAxis {
            AxisMarks { value in
                AxisGridLine()
                AxisValueLabel {
                    if let v = value.as(Double.self) {
                        Text(format(v))
                    }
                }
            }
        }
        .frame(height: 220)
    }

    // MARK: - Best Lap Chart

    private var bestLapChart: some View {
        Chart(chartData) { point in
            LineMark(
                x: .value("Date", point.date),
                y: .value("Best Lap", point.bestLap)
            )
            .interpolationMethod(.catmullRom)
            .foregroundStyle(.orange)

            PointMark(
                x: .value("Date", point.date),
                y: .value("Best Lap", point.bestLap)
            )
            .foregroundStyle(.orange)
            .annotation(position: .top, spacing: 4) {
                Text(format(point.bestLap))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .chartYScale(domain: .automatic(includesZero: false))
        .chartYAxis {
            AxisMarks { value in
                AxisGridLine()
                AxisValueLabel {
                    if let v = value.as(Double.self) {
                        Text(format(v))
                    }
                }
            }
        }
        .frame(height: 220)
    }

    // MARK: - Helpers

    private func format(_ value: TimeInterval) -> String {
        String(format: "%.2fs", value)
    }

    private func formatDelta(_ value: TimeInterval) -> String {
        let sign = value <= 0 ? "" : "+"
        return String(format: "%@%.2fs", sign, value)
    }
}

// MARK: - Chart Data Point

private struct DayPoint: Identifiable {
    let id = UUID()
    let date: Date
    let averageLap: TimeInterval
    let bestLap: TimeInterval
    let sessionCount: Int
}

#Preview {
    ProgressionView()
}
