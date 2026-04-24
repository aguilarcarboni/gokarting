import SwiftUI
import MapKit

struct LapView: View {
    let lap: Lap
    let heat: Heat
    @State private var lapCameraPosition: MapCameraPosition = .automatic

    private var lapCompetitor: HeatCompetitor {
        heat.competitor(for: lap)
    }

    private var deltaToBest: TimeInterval? {
        guard let best = heat.bestLap(for: lapCompetitor) else { return nil }
        return lap.duration - best
    }

    private var deltaToAverage: TimeInterval? {
        guard let average = heat.averageLap(for: lapCompetitor) else { return nil }
        return lap.duration - average
    }

    private var lapPolyline: [CLLocationCoordinate2D] {
        sanitizedLapRoute.map(\.clCoordinate)
    }

    private var sanitizedLapRoute: [GeoCoordinate] {
        let validPoints = lap.route.filter { point in
            (-90.0 ... 90.0).contains(point.latitude)
            && (-180.0 ... 180.0).contains(point.longitude)
            && !(abs(point.latitude) < 0.000001 && abs(point.longitude) < 0.000001)
        }

        guard validPoints.count > 2 else { return validPoints }

        let avgLatitude = validPoints.map(\.latitude).reduce(0, +) / Double(validPoints.count)
        let avgLongitude = validPoints.map(\.longitude).reduce(0, +) / Double(validPoints.count)
        let center = CLLocation(latitude: avgLatitude, longitude: avgLongitude)

        return validPoints.filter { point in
            let location = CLLocation(latitude: point.latitude, longitude: point.longitude)
            return center.distance(from: location) <= 2_500
        }
    }

    private var startCoordinate: CLLocationCoordinate2D? {
        lapPolyline.first
    }

