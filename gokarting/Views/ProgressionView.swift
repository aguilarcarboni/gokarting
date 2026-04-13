import SwiftUI
import SwiftData
import Charts

struct ProgressionView: View {
    @Query(sort: \Session.date) private var allSessions: [Session]
    @Query(sort: \RaceSession.startTime) private var allRaceSessions: [RaceSession]
    @State private var selectedSource: ProgressionSource
    @State private var selectedSort: ProgressionSort = .date
    @State private var selectedCombo: TrackKartCombo = TrackKartCombo.allCases.first!
    @State private var selectedRaceTrack: Track? = nil

    init(initialSource: ProgressionSource = .timeTrials) {
        _selectedSource = State(initialValue: initialSource)
    }

    private var filteredTimeTrialSessions: [Session] {
        allSessions
            .filter { $0.trackKartCombo == selectedCombo && !$0.safeLaps.isEmpty }
    }

    private var filteredRaceSessions: [RaceSession] {
        allRaceSessions
            .filter { $0.runType == .race }
            .filter { session in
                selectedRaceTrack == nil || session.event?.track == selectedRaceTrack
            }
            .filter { $0.bestLapTime != nil }
    }

    private var timeTrialChartData: [DayPoint] {
        filteredTimeTrialSessions.compactMap { session in
            guard let averageLap = session.averageLap, let bestLap = session.bestLap else { return nil }
            return DayPoint(
                date: session.date,
                heatNumber: extractHeatNumber(from: session.note),
                averageLap: averageLap,
                bestLap: bestLap,
                sessionCount: 1
            )
        }
    }

    private var raceChartData: [DayPoint] {
        filteredRaceSessions.compactMap { session in
            guard let bestLapTime = session.bestLapTime else { return nil }
            return DayPoint(
                date: session.startTime,
                heatNumber: extractHeatNumber(from: session.runName),
                averageLap: bestLapTime,
                bestLap: bestLapTime,
                sessionCount: 1
            )
        }
    }

    private var availableRaceTracks: [Track] {
        let trackSet = Set(allRaceSessions.compactMap { $0.event?.track })
        return trackSet.sorted { $0.rawValue < $1.rawValue }
    }

    private var rawChartData: [DayPoint] {
        selectedSource == .timeTrials ? timeTrialChartData : raceChartData
    }

    private var heatChartData: [DayPoint] {
        rawChartData.sorted {
            switch ($0.heatNumber, $1.heatNumber) {
            case let (lhs?, rhs?):
                return lhs < rhs
            case (nil, nil):
                return $0.date < $1.date
            case (.some, nil):
                return true
            case (nil, .some):
                return false
            }
        }
    }

    private var dateChartData: [DayPoint] {
        let groupedByDay = Dictionary(grouping: rawChartData) { point in
            Calendar.current.startOfDay(for: point.date)
        }

        return groupedByDay.keys.sorted().compactMap { day in
            guard let points = groupedByDay[day], !points.isEmpty else { return nil }

            let averageLap = points.reduce(0) { $0 + $1.averageLap } / Double(points.count)
            guard let bestLap = points.map(\.bestLap).min() else { return nil }
            let sessionCount = points.reduce(0) { $0 + $1.sessionCount }

            return DayPoint(
                date: day,
                heatNumber: nil,
                averageLap: averageLap,
                bestLap: bestLap,
                sessionCount: sessionCount
            )
        }
    }

    private var chartData: [DayPoint] {
        selectedSort == .date ? dateChartData : heatChartData
    }

    private var heatChartPoints: [ChartPoint] {
        heatChartData.enumerated().map { index, point in
            ChartPoint(
                point: point,
                heatIndex: index + 1
            )
        }
    }

