import SwiftUI
import Charts

struct ProgressionView: View {
    private let standaloneHeats = SampleData.standaloneHeats
    private let races = SampleData.races

    @State private var selectedSource: ProgressionSource
    @State private var selectedSort: ProgressionSort = .date
    @State private var selectedCombo: TrackKartCombo
    @State private var selectedRaceTrack: Track? = nil

    init(initialSource: ProgressionSource = .timeTrials) {
        let defaultCombo = SampleData.standaloneHeats.first.map { TrackKartCombo(track: $0.track, kart: $0.kart) }
            ?? TrackKartCombo.allCases.first
            ?? TrackKartCombo(track: .fik, kart: .fikKart)
        _selectedSource = State(initialValue: initialSource)
        _selectedCombo = State(initialValue: defaultCombo)
    }

    private var availableTimeTrialCombos: [TrackKartCombo] {
        let combos = Set(standaloneHeats.map { TrackKartCombo(track: $0.track, kart: $0.kart) })
        return combos.sorted { $0.displayName < $1.displayName }
    }

    private var raceHeats: [Heat] {
        races.flatMap(\.heats).filter { $0.type == .race }
    }

    private var filteredTimeTrialHeats: [Heat] {
        standaloneHeats
            .filter { $0.track == selectedCombo.track && $0.kart == selectedCombo.kart }
            .filter { !$0.laps.isEmpty }
    }

    private var filteredRaceHeats: [Heat] {
        raceHeats
            .filter { selectedRaceTrack == nil || $0.track == selectedRaceTrack }
            .filter { $0.bestLap != nil }
    }

    private var timeTrialChartData: [DayPoint] {
        filteredTimeTrialHeats.compactMap { heat in
            guard let averageLap = heat.averageLap, let bestLap = heat.bestLap else { return nil }
            return DayPoint(
                date: heat.date,
                heatNumber: extractHeatNumber(from: heat.identifier),
                averageLap: averageLap,
                bestLap: bestLap,
                sessionCount: 1
            )
        }
    }

    private var raceChartData: [DayPoint] {
        filteredRaceHeats.compactMap { heat in
            guard let bestLap = heat.bestLap else { return nil }
            return DayPoint(
                date: heat.date,
                heatNumber: extractHeatNumber(from: heat.identifier),
                averageLap: bestLap,
                bestLap: bestLap,
                sessionCount: 1
            )
        }
    }

    private var availableRaceTracks: [Track] {
        let trackSet = Set(raceHeats.map(\.track))
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
            ChartPoint(point: point, heatIndex: index + 1)
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
                            ForEach(availableTimeTrialCombos) { combo in
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
            return "No sessions found for \(selectedCombo.displayName)."
        }

        if let selectedRaceTrack {
            return "No race sessions found for \(selectedRaceTrack.rawValue)."
        }

        return "No race sessions found in SampleData."
    }
}

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
