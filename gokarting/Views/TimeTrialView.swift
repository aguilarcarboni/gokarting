import SwiftUI

struct SessionsView: View {
    @State private var selectedMode: SessionsMode = .timeTrials
    @State private var selectedCombo: TrackKartCombo? = nil
    @State private var selectedRange: HistoryRange = .all

    private var timeTrials: [Heat] {
        SampleData.standaloneHeats
            .filter { $0.type == .timeTrial }
            .sorted { $0.date > $1.date }
    }

    private var raceEvents: [Race] {
        SampleData.races
    }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Sessions")
                            .font(.system(.largeTitle, design: .rounded, weight: .bold))
                            .foregroundStyle(.white)

                        Text("Browse Time Trials or Race sessions.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    modeControls
                    filterControls

                    if selectedMode == .timeTrials {
                        timeTrialContent
                    } else {
                        raceContent
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 24)
            }
            .appScreenBackground()
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private var modeControls: some View {
        HStack(spacing: 10) {
            modeChip(for: .timeTrials)
            modeChip(for: .races)
        }
    }

    private func modeChip(for mode: SessionsMode) -> some View {
        Button {
            selectedMode = mode
        } label: {
            Label(mode.title, systemImage: mode.icon)
                .font(.subheadline.weight(.semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .foregroundStyle(selectedMode == mode ? Color.white : Color.primary)
        }
        .buttonStyle(.plain)
        .glassCapsuleBackground(accented: selectedMode == mode)
    }

    private var filterControls: some View {
        HStack(spacing: 10) {
            Menu {
                Picker("Combo", selection: $selectedCombo) {
                    Text("All Combos").tag(Optional<TrackKartCombo>.none)
                    ForEach(availableCombos) { combo in
                        Text(combo.displayName).tag(Optional(combo))
                    }
                }
            } label: {
                Label(
                    selectedCombo?.displayName ?? "All Combos",
                    systemImage: selectedMode == .timeTrials ? "stopwatch" : "flag"
                )
                .font(.subheadline.weight(.semibold))
                .lineLimit(1)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .glassCapsuleBackground(accented: false)
            }

            Menu {
                Picker("Range", selection: $selectedRange) {
                    ForEach(HistoryRange.allCases) { range in
                        Text(range.label).tag(range)
                    }
                }
            } label: {
                Label(selectedRange.label, systemImage: "calendar")
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(1)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .glassCapsuleBackground(accented: false)
            }
        }
    }

    @ViewBuilder
    private var timeTrialContent: some View {
        if filteredTimeTrials.isEmpty {
            ContentUnavailableView(
                "No Time Trials",
                systemImage: "stopwatch",
                description: Text("Try a different range or track/kart combo.")
            )
            .frame(maxWidth: .infinity)
            .padding(.vertical, 32)
        } else {
            LazyVStack(spacing: 12) {
                ForEach(filteredTimeTrials) { heat in
                    NavigationLink {
                        HeatView(heat: heat)
                    } label: {
                        TimeTrialCard(heat: heat)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    @ViewBuilder
    private var raceContent: some View {
        if filteredRaces.isEmpty {
            ContentUnavailableView(
                "No Races",
                systemImage: "flag",
                description: Text("Try a different range or track/kart combo.")
            )
            .frame(maxWidth: .infinity)
            .padding(.vertical, 32)
        } else {
            LazyVStack(spacing: 12) {
                ForEach(filteredRaces) { race in
                    NavigationLink {
                        RaceView(race: race)
                    } label: {
                        RaceEventCard(race: race)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var availableCombos: [TrackKartCombo] {
        let combos: Set<TrackKartCombo>

        if selectedMode == .timeTrials {
            combos = Set(timeTrials.map { TrackKartCombo(track: $0.track, kart: $0.kart) })
        } else {
            combos = Set(raceEvents.map { TrackKartCombo(track: $0.track, kart: $0.kart) })
        }

        return combos.sorted { $0.displayName < $1.displayName }
    }

    private var filteredTimeTrials: [Heat] {
        timeTrials.filter { heat in
            let comboMatches = selectedCombo == nil || (heat.track == selectedCombo?.track && heat.kart == selectedCombo?.kart)
            let rangeMatches = selectedRange.contains(heat.date)
            return comboMatches && rangeMatches
        }
    }

    private var filteredRaces: [Race] {
        raceEvents
            .filter { race in
                let comboMatches = selectedCombo == nil || (race.track == selectedCombo?.track && race.kart == selectedCombo?.kart)
                let rangeMatches = selectedRange.contains(latestRaceDate(for: race) ?? .distantPast)
                return comboMatches && rangeMatches
            }
            .sorted { (latestRaceDate(for: $0) ?? .distantPast) > (latestRaceDate(for: $1) ?? .distantPast) }
    }

    private func latestRaceDate(for race: Race) -> Date? {
        race.heats.map(\.date).max()
    }
}

struct RaceView: View {
    let race: Race

    private var sortedHeats: [Heat] {
        race.heats.sorted(by: { $0.date > $1.date })
    }

    private var bestLap: TimeInterval? {
        sortedHeats.compactMap(\.bestLap).min()
    }

    private var totalLaps: Int {
        sortedHeats.reduce(0) { $0 + $1.lapCount }
    }

    private var raceDate: Date? {
        sortedHeats.map(\.date).max()
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 14) {
                raceSummaryCard

                if sortedHeats.isEmpty {
                    ContentUnavailableView(
                        "No Race Heats",
                        systemImage: "flag.checkered",
                        description: Text("This race does not have any heats yet.")
                    )
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 32)
                } else {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Race Heats")
                            .font(.title3.weight(.bold))
                            .foregroundStyle(.white)

                        LazyVStack(spacing: 12) {
                            ForEach(sortedHeats) { heat in
                                NavigationLink {
                                    HeatView(heat: heat)
                                } label: {
                                    RaceHeatCard(heat: heat)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 24)
        }
        .appScreenBackground()
        .navigationTitle("Race")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var raceSummaryCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                Image(systemName: "flag.fill")
                    .font(.title3)
                    .foregroundStyle(.red)
                    .frame(width: 40, height: 40)
                    .glassRoundedBackground(radius: 12)

                VStack(alignment: .leading, spacing: 2) {
                    Text(race.track.rawValue)
                        .font(.headline)
                        .foregroundStyle(.white)
                    Text(race.kart.rawValue)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                if let raceDate {
                    Text(raceDate.formatted(date: .abbreviated, time: .omitted))
                        .font(.caption.weight(.medium))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .glassCapsuleBackground(accented: false)
                }
            }

            Divider()

            HStack(spacing: 12) {
                raceMetric(title: "Heats", value: "\(sortedHeats.count)", highlight: false)
                raceMetric(title: "Best", value: format(bestLap), highlight: true)
                raceMetric(title: "Laps", value: "\(totalLaps)", highlight: false)
            }
        }
        .padding(16)
        .glassCard()
    }

    private func raceMetric(title: String, value: String, highlight: Bool) -> some View {
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
}

private struct TimeTrialCard: View {
    let heat: Heat

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                Image(systemName: "stopwatch.fill")
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

            Divider()

            HStack(spacing: 12) {
                metric(title: "Best", value: format(heat.bestLap), highlight: true)
                metric(title: "Avg", value: format(heat.averageLap), highlight: false)
                metric(title: "Laps", value: "\(heat.lapCount)", highlight: false)
            }

            HStack {
                Text("Open Heat")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption.bold())
                    .foregroundStyle(.white.opacity(0.85))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .glassCapsuleBackground(accented: true, tint: .red)
        }
        .padding(16)
        .glassCard()
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
}

private struct RaceEventCard: View {
    let race: Race

    private var sortedHeats: [Heat] {
        race.heats.sorted(by: { $0.date > $1.date })
    }

    private var bestLap: TimeInterval? {
        sortedHeats.compactMap(\.bestLap).min()
    }

    private var raceDate: Date? {
        sortedHeats.map(\.date).max()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                Image(systemName: "flag.fill")
                    .font(.title3)
                    .foregroundStyle(.red)
                    .frame(width: 40, height: 40)
                    .glassRoundedBackground(radius: 12)

                VStack(alignment: .leading, spacing: 2) {
                    Text(race.track.rawValue)
                        .font(.headline)
                        .foregroundStyle(.white)
                    Text(race.kart.rawValue)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                if let raceDate {
                    Text(raceDate.formatted(date: .abbreviated, time: .omitted))
                        .font(.caption.weight(.medium))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .glassCapsuleBackground(accented: false)
                }
            }

            Divider()

            HStack(spacing: 12) {
                raceMetric(title: "Heats", value: "\(sortedHeats.count)", highlight: false)
                raceMetric(title: "Best", value: format(bestLap), highlight: true)
                raceMetric(title: "Laps", value: "\(sortedHeats.reduce(0) { $0 + $1.lapCount })", highlight: false)
            }

            HStack {
                Text("Open Race")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption.bold())
                    .foregroundStyle(.white.opacity(0.85))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .glassCapsuleBackground(accented: true, tint: .red)
        }
        .padding(16)
        .glassCard()
    }

    private func raceMetric(title: String, value: String, highlight: Bool) -> some View {
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
}

private struct RaceHeatCard: View {
    let heat: Heat

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: heat.type == .quali ? "clock.badge.checkmark" : "flag.checkered")
                    .font(.title3)
                    .foregroundStyle(.red)
                    .frame(width: 40, height: 40)
                    .glassRoundedBackground(radius: 12)

                VStack(alignment: .leading, spacing: 2) {
                    Text(heat.type.label)
                        .font(.headline)
                        .foregroundStyle(.white)
                    Text(heat.identifier)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                Spacer()

                Text(heat.date.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption.weight(.medium))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .glassCapsuleBackground(accented: false)
            }

            Divider()

            HStack(spacing: 12) {
                heatMetric(title: "Best", value: format(heat.bestLap), highlight: true)
                heatMetric(title: "Avg", value: format(heat.averageLap), highlight: false)
                heatMetric(title: "Laps", value: "\(heat.lapCount)", highlight: false)
            }

            HStack {
                Text("Open Heat")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption.bold())
                    .foregroundStyle(.white.opacity(0.85))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .glassCapsuleBackground(accented: true, tint: .red)
        }
        .padding(16)
        .glassCard()
    }

    private func heatMetric(title: String, value: String, highlight: Bool) -> some View {
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
}

private enum SessionsMode: String, CaseIterable, Identifiable {
    case timeTrials
    case races

    var id: String { rawValue }

    var title: String {
        switch self {
        case .timeTrials:
            return "Time Trials"
        case .races:
            return "Races"
        }
    }

    var icon: String {
        switch self {
        case .timeTrials:
            return "stopwatch"
        case .races:
            return "flag"
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

#Preview {
    SessionsView()
}