    private var heatXDomain: ClosedRange<Int> {
        0...max(heatChartPoints.count + 2, 2)
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Picker("Source", selection: $selectedSource) {
                        ForEach(ProgressionSource.allCases) { source in
                            Text(source.label).tag(source)
                        }
                    }
                    .pickerStyle(.segmented)

                    Picker("Sort", selection: $selectedSort) {
                        ForEach(ProgressionSort.allCases) { sort in
                            Text(sort.label).tag(sort)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section {
                    if selectedSource == .timeTrials {
                        Picker("Combo", selection: $selectedCombo) {
                            ForEach(TrackKartCombo.allCases) { combo in
                                Text(combo.displayName).tag(combo)
                            }
                        }
                        .pickerStyle(.menu)
                    } else {
                        Picker("Track", selection: $selectedRaceTrack) {
                            Text("All Tracks").tag(Optional<Track>.none)
                            ForEach(availableRaceTracks, id: \.self) { track in
                                Text(track.rawValue).tag(Optional(track))
                            }
                        }
                        .pickerStyle(.menu)
                    }
                }

                if chartData.isEmpty {
                    ContentUnavailableView(
                        selectedSource == .timeTrials ? "No Sessions" : "No Race Sessions",
                        systemImage: "chart.line.downtrend.xyaxis",
                        description: Text(emptyStateDescription)
                    )
                    .listRowBackground(Color.clear)
                } else {
                    Section {
                        averageLapChart
                    } header: {
                        Text(selectedSource == .timeTrials ? "Average Lap Over Time" : "Average Best Lap Over Time")
                    }

                    Section {
                        bestLapChart
                    } header: {
                        Text("Best Lap Over Time")
                    }
                }

                if !chartData.isEmpty {
                    Section("Summary") {
                        LabeledContent(primaryCountLabel, value: "\(chartData.count)")
                        LabeledContent("Data Points", value: "\(chartData.reduce(0) { $0 + $1.sessionCount })")
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
        Group {
            if selectedSort == .date {
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
            } else {
                Chart(heatChartPoints) { chartPoint in
                    LineMark(
                        x: .value("Heat", chartPoint.heatIndex),
                        y: .value("Avg Lap", chartPoint.point.averageLap)
                    )
                    .interpolationMethod(.catmullRom)
                    .foregroundStyle(.blue)

                    PointMark(
                        x: .value("Heat", chartPoint.heatIndex),
                        y: .value("Avg Lap", chartPoint.point.averageLap)
                    )
                    .foregroundStyle(.blue)
                    .annotation(position: .top, spacing: 4) {
                        Text(format(chartPoint.point.averageLap))
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                .chartXScale(domain: heatXDomain)
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
        Group {
            if selectedSort == .date {
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
            } else {
                Chart(heatChartPoints) { chartPoint in
                    LineMark(
                        x: .value("Heat", chartPoint.heatIndex),
                        y: .value("Best Lap", chartPoint.point.bestLap)
                    )
                    .interpolationMethod(.catmullRom)
                    .foregroundStyle(.orange)

                    PointMark(
                        x: .value("Heat", chartPoint.heatIndex),
                        y: .value("Best Lap", chartPoint.point.bestLap)
                    )
                    .foregroundStyle(.orange)
                    .annotation(position: .top, spacing: 4) {
                        Text(format(chartPoint.point.bestLap))
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                .chartXScale(domain: heatXDomain)
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

    private func extractHeatNumber(from text: String?) -> Int? {
        guard let text else { return nil }
        let matches = text.matches(of: /(\d+)/)
        guard let last = matches.last else { return nil }
        return Int(last.1)
    }

    private var primaryCountLabel: String {
        if selectedSort == .date {
            return "Days"
        }
        return selectedSource == .timeTrials ? "Heats" : "Race Sessions"
    }

    private var emptyStateDescription: String {
        if selectedSource == .timeTrials {
            return "Record some sessions with \(selectedCombo.displayName) to see your progression."
        }

        if let selectedRaceTrack {
            return "No race sessions found for \(selectedRaceTrack.rawValue)."
        }

        return "Seed race CSV data to see race progression."
    }
}

// MARK: - Chart Data Point

private struct DayPoint: Identifiable {
    let id = UUID()
    let date: Date
    let heatNumber: Int?
    let averageLap: TimeInterval
    let bestLap: TimeInterval
    let sessionCount: Int
}

private struct ChartPoint: Identifiable {
    let point: DayPoint
    let heatIndex: Int

    var id: UUID { point.id }
}

enum ProgressionSort: String, CaseIterable, Identifiable {
    case date
    case heat

    var id: String { rawValue }

    var label: String {
        switch self {
        case .date:
            return "Date"
        case .heat:
            return "Heat"
        }
    }
}

enum ProgressionSource: String, CaseIterable, Identifiable {
    case timeTrials
    case races

    var id: String { rawValue }

    var label: String {
        switch self {
        case .timeTrials:
            return "Time Trials"
        case .races:
            return "Races"
        }
    }
}

#Preview {
    ProgressionView()
}
