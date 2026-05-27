import SwiftUI
import Charts
import MapKit

struct AnalysisView: View {
    private struct CompetitorOption: Identifiable, Hashable {
        let id: String
        let label: String
    }

    private struct AnalysisLap: Identifiable, Hashable {
        let id: UUID
        let heat: Heat
        let lap: Lap

        var title: String {
            "\(heat.identifier) • L\(lap.lapNumber)"
        }

        var subtitle: String {
            "\(competitorDisplay) • \(heat.date.formatted(date: .abbreviated, time: .shortened))"
        }

        var competitorDisplay: String {
            if let name = lap.driverName, !name.isEmpty {
                if let number = lap.driverNumber, !number.isEmpty {
                    return "#\(number) \(name)"
                }
                return name
            }
            if let number = lap.driverNumber, !number.isEmpty {
                return "Driver #\(number)"
            }
            return "You"
        }
    }

    private struct TelemetryPoint: Identifiable {
        let id = UUID()
        let lapID: UUID
        let progress: Double
        let value: Double
    }

    @State private var selectedTrack: Track = .formulaKart
    @State private var selectedCompetitorID: String = "all"
    @State private var addedLapIDs: [UUID] = []
    @State private var cameraPosition: MapCameraPosition = .automatic

    private let palette: [Color] = [.red, .blue, .green, .orange]

    private var allHeats: [Heat] {
        SampleData.standaloneHeats + SampleData.races.flatMap(\.heats)
    }

    private var trackLaps: [AnalysisLap] {
        allHeats
            .filter { $0.track == selectedTrack }
            .sorted { $0.date > $1.date }
            .flatMap { heat in
                heat.laps
                    .sorted(by: { $0.lapNumber < $1.lapNumber })
                    .map { AnalysisLap(id: $0.id, heat: heat, lap: $0) }
            }
    }

    private var competitorOptions: [CompetitorOption] {
        var seen = Set<String>()
        var options: [CompetitorOption] = [CompetitorOption(id: "all", label: "All Competitors")]

        for row in trackLaps {
            let key = competitorKey(for: row.lap)
            guard seen.insert(key).inserted else { continue }
            options.append(CompetitorOption(id: key, label: row.competitorDisplay))
        }
        return options
    }

    private var filteredLibraryLaps: [AnalysisLap] {
        let source: [AnalysisLap]
        if selectedCompetitorID == "all" {
            source = trackLaps
        } else {
            source = trackLaps.filter { competitorKey(for: $0.lap) == selectedCompetitorID }
        }

        // Keep the library practical and bias towards better laps.
        return Array(source.sorted { $0.lap.duration < $1.lap.duration }.prefix(80))
    }

    private var addedLaps: [AnalysisLap] {
        addedLapIDs.compactMap { id in
            filteredLibraryLaps.first(where: { $0.id == id }) ?? trackLaps.first(where: { $0.id == id })
        }
    }