    private var finishCoordinate: CLLocationCoordinate2D? {
        lapPolyline.last
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 14) {
                headerCard

                card(title: "Lap Metrics") {
                    VStack(spacing: 8) {
                        statRow(title: "Lap Time", value: format(lap.duration))
                        statRow(title: "Delta to Best", value: formatDelta(deltaToBest))
                        statRow(title: "Delta to Avg", value: formatDelta(deltaToAverage))
                        statRow(title: "Timestamp", value: lap.timestamp.formatted(date: .abbreviated, time: .shortened))
                    }
                }

                card(title: "Session Context") {
                    VStack(spacing: 8) {
                        statRow(title: "Heat", value: heat.identifier)
                        statRow(title: "Type", value: heat.type.label)
                        statRow(title: "Competitor", value: lapCompetitor.displayName)
                        statRow(title: "Track", value: lap.track.rawValue)
                        statRow(title: "Kart", value: lap.kart.rawValue)
                        statRow(title: "Total Laps", value: "\(heat.laps(for: lapCompetitor).count)")
                    }
                }

                card(title: "Lap Line") {
                    if lapPolyline.count > 1 {
                        Map(position: $lapCameraPosition, interactionModes: [.zoom, .pan]) {
                            MapPolyline(coordinates: lapPolyline)
                                .stroke(.cyan, lineWidth: 4)

                            if let startCoordinate {
                                Marker("Start", coordinate: startCoordinate)
                                    .tint(.green)
                            }

                            if let finishCoordinate {
                                Marker("Finish", coordinate: finishCoordinate)
                                    .tint(.red)
                            }
                        }
                        .mapStyle(.standard(elevation: .realistic))
                        .mapControls {
                            MapCompass()
                            MapScaleView()
                        }
                        .frame(height: 220)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    } else {
                        Text("No valid lap route available for this lap.")
                            .foregroundStyle(.secondary)
                    }
                }

                if lap.telemetry != nil || lap.speedAtCrossingMPS != nil || lap.crossedAt != nil {
                    card(title: "Telemetry") {
                        VStack(spacing: 8) {
                            if let crossedAt = lap.crossedAt {
                                statRow(title: "Crossed At", value: crossedAt.formatted(date: .abbreviated, time: .shortened))
                            }
                            if let speedAtCrossingMPS = lap.speedAtCrossingMPS {
                                statRow(title: "Crossing Speed", value: String(format: "%.2f m/s", speedAtCrossingMPS))
                            }
                            if let telemetry = lap.telemetry {
                                statRow(title: "Longitudinal Accel", value: String(format: "%.2f g", telemetry.maxLongitudinalAccel))
                                statRow(title: "Lateral Accel", value: String(format: "%.2f g", telemetry.maxLateralAccel))
                                statRow(title: "Yaw Rate", value: String(format: "%.2f rad/s", telemetry.maxYawRate))
                                statRow(title: "Avg Speed", value: String(format: "%.2f m/s", telemetry.averageSpeedMPS))
                                statRow(title: "Peak Speed", value: String(format: "%.2f m/s", telemetry.peakSpeedMPS))
                                statRow(title: "Distance", value: String(format: "%.1f m", telemetry.distanceMeters))
                                statRow(title: "Samples", value: "\(telemetry.sampleCount)")
                            }
                        }
                    }
                }

                if lap.driverName != nil || lap.driverNumber != nil || lap.competitorID != nil {
                    card(title: "Driver") {
                        VStack(spacing: 8) {
                            statRow(title: "Driver Name", value: lap.driverName ?? "--")
                            statRow(title: "Driver Number", value: lap.driverNumber ?? "--")
                            statRow(title: "Competitor ID", value: lap.competitorID ?? "--")
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 24)
        }
        .appScreenBackground()
        .navigationTitle("Lap #\(lap.lapNumber)")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if let region = mapRegionForLapRoute() {
                lapCameraPosition = .region(region)
            }
        }
    }

    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: "gauge.with.dots.needle.50percent")
                    .font(.title3)
                    .foregroundStyle(.red)
                    .frame(width: 40, height: 40)
                    .glassRoundedBackground(radius: 12)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Lap \(lap.lapNumber)")
                        .font(.headline)
                        .foregroundStyle(.white)
                    Text(heat.track.rawValue)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Text(format(lap.duration))
                    .font(.subheadline.weight(.semibold))
                    .monospacedDigit()
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .glassCapsuleBackground(accented: true, tint: .red)
            }

            HStack(spacing: 12) {
                metric(title: "Best", value: format(heat.bestLap(for: lapCompetitor)), highlight: true)
                metric(title: "Delta", value: formatDelta(deltaToBest), highlight: false)
                metric(title: "Avg Δ", value: formatDelta(deltaToAverage), highlight: false)
            }
        }
        .padding(16)
        .glassCard()
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
                .lineLimit(1)
            Spacer(minLength: 12)
            Text(value)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white)
                .multilineTextAlignment(.trailing)
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

    private func formatDelta(_ value: TimeInterval?) -> String {
        guard let value else { return "--" }
        return String(format: "%@%.3fs", value >= 0 ? "+" : "-", abs(value))
    }

    private func mapRegionForLapRoute() -> MKCoordinateRegion? {
        guard !sanitizedLapRoute.isEmpty else { return nil }

        let latitudes = sanitizedLapRoute.map(\.latitude)
        let longitudes = sanitizedLapRoute.map(\.longitude)

        guard let minLat = latitudes.min(),
              let maxLat = latitudes.max(),
              let minLon = longitudes.min(),
              let maxLon = longitudes.max() else {
            return nil
        }

        let center = CLLocationCoordinate2D(
            latitude: (minLat + maxLat) / 2,
            longitude: (minLon + maxLon) / 2
        )

        let latDelta = max(0.0008, (maxLat - minLat) * 1.6)
        let lonDelta = max(0.0008, (maxLon - minLon) * 1.6)

        return MKCoordinateRegion(
            center: center,
            span: MKCoordinateSpan(latitudeDelta: latDelta, longitudeDelta: lonDelta)
        )
    }
}

#Preview {
    NavigationStack {
        LapView(
            lap: SampleData.standaloneHeats.first!.laps[0],
            heat: SampleData.standaloneHeats.first!
        )
    }
}
