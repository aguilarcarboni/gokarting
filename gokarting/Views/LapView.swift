import SwiftUI
import MapKit
import Charts

struct LapView: View {
    let lap: Lap
    let heat: Heat
    @State private var lapCameraPosition: MapCameraPosition = .automatic
    @State private var selectedTelemetryTime: Double?

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

    private var trackLayoutPolyline: [CLLocationCoordinate2D] {
        lap.track.layout?.centerline.map(\.clCoordinate) ?? []
    }

    private var sanitizedLapRoute: [GeoCoordinate] {
        let sanitizedMotionRoute = sanitizeRoute(motionDerivedRoute)
        let sanitizedRecordedRoute = sanitizeRoute(lap.route)

        if sanitizedMotionRoute.count >= 2 {
            return sanitizedMotionRoute
        }
        return sanitizedRecordedRoute
    }

    private func sanitizeRoute(_ route: [GeoCoordinate]) -> [GeoCoordinate] {
        let validPoints = route.filter { point in
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

    private var motionDerivedRoute: [GeoCoordinate] {
        let motionCoords = lapMotionSamples.compactMap { sample -> (Date, GeoCoordinate)? in
            guard let latitude = sample.latitude, let longitude = sample.longitude else { return nil }
            return (sample.timestamp, GeoCoordinate(latitude: latitude, longitude: longitude))
        }
        guard motionCoords.count > 2 else { return [] }
        return smoothedRoute(from: motionCoords)
    }


    private var startCoordinate: CLLocationCoordinate2D? {
        lapPolyline.first
    }

    private var finishCoordinate: CLLocationCoordinate2D? {
        lapPolyline.last
    }

    private var selectedTelemetryCoordinate: CLLocationCoordinate2D? {
        guard let selectedTelemetryTime else { return nil }
        return telemetryCoordinate(at: selectedTelemetryTime)?.clCoordinate
    }

    private struct TelemetryPoint: Identifiable {
        let id = UUID()
        let t: Double
        let value: Double
    }

    private var lapMotionSamples: [LapMotionSample] {
        lap.motionSamples ?? []
    }

    private var speedSeries: [TelemetryPoint] {
        guard let start = lapMotionSamples.first?.timestamp else { return [] }
        let raw: [TelemetryPoint] = lapMotionSamples.compactMap { sample in
            guard let speed = sample.speedMPS else { return nil }
            return TelemetryPoint(t: sample.timestamp.timeIntervalSince(start), value: speed)
        }
        let deDuplicated = deduplicateAdjacent(raw, epsilon: 0.02)
        let smoothed = movingAverage(deDuplicated, window: 5)
        return downsample(smoothed, maxPoints: 500)
    }

    private var longitudinalAccelSeries: [TelemetryPoint] {
        guard let start = lapMotionSamples.first?.timestamp else { return [] }
        let raw = lapMotionSamples.map { sample in
            TelemetryPoint(t: sample.timestamp.timeIntervalSince(start), value: sample.accelerationX)
        }
        let clipped = clipOutliers(raw, sigma: 2.8)
        let smoothed = movingAverage(clipped, window: 11)
        return downsample(smoothed, maxPoints: 500)
    }

    private var lateralAccelSeries: [TelemetryPoint] {
        guard let start = lapMotionSamples.first?.timestamp else { return [] }
        let raw = lapMotionSamples.map { sample in
            TelemetryPoint(t: sample.timestamp.timeIntervalSince(start), value: sample.accelerationY)
        }
        let clipped = clipOutliers(raw, sigma: 2.8)
        let smoothed = movingAverage(clipped, window: 11)
        return downsample(smoothed, maxPoints: 500)
    }

    private var yawSeries: [TelemetryPoint] {
        guard let start = lapMotionSamples.first?.timestamp else { return [] }
        let raw = lapMotionSamples.map { sample in
            TelemetryPoint(t: sample.timestamp.timeIntervalSince(start), value: sample.yawRate)
        }
        let clipped = clipOutliers(raw, sigma: 2.8)
        let smoothed = movingAverage(clipped, window: 11)
        return downsample(smoothed, maxPoints: 500)
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
                        if let crossedAt = lap.crossedAt {
                            statRow(title: "Crossed At", value: crossedAt.formatted(date: .abbreviated, time: .shortened))
                        }
                        if let speedAtCrossingMPS = lap.speedAtCrossingMPS {
                            statRow(title: "Crossing Speed", value: String(format: "%.2f m/s", speedAtCrossingMPS))
                        }
                        if let confidence = lap.confidenceScore {
                            statRow(title: "Crossing Confidence", value: String(format: "%.0f%%", confidence * 100))
                        }
                        statRow(title: "Recovered Lap", value: (lap.isRecovered ?? false) ? "Yes" : "No")
                        if let suspectReason = lap.suspectReason, !suspectReason.isEmpty {
                            statRow(title: "Lap Flag", value: suspectReason)
                        }
                        if let telemetry = lap.telemetry {
                            statRow(title: "Longitudinal Accel", value: String(format: "%.2f g", telemetry.maxLongitudinalAccel))
                            statRow(title: "Lateral Accel", value: String(format: "%.2f g", telemetry.maxLateralAccel))
                            statRow(title: "Yaw Rate", value: String(format: "%.2f rad/s", telemetry.maxYawRate))
                            statRow(title: "Avg Speed", value: String(format: "%.2f m/s", telemetry.averageSpeedMPS))
                            statRow(title: "Peak Speed", value: String(format: "%.2f m/s", telemetry.peakSpeedMPS))
                            statRow(title: "Distance", value: String(format: "%.1f m", telemetry.distanceMeters))
                            statRow(title: "GPS Samples", value: "\(telemetry.sampleCount)")
                        }
                    }
                }

                card(title: "Lap Line") {
                    if lapPolyline.count > 1 {
                        Map(position: $lapCameraPosition, interactionModes: [.zoom, .pan]) {
                            if !trackLayoutPolyline.isEmpty {
                                MapPolyline(coordinates: trackLayoutPolyline)
                                    .stroke(.white.opacity(0.9), lineWidth: 3)
                            }

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

                            if let selectedTelemetryCoordinate {
                                Marker("Selected", coordinate: selectedTelemetryCoordinate)
                                    .tint(.yellow)
                            }
                        }
                        .mapStyle(.imagery(elevation: .realistic))
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

                if !lapMotionSamples.isEmpty {
                    card(title: "Telemetry Graphs") {
                        VStack(spacing: 12) {
                            if !speedSeries.isEmpty {
                                chartCard(title: "Speed (m/s)") {
                                    Chart {
                                        ForEach(speedSeries) { point in
                                            LineMark(
                                                x: .value("t", point.t),
                                                y: .value("Speed", point.value)
                                            )
                                            .foregroundStyle(.green)
                                            .interpolationMethod(.linear)
                                        }
                                        if let selectedTelemetryTime {
                                            RuleMark(x: .value("Selected", selectedTelemetryTime))
                                                .foregroundStyle(.yellow.opacity(0.7))
                                        }
                                    }
                                    .chartOverlay { proxy in
                                        GeometryReader { geometry in
                                            Rectangle()
                                                .fill(.clear)
                                                .contentShape(Rectangle())
                                                .gesture(
                                                    DragGesture(minimumDistance: 0)
                                                        .onChanged { value in
                                                            let origin = geometry[proxy.plotAreaFrame].origin
                                                            let x = value.location.x - origin.x
                                                            if let t: Double = proxy.value(atX: x) {
                                                                selectedTelemetryTime = max(0, t)
                                                            }
                                                        }
                                                )
                                        }
                                    }
                                    .frame(height: 150)
                                }
                            }

                            chartCard(title: "Longitudinal G") {
                                Chart {
                                    ForEach(longitudinalAccelSeries) { point in
                                        LineMark(
                                            x: .value("t", point.t),
                                            y: .value("Longitudinal G", point.value)
                                        )
                                        .foregroundStyle(.red)
                                        .interpolationMethod(.linear)
                                    }
                                    if let selectedTelemetryTime {
                                        RuleMark(x: .value("Selected", selectedTelemetryTime))
                                            .foregroundStyle(.yellow.opacity(0.7))
                                    }
                                }
                                .chartOverlay { proxy in
                                    GeometryReader { geometry in
                                        Rectangle()
                                            .fill(.clear)
                                            .contentShape(Rectangle())
                                            .gesture(
                                                DragGesture(minimumDistance: 0)
                                                    .onChanged { value in
                                                        let origin = geometry[proxy.plotAreaFrame].origin
                                                        let x = value.location.x - origin.x
                                                        if let t: Double = proxy.value(atX: x) {
                                                            selectedTelemetryTime = max(0, t)
                                                        }
                                                    }
                                            )
                                    }
                                }
                                .frame(height: 130)
                            }

                            chartCard(title: "Lateral G") {
                                Chart {
                                    ForEach(lateralAccelSeries) { point in
                                        LineMark(
                                            x: .value("t", point.t),
                                            y: .value("Lateral G", point.value)
                                        )
                                        .foregroundStyle(.blue)
                                        .interpolationMethod(.linear)
                                    }
                                    if let selectedTelemetryTime {
                                        RuleMark(x: .value("Selected", selectedTelemetryTime))
                                            .foregroundStyle(.yellow.opacity(0.7))
                                    }
                                }
                                .chartOverlay { proxy in
                                    GeometryReader { geometry in
                                        Rectangle()
                                            .fill(.clear)
                                            .contentShape(Rectangle())
                                            .gesture(
                                                DragGesture(minimumDistance: 0)
                                                    .onChanged { value in
                                                        let origin = geometry[proxy.plotAreaFrame].origin
                                                        let x = value.location.x - origin.x
                                                        if let t: Double = proxy.value(atX: x) {
                                                            selectedTelemetryTime = max(0, t)
                                                        }
                                                    }
                                            )
                                    }
                                }
                                .frame(height: 130)
                            }

                            chartCard(title: "Yaw Rate (rad/s)") {
                                Chart {
                                    ForEach(yawSeries) { point in
                                        LineMark(
                                            x: .value("t", point.t),
                                            y: .value("Yaw", point.value)
                                        )
                                        .foregroundStyle(.orange)
                                        .interpolationMethod(.linear)
                                    }
                                    if let selectedTelemetryTime {
                                        RuleMark(x: .value("Selected", selectedTelemetryTime))
                                            .foregroundStyle(.yellow.opacity(0.7))
                                    }
                                }
                                .chartOverlay { proxy in
                                    GeometryReader { geometry in
                                        Rectangle()
                                            .fill(.clear)
                                            .contentShape(Rectangle())
                                            .gesture(
                                                DragGesture(minimumDistance: 0)
                                                    .onChanged { value in
                                                        let origin = geometry[proxy.plotAreaFrame].origin
                                                        let x = value.location.x - origin.x
                                                        if let t: Double = proxy.value(atX: x) {
                                                            selectedTelemetryTime = max(0, t)
                                                        }
                                                    }
                                            )
                                    }
                                }
                                .frame(height: 130)
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

    private func chartCard<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            content()
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .glassRoundedBackground(radius: 10)
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

    private func deduplicateAdjacent(_ points: [TelemetryPoint], epsilon: Double) -> [TelemetryPoint] {
        guard let first = points.first else { return [] }
        var reduced: [TelemetryPoint] = [first]
        for point in points.dropFirst() {
            if abs(point.value - reduced[reduced.count - 1].value) >= epsilon {
                reduced.append(point)
            }
        }
        if let last = points.last, last.t != reduced.last?.t {
            reduced.append(last)
        }
        return reduced
    }

    private func movingAverage(_ points: [TelemetryPoint], window: Int) -> [TelemetryPoint] {
        guard window > 1, points.count > window else { return points }
        let half = window / 2
        return points.enumerated().map { index, point in
            let lower = max(0, index - half)
            let upper = min(points.count - 1, index + half)
            let slice = points[lower...upper]
            let avg = slice.reduce(0.0) { $0 + $1.value } / Double(slice.count)
            return TelemetryPoint(t: point.t, value: avg)
        }
    }

    private func downsample(_ points: [TelemetryPoint], maxPoints: Int) -> [TelemetryPoint] {
        guard points.count > maxPoints, maxPoints > 1 else { return points }
        let stride = Double(points.count - 1) / Double(maxPoints - 1)
        return (0..<maxPoints).map { index in
            let sourceIndex = Int((Double(index) * stride).rounded())
            return points[min(sourceIndex, points.count - 1)]
        }
    }

    private func clipOutliers(_ points: [TelemetryPoint], sigma: Double) -> [TelemetryPoint] {
        guard points.count > 8 else { return points }
        let values = points.map(\.value)
        let mean = values.reduce(0, +) / Double(values.count)
        let variance = values.reduce(0.0) { partial, value in
            let d = value - mean
            return partial + (d * d)
        } / Double(values.count)
        let stdDev = sqrt(max(variance, 1e-9))
        let minVal = mean - (sigma * stdDev)
        let maxVal = mean + (sigma * stdDev)
        return points.map { point in
            TelemetryPoint(t: point.t, value: min(max(point.value, minVal), maxVal))
        }
    }

    private func telemetryCoordinate(at time: Double) -> GeoCoordinate? {
        guard let start = lapMotionSamples.first?.timestamp else { return nil }
        let targetTimestamp = start.addingTimeInterval(time)
        let candidates = lapMotionSamples.compactMap { sample -> (Date, GeoCoordinate)? in
            guard let latitude = sample.latitude, let longitude = sample.longitude else { return nil }
            return (sample.timestamp, GeoCoordinate(latitude: latitude, longitude: longitude))
        }
        guard !candidates.isEmpty else { return nil }
        return candidates.min(by: {
            abs($0.0.timeIntervalSince(targetTimestamp)) < abs($1.0.timeIntervalSince(targetTimestamp))
        })?.1
    }

    private func smoothedRoute(from datedRoute: [(Date, GeoCoordinate)]) -> [GeoCoordinate] {
        guard let first = datedRoute.first else { return [] }
        let origin = first.1
        var stateX = Geometry.coordinateToLocalPoint(origin: origin, coordinate: first.1).x
        var stateY = Geometry.coordinateToLocalPoint(origin: origin, coordinate: first.1).y
        var velX = 0.0
        var velY = 0.0
        var previousTime = first.0
        var smoothed: [GeoCoordinate] = [first.1]

        for (timestamp, coordinate) in datedRoute.dropFirst() {
            let dt = max(0.001, timestamp.timeIntervalSince(previousTime))
            let measurement = Geometry.coordinateToLocalPoint(origin: origin, coordinate: coordinate)
            let predX = stateX + (velX * dt)
            let predY = stateY + (velY * dt)
            let residualX = measurement.x - predX
            let residualY = measurement.y - predY

            // lightweight constant-velocity Kalman-like correction
            let positionGain = 0.22
            let velocityGain = 0.06
            stateX = predX + (residualX * positionGain)
            stateY = predY + (residualY * positionGain)
            velX = velX + ((residualX / dt) * velocityGain)
            velY = velY + ((residualY / dt) * velocityGain)

            let corrected = Geometry.localPointToCoordinate(
                origin: origin,
                point: Vector2D(x: stateX, y: stateY)
            )
            smoothed.append(corrected)
            previousTime = timestamp
        }

        return smoothed
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