    private var baseLap: AnalysisLap? {
        addedLaps.min(by: { $0.lap.duration < $1.lap.duration })
    }

    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                ScrollView(showsIndicators: false) {
                    if geometry.size.width > 920 {
                        HStack(alignment: .top, spacing: 14) {
                            leftPanel
                                .frame(width: 360)

                            rightPanel
                                .frame(maxWidth: .infinity)
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 12)
                        .padding(.bottom, 24)
                    } else {
                        VStack(alignment: .leading, spacing: 14) {
                            leftPanel
                            rightPanel
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 12)
                        .padding(.bottom, 24)
                    }
                }
            }
            .appScreenBackground()
            .navigationTitle("Analysis")
            .navigationBarTitleDisplayMode(.inline)
            .onChange(of: selectedTrack) { _, _ in
                selectedCompetitorID = "all"
                addedLapIDs.removeAll()
            }
            .onChange(of: selectedCompetitorID) { _, _ in
                addedLapIDs.removeAll()
            }
            .onChange(of: addedLaps.map(\.id)) { _, _ in
                recenterMapIfNeeded()
            }
            .onAppear {
                recenterMapIfNeeded()
            }
        }
    }

    private var leftPanel: some View {
        VStack(alignment: .leading, spacing: 14) {
            card(title: "Workspace") {
                VStack(spacing: 10) {
                    Picker("Track", selection: $selectedTrack) {
                        ForEach(Track.allCases, id: \.self) { track in
                            Text(track.rawValue).tag(track)
                        }
                    }
                    .pickerStyle(.menu)

                    Picker("Competitor", selection: $selectedCompetitorID) {
                        ForEach(competitorOptions) { option in
                            Text(option.label).tag(option.id)
                        }
                    }
                    .pickerStyle(.menu)

                    HStack {
                        Text("Added laps")
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text("\(addedLaps.count)/4")
                            .font(.subheadline.weight(.semibold))
                            .monospacedDigit()
                    }
                    .font(.subheadline)
                }
            }

            card(title: "Added Laps") {
                if addedLaps.isEmpty {
                    Text("Add at least 2 laps to compare.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } else {
                    VStack(spacing: 8) {
                        ForEach(Array(addedLaps.enumerated()), id: \.element.id) { index, row in
                            HStack(spacing: 8) {
                                Circle()
                                    .fill(color(for: row.id, fallbackIndex: index))
                                    .frame(width: 10, height: 10)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(row.title)
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundStyle(.white)
                                        .lineLimit(1)
                                    Text(row.lap.duration.formattedLap)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }

                                Spacer()

                                if row.id == baseLap?.id {
                                    Text("BASE")
                                        .font(.caption2.weight(.bold))
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 3)
                                        .glassCapsuleBackground(accented: true, tint: .red)
                                }

                                Button {
                                    removeLap(row.id)
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundStyle(.secondary)
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 8)
                            .glassRoundedBackground(radius: 12)
                        }
                    }
                }
            }

            card(title: "Lap Library") {
                VStack(spacing: 8) {
                    ForEach(filteredLibraryLaps.prefix(35)) { row in
                        HStack(spacing: 8) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(row.title)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(.white)
                                    .lineLimit(1)
                                Text(row.subtitle)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                            }

                            Spacer()

                            Text(row.lap.duration.formattedLap)
                                .font(.caption.weight(.semibold))
                                .monospacedDigit()
                                .foregroundStyle(.secondary)

                            Button {
                                toggleLap(row.id)
                            } label: {
                                Image(systemName: addedLapIDs.contains(row.id) ? "checkmark.circle.fill" : "plus.circle")
                                    .foregroundStyle(addedLapIDs.contains(row.id) ? .red : .secondary)
                                    .font(.title3)
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 8)
                        .glassRoundedBackground(radius: 12)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var rightPanel: some View {
        VStack(alignment: .leading, spacing: 14) {
            card(title: "Lap Delta") {
                if let baseLap, addedLaps.count >= 2 {
                    VStack(spacing: 8) {
                        ForEach(addedLaps) { row in
                            let delta = row.lap.duration - baseLap.lap.duration
                            HStack {
                                Circle()
                                    .fill(color(for: row.id, fallbackIndex: 0))
                                    .frame(width: 10, height: 10)
                                Text(row.title)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                                Spacer()
                                Text(formatDelta(delta))
                                    .font(.subheadline.weight(.semibold))
                                    .monospacedDigit()
                                    .foregroundStyle(delta <= 0 ? .green : .red)
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 8)
                            .glassRoundedBackground(radius: 12)
                        }
                    }
                } else {
                    Text("Add at least 2 laps.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            card(title: "Line Overlay") {
                if addedLaps.isEmpty {
                    Text("No lap lines selected.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } else {
                    Map(position: $cameraPosition, interactionModes: [.zoom, .pan]) {
                        ForEach(Array(addedLaps.enumerated()), id: \.element.id) { index, row in
                            let points = sanitizedRoute(for: row.lap)
                            if points.count > 1 {
                                MapPolyline(coordinates: points)
                                    .stroke(color(for: row.id, fallbackIndex: index), lineWidth: 4)
                            }
                        }
                    }
                    .mapStyle(.imagery(elevation: .realistic))
                    .frame(height: 300)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }

            telemetryCard(
                title: "Speed (m/s)",
                extractor: { $0.speedMPS }
            )

            telemetryCard(
                title: "Lateral G",
                extractor: { Optional($0.accelerationY) }
            )

            telemetryCard(
                title: "Yaw Rate (rad/s)",
                extractor: { Optional($0.yawRate) }
            )
        }
    }

    private func telemetryCard(
        title: String,
        extractor: @escaping (LapMotionSample) -> Double?
    ) -> some View {
        card(title: title) {
            let series = telemetrySeries(extractor: extractor)
            if series.isEmpty {
                Text("No telemetry for selected laps.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                Chart(series) { point in
                    LineMark(
                        x: .value("Progress", point.progress),
                        y: .value("Value", point.value)
                    )
                    .interpolationMethod(.linear)
                    .foregroundStyle(color(for: point.lapID, fallbackIndex: 0))
                }
                .frame(height: 190)
            }
        }
    }

    private func telemetrySeries(
        extractor: (LapMotionSample) -> Double?
    ) -> [TelemetryPoint] {
        addedLaps.flatMap { row in
            normalizedTelemetryPoints(samples: row.lap.motionSamples ?? [], lapID: row.id, extractor: extractor)
        }
    }

    private func normalizedTelemetryPoints(
        samples: [LapMotionSample],
        lapID: UUID,
        extractor: (LapMotionSample) -> Double?
    ) -> [TelemetryPoint] {
        guard let start = samples.first?.timestamp,
              let end = samples.last?.timestamp,
              end > start else { return [] }

        let duration = end.timeIntervalSince(start)

        return samples.compactMap { sample in
            guard let value = extractor(sample) else { return nil }
            let t = sample.timestamp.timeIntervalSince(start)
            return TelemetryPoint(
                lapID: lapID,
                progress: min(max(t / duration, 0), 1),
                value: value
            )
        }
    }

    private func toggleLap(_ lapID: UUID) {
        if addedLapIDs.contains(lapID) {
            removeLap(lapID)
            return
        }
        guard addedLapIDs.count < 4 else { return }
        addedLapIDs.append(lapID)
    }

    private func removeLap(_ lapID: UUID) {
        addedLapIDs.removeAll { $0 == lapID }
    }

    private func competitorKey(for lap: Lap) -> String {
        if let competitorID = lap.competitorID, !competitorID.isEmpty {
            return "id:\(competitorID)"
        }
        if let driverNumber = lap.driverNumber, !driverNumber.isEmpty {
            return "num:\(driverNumber)"
        }
        if let driverName = lap.driverName, !driverName.isEmpty {
            return "name:\(driverName)"
        }
        return "you"
    }

    private func color(for lapID: UUID, fallbackIndex: Int) -> Color {
        if let index = addedLapIDs.firstIndex(of: lapID) {
            return palette[index % palette.count]
        }
        return palette[fallbackIndex % palette.count]
    }

    private func sanitizedRoute(for lap: Lap) -> [CLLocationCoordinate2D] {
        let raw = lap.route.filter { point in
            (-90.0...90.0).contains(point.latitude)
            && (-180.0...180.0).contains(point.longitude)
            && !(abs(point.latitude) < 0.000001 && abs(point.longitude) < 0.000001)
        }

        return raw.map(\.clCoordinate)
    }

    private func recenterMapIfNeeded() {
        let coords = addedLaps.flatMap { sanitizedRoute(for: $0.lap) }
        guard !coords.isEmpty else { return }

        let lats = coords.map(\.latitude)
        let lons = coords.map(\.longitude)

        guard let minLat = lats.min(), let maxLat = lats.max(), let minLon = lons.min(), let maxLon = lons.max() else {
            return
        }

        let center = CLLocationCoordinate2D(
            latitude: (minLat + maxLat) / 2,
            longitude: (minLon + maxLon) / 2
        )

        let span = MKCoordinateSpan(
            latitudeDelta: max(0.0008, (maxLat - minLat) * 1.6),
            longitudeDelta: max(0.0008, (maxLon - minLon) * 1.6)
        )

        cameraPosition = .region(MKCoordinateRegion(center: center, span: span))
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

    private func formatDelta(_ value: TimeInterval) -> String {
        String(format: "%@%.3fs", value >= 0 ? "+" : "-", abs(value))
    }
}

private extension TimeInterval {
    var formattedLap: String {
        String(format: "%.3fs", self)
    }
}

#Preview {
    AnalysisView()
}
