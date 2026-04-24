import SwiftUI

struct DashboardView: View {
    @Binding var selectedTab: AppTab

    private let standaloneHeats = SampleData.standaloneHeats
    private let races = SampleData.races

    private var raceHeats: [Heat] {
        races
            .flatMap(\.heats)
            .sorted { $0.date > $1.date }
    }

    private var allHeats: [Heat] {
        (standaloneHeats + raceHeats).sorted { $0.date > $1.date }
    }

    private var latestHeat: Heat? {
        allHeats.first
    }

    private var allLaps: [Lap] {
        allHeats.flatMap(\.laps)
    }

    private var rankedLaps: [RankedLap] {
        allHeats
            .flatMap { heat in
                heat.laps.map { lap in
                    RankedLap(
                        id: lap.id,
                        duration: lap.duration,
                        timestamp: heat.date,
                        trackName: heat.track.rawValue,
                        heatType: heat.type.label
                    )
                }
            }
            .sorted { $0.duration < $1.duration }
    }

    private var bestLap: RankedLap? {
        rankedLaps.first
    }

    private var consistencyValue: TimeInterval? {
        let values = allLaps.map(\.duration)
        guard values.count > 1 else { return nil }
        let average = values.reduce(0, +) / Double(values.count)
        let variance = values.reduce(0) { partial, value in
            let diff = value - average
            return partial + (diff * diff)
        } / Double(values.count)
        return sqrt(variance)
    }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    header
                    latestSessionSection
                    personalBestsSection
                    recentLapsSection
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 24)
            }
            .appScreenBackground()
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { EmptyView() }
        }
    }

    private var header: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                (
                    Text("Go")
                        .foregroundStyle(.white)
                    + Text("Karting")
                        .foregroundStyle(.red)
                )
                .font(.system(.largeTitle, design: .rounded, weight: .bold))

                Text("Track your speed. Beat your best.")
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var topNavigation: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                navChip(title: "Dashboard", icon: "square.grid.2x2", tab: .dashboard)
                navChip(title: "Sessions", icon: "clock", tab: .session)
                navChip(title: "Races", icon: "flag", tab: .races)
                navChip(title: "Progress", icon: "chart.line.uptrend.xyaxis", tab: .progression)
            }
            .padding(.vertical, 2)
        }
    }

    private var newSessionAction: some View {
        Button {
            selectedTab = .timeTrials
        } label: {
            Label("New Session", systemImage: "stopwatch.fill")
                .font(.headline)
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .tint(.red)
        .controlSize(.large)
    }

    private func navChip(title: String, icon: String, tab: AppTab) -> some View {
        Button {
            selectedTab = tab
        } label: {
            Label(title, systemImage: icon)
                .font(.subheadline.weight(.semibold))
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .foregroundStyle(selectedTab == tab ? Color.white : Color.primary)
        }
        .buttonStyle(.plain)
        .glassCapsuleBackground(accented: selectedTab == tab)
    }

    private var latestSessionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(title: "Latest Session", action: {
                selectedTab = .session
            })

            if let latestHeat {
                VStack(alignment: .leading, spacing: 14) {
                    HStack(spacing: 12) {
                        Image(systemName: "point.topleft.down.curvedto.point.bottomright.up")
                            .font(.title3)
                            .foregroundStyle(.red)
                            .frame(width: 44, height: 44)
                            .glassRoundedBackground(radius: 12)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(latestHeat.track.rawValue)
                                .font(.headline)
                            Text(latestHeat.kart.rawValue)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        Text(latestHeat.date.formatted(date: .abbreviated, time: .omitted))
                            .font(.subheadline.weight(.medium))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .glassCapsuleBackground(accented: false)
                    }

                    Divider()

                    HStack(spacing: 12) {
                        metric(title: "Best", value: formatLapTime(latestHeat.bestLap), highlight: true)
                        metric(title: "Avg", value: formatLapTime(latestHeat.averageLap), highlight: false)
                        metric(title: "Laps", value: "\(latestHeat.lapCount)", highlight: false)
                    }

                    Button {
                        selectedTab = .session
                    } label: {
                        Text("View Session")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.red)
                    .controlSize(.large)
                }
                .padding(16)
                .glassCard()
            } else {
                Text("No session data yet")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .glassCard()
            }
        }
    }

    private var personalBestsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(title: "Personal Bests", action: {
                selectedTab = .progression
            })

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 110), spacing: 10)], spacing: 10) {
                statCard(icon: "stopwatch", title: "Best Lap", value: formatLapTime(bestLap?.duration), detail: bestLap?.timestamp.formatted(date: .abbreviated, time: .omitted) ?? "No data")
                statCard(icon: "waveform.path.ecg", title: "Consistency", value: formatLapTime(consistencyValue), detail: "StdDev")
                statCard(icon: "number", title: "Total Laps", value: "\(allLaps.count)", detail: "All sessions")
            }
        }
    }

    private var recentLapsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(title: "Recent Laps", action: {
                selectedTab = .timeTrials
            })

            VStack(spacing: 8) {
                ForEach(Array(rankedLaps.prefix(5).enumerated()), id: \.element.id) { index, lap in
                    HStack(spacing: 12) {
                        Text("#\(index + 1)")
                            .font(.subheadline.bold())
                            .foregroundStyle(index == 0 ? .red : .secondary)
                            .frame(width: 36)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(formatLapTime(lap.duration))
                                .font(.headline)
                                .foregroundStyle(.red)
                            Text(lap.timestamp.formatted(date: .abbreviated, time: .shortened))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        VStack(alignment: .trailing, spacing: 2) {
                            Text(lap.trackName)
                                .font(.subheadline.weight(.medium))
                            Text(lap.heatType)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .glassRoundedBackground(radius: 14)
                }
            }
        }
    }

    private func sectionHeader(title: String, action: @escaping () -> Void) -> some View {
        HStack {
            Text(title)
                .font(.title2.bold())
            Spacer()
            Button("View All", action: action)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.red)
        }
    }

    private func metric(title: String, value: String, highlight: Bool) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.title3.bold())
                .foregroundStyle(highlight ? .red : .primary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func statCard(icon: String, title: String, value: String, detail: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon)
                .font(.headline)
                .foregroundStyle(.red)

            Text(title)
                .font(.subheadline)

            Text(value)
                .font(.headline.bold())
                .foregroundStyle(.red)
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            Text(detail)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity, minHeight: 100, alignment: .topLeading)
        .padding(12)
        .glassCard()
    }

    private func formatLapTime(_ value: TimeInterval?) -> String {
        guard let value else { return "--" }
        return String(format: "%.3fs", value)
    }
}

private struct RankedLap: Identifiable {
    let id: UUID
    let duration: TimeInterval
    let timestamp: Date
    let trackName: String
    let heatType: String
}

#Preview {
    DashboardView(selectedTab: .constant(.dashboard))
}
