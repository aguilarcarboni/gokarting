import SwiftUI
import Charts

struct HeatView: View {
    let heat: Heat
    @State private var selectedCompetitorID: String?

    init(heat: Heat) {
        self.heat = heat
        _selectedCompetitorID = State(initialValue: heat.sortedCompetitorsForHeatType().first?.id)
    }

    private var competitors: [HeatCompetitor] {
        heat.sortedCompetitorsForHeatType()
    }

    private var activeCompetitor: HeatCompetitor? {
        if let selectedCompetitorID,
           let competitor = competitors.first(where: { $0.id == selectedCompetitorID }) {
            return competitor
        }
        return competitors.first
    }

    private var sortedLaps: [Lap] {
        guard let activeCompetitor else { return [] }
        return heat.laps(for: activeCompetitor).sorted(by: { $0.lapNumber < $1.lapNumber })
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 14) {
                headerCard
                competitorCard

                card(title: "Lap Progression") {
                    Chart(sortedLaps) { lap in
                        LineMark(
                            x: .value("Lap", lap.lapNumber),
                            y: .value("Time", lap.duration)
                        )
                        .interpolationMethod(.catmullRom)
                        .foregroundStyle(.red)

                        PointMark(
                            x: .value("Lap", lap.lapNumber),
                            y: .value("Time", lap.duration)
                        )
                        .foregroundStyle(.white)
                    }
                    .frame(height: 220)
                    .chartYScale(domain: .automatic(includesZero: false))
                }

                card(title: "Stats") {
                    VStack(spacing: 8) {
                        statRow(title: "Competitor", value: activeCompetitor?.displayName ?? "--")
                        statRow(title: "Track", value: heat.track.rawValue)
                        statRow(title: "Kart", value: heat.kart.rawValue)
                        statRow(title: "Best Lap", value: format(heat.bestLap(for: activeCompetitor)))
                        statRow(title: "Avg Lap", value: format(heat.averageLap(for: activeCompetitor)))
                        statRow(title: "Median Lap", value: format(heat.medianLap(for: activeCompetitor)))
                        statRow(title: "Consistency (StdDev)", value: format(heat.consistency(for: activeCompetitor)))
                        statRow(title: "Opening Pace (First 5)", value: format(heat.firstLapsAverage(for: activeCompetitor, count: 5)))
                        statRow(title: "Closing Pace (Last 5)", value: format(heat.lastLapsAverage(for: activeCompetitor, count: 5)))
                    }
                }

                if let metadata = heat.sessionMetadata {
                    card(title: "Session Telemetry") {
                        VStack(spacing: 8) {
                            statRow(title: "Source", value: metadata.source)
                            statRow(title: "Direction", value: metadata.raceDirection.rawValue)
                            statRow(title: "Duration", value: format(metadata.durationSeconds))
                            statRow(title: "Samples", value: "\(metadata.sampleCount)")
                            statRow(title: "Gate Crossings", value: "\(metadata.gateCrossingsCount)")
                            statRow(title: "Distance", value: String(format: "%.1f m", metadata.totalDistanceMeters))
                            statRow(title: "Average Speed", value: String(format: "%.2f m/s", metadata.averageSpeedMPS))
                            statRow(title: "Peak Speed", value: String(format: "%.2f m/s", metadata.peakSpeedMPS))
                            statRow(title: "Peak Accel", value: String(format: "%.2f g", metadata.peakAccelerationG))
                            statRow(title: "Peak Decel", value: String(format: "%.2f g", metadata.peakDecelerationG))
                            statRow(title: "Peak Yaw", value: String(format: "%.2f rad/s", metadata.peakYawRate))
                        }
                    }
                }

                card(title: "Laps") {
                    VStack(spacing: 8) {
                        ForEach(sortedLaps) { lap in
                            NavigationLink {
                                LapView(lap: lap, heat: heat)
                            } label: {
                                HStack(spacing: 10) {
                                    Text("#\(lap.lapNumber)")
                                        .font(.caption.weight(.semibold))
                                        .foregroundStyle(.secondary)
                                        .frame(width: 34)

                                    Text(format(lap.duration))
                                        .font(.body.weight(.semibold))
                                        .monospacedDigit()

                                    Spacer()

                                    if lap.duration == heat.bestLap(for: activeCompetitor) {
                                        Label("Best", systemImage: "trophy.fill")
                                            .font(.caption.weight(.semibold))
                                            .foregroundStyle(.yellow)
                                    }

                                    Image(systemName: "chevron.right")
                                        .font(.caption.bold())
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .buttonStyle(.plain)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 8)
                            .glassRoundedBackground(radius: 12)
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 24)
        }
        .appScreenBackground()
        .navigationTitle("Heat")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: "flag.checkered")
                    .font(.title3)
                    .foregroundStyle(.red)
                    .frame(width: 40, height: 40)
                    .glassRoundedBackground(radius: 12)

                VStack(alignment: .leading, spacing: 2) {
                    Text(heat.track.rawValue)
                        .font(.headline)
                        .foregroundStyle(.white)
                    Text(heat.kart.rawValue)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Text(heat.date.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption.weight(.medium))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .glassCapsuleBackground(accented: false)
            }

            Text(heat.identifier)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)

            HStack(spacing: 12) {
                metric(title: "Best", value: format(heat.bestLap(for: activeCompetitor)), highlight: true)
                metric(title: "Avg", value: format(heat.averageLap(for: activeCompetitor)), highlight: false)
                metric(title: "Laps", value: "\(sortedLaps.count)", highlight: false)
            }
        }
        .padding(16)
        .glassCard()
    }

    @ViewBuilder
    private var competitorCard: some View {
        if heat.type == .timeTrial {
            card(title: "Competitor") {
                HStack {
                    Text("You")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                    Spacer()
                    Label("Time Trial", systemImage: "person.fill")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.red)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 10)
                .glassRoundedBackground(radius: 12)
            }
        } else if !competitors.isEmpty {
            card(title: "Competitor") {
                VStack(spacing: 8) {
                    ForEach(Array(competitors.enumerated()), id: \.element.id) { index, competitor in
                        Button {
                            selectedCompetitorID = competitor.id
                        } label: {
                            HStack(spacing: 10) {
                                Text("#\(index + 1)")
                                    .font(.caption.bold())
                                    .foregroundStyle(.secondary)
                                    .frame(width: 30, alignment: .leading)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(competitor.displayName)
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundStyle(.white)
                                        .lineLimit(1)

                                    Text(leaderboardDetail(for: competitor))
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }

                                Spacer()

                                Image(systemName: (selectedCompetitorID ?? competitors.first?.id) == competitor.id ? "checkmark.circle.fill" : "circle")
                                    .foregroundStyle((selectedCompetitorID ?? competitors.first?.id) == competitor.id ? .red : .secondary)
                            }
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 10)
                        .glassRoundedBackground(radius: 12)
                    }
                }
            }
        }
    }

    private func leaderboardDetail(for competitor: HeatCompetitor) -> String {
        switch heat.type {
        case .race:
            let laps = heat.laps(for: competitor).count
            let total = heat.laps(for: competitor).reduce(0) { $0 + $1.duration }
            return "\(laps) laps • \(format(total)) total"
        case .quali, .timeTrial, .practice:
            return "Best: \(format(heat.bestLap(for: competitor)))"
        }
    }

    private func card<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.headline)
                .foregroundStyle(.white)

            content()
        }
        .padding(16)
        .glassCard()
    }

    private func statRow(title: String, value: String) -> some View {
        HStack(spacing: 8) {
            Text(title)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white)
                .monospacedDigit()
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .glassRoundedBackground(radius: 12)
    }

    private func metric(title: String, value: String, highlight: Bool) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.title3.weight(.semibold))
                .monospacedDigit()
                .foregroundStyle(highlight ? Color.red : Color.white)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func format(_ value: TimeInterval?) -> String {
        guard let value else { return "--" }
        return String(format: "%.3fs", value)
    }

    private func format(_ value: TimeInterval) -> String {
        String(format: "%.3fs", value)
    }
}

#Preview {
    NavigationStack {
        HeatView(heat: SampleData.standaloneHeats.first!)
    }
}
