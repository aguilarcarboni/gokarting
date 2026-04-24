import Foundation
import Combine
import CoreLocation
#if canImport(UIKit)
import UIKit
#endif

@MainActor
final class LiveTimingViewModel: ObservableObject {
    enum SessionPhase {
        case setup
        case live
        case summary
    }

    @Published private(set) var phase: SessionPhase = .setup
    @Published var selectedTrack: Track = .p1Speedway {
        didSet {
            normalizeKartForTrack()
            normalizeRaceDirectionForTrack()
        }
    }
    @Published var selectedKart: Kart = Track.p1Speedway.defaultKart
    @Published var sessionType: HeatType = .timeTrial
    @Published var sessionIdentifier: String = ""
    @Published var carNumber: String = ""
    @Published var competitorID: String = ""
    @Published var driverName: String = ""
    @Published var driverNumber: String = ""
    @Published var raceDirection: RaceDirection = .clockwise

    @Published var cooldownSeconds: Double = 5
    @Published var minimumLapDurationSeconds: Double = 20
    @Published var minimumSpeedMPS: Double = 3
    @Published var maximumHorizontalAccuracyMeters: Double = 15
    @Published var directionAlignmentThreshold: Double = 0.35

    @Published private(set) var latestSample: TelemetrySample?
    @Published private(set) var laps: [RecordedLap] = []
    @Published private(set) var gateCrossings: [RecordedGateCrossing] = []
    @Published private(set) var route: [GeoCoordinate] = []
    @Published private(set) var isRecording = false
    @Published private(set) var isSensorCheckRunning = false
    @Published private(set) var exportStatus: String?
    @Published private(set) var debugImportedHeat: Heat?
    @Published private(set) var debugImportStatus: String?

    private let sensorRecorder = SensorRecorder()
    private var detector: LapDetectionEngine?
    private var sessionSamples: [TelemetrySample] = []
    private var sessionStartedAt: Date?
    private var sessionEndedAt: Date?

    init() {
        normalizeKartForTrack()
        normalizeRaceDirectionForTrack()
        sensorRecorder.onSample = { [weak self] sample in
            self?.handle(sample: sample)
        }
    }

    var currentGate: StartFinishGate {
        let gatePoints = selectedTrack.gatePoints
        let expectedForward = expectedForwardVectorFromGateAndDirection()
        return StartFinishGate(pointA: gatePoints.pointA, pointB: gatePoints.pointB, expectedForward: expectedForward)
    }

    func requestPermissions() {
        sensorRecorder.requestPermissions()
    }

    func startSession() {
        if isSensorCheckRunning {
            stopSensorCheck()
        }
        normalizeRaceDirectionForTrack()

        let config = RecordingConfig(
            track: selectedTrack,
            raceDirection: raceDirection,
            gate: currentGate,
            cooldownSeconds: cooldownSeconds,
            minimumLapDurationSeconds: minimumLapDurationSeconds,
            minimumSpeedMPS: minimumSpeedMPS,
            maximumHorizontalAccuracyMeters: maximumHorizontalAccuracyMeters,
            directionAlignmentThreshold: directionAlignmentThreshold
        )

        detector = LapDetectionEngine(config: config)
        detector?.reset(config: config)

        laps.removeAll()
        gateCrossings.removeAll()
        route.removeAll()
        latestSample = nil
        sessionSamples.removeAll()
        sessionStartedAt = Date()
        sessionEndedAt = nil
        exportStatus = nil
        phase = .live

        sensorRecorder.start()
        isRecording = true
        isSensorCheckRunning = false
    }

    func finishSession() {
        sensorRecorder.stop()
        isRecording = false
        sessionEndedAt = Date()
        phase = .summary
    }

    func returnToSetup() {
        sensorRecorder.stop()
        isRecording = false
        isSensorCheckRunning = false
        phase = .setup
    }

    func discardAndReturnToSetup() {
        returnToSetup()
        laps.removeAll()
        gateCrossings.removeAll()
        route.removeAll()
        latestSample = nil
        sessionSamples.removeAll()
        sessionStartedAt = nil
        sessionEndedAt = nil
        exportStatus = nil
    }

    func startSensorCheck() {
        guard !isRecording else { return }
        sensorRecorder.start()
        isSensorCheckRunning = true
    }

    func stopSensorCheck() {
        guard !isRecording else { return }
        sensorRecorder.stop()
        isSensorCheckRunning = false
    }

    func exportSessionJSON() {
        guard !isRecording else {
            exportStatus = "Stop the session before exporting."
            return
        }

        guard !sessionSamples.isEmpty || !laps.isEmpty || !gateCrossings.isEmpty else {
            exportStatus = "No completed session data to export."
            return
        }

        do {
            let json = try encodedSessionExportJSON()
            copyToClipboard(json)
            exportStatus = "Session JSON copied to clipboard."
        } catch {
            exportStatus = "Export failed: \(error.localizedDescription)"
        }
    }

    func importDebugSampleSessionFromFile() {
        let urls = debugSampleCandidateURLs()
        print("[LiveTimingDebug] Looking for sample session at:")
        urls.forEach { print("  - \($0.path)") }

        guard let url = urls.first(where: { FileManager.default.fileExists(atPath: $0.path) }) else {
            debugImportedHeat = nil
            debugImportStatus = "Import failed: data.json not found."
            print("[LiveTimingDebug] data.json not found in known paths.")
            return
        }

        do {
            let data = try Data(contentsOf: url)
            try importDebugJSONData(data, source: url.lastPathComponent)
        } catch {
            debugImportedHeat = nil
            debugImportStatus = "Import failed: \(error.localizedDescription)"
            print("[LiveTimingDebug] Failed loading file \(url.path): \(error)")
        }
    }

    func clearDebugImport() {
        debugImportedHeat = nil
        debugImportStatus = nil
    }

    private func handle(sample: TelemetrySample) {
        latestSample = sample

        guard let detector else { return }

        if isRecording {
            sessionSamples.append(sample)
        }

        _ = detector.ingest(sample)
        laps = detector.laps
        gateCrossings = detector.gateCrossings

        route = detector.route
    }

    private func encodedSessionExportJSON() throws -> String {
        let sessionEndedAt = self.sessionEndedAt ?? sessionSamples.last?.timestamp ?? Date()
        let sessionStartedAt = self.sessionStartedAt ?? sessionSamples.first?.timestamp ?? sessionEndedAt
        let durationSeconds = max(0, sessionEndedAt.timeIntervalSince(sessionStartedAt))

        let lapDurations = laps.map(\.durationSeconds)
        let crossingSpeeds = gateCrossings.map(\.speedAtCrossingMPS)
        let sampleSpeeds = sessionSamples.map(\.speedMPS)
        let totalDistanceMeters = accumulatedDistanceMeters(for: sessionSamples)

        let payload = LiveSessionExport(
            metadata: LiveSessionExport.Metadata(
                exportedAt: Date(),
                sessionStartedAt: sessionStartedAt,
                sessionEndedAt: sessionEndedAt,
                durationSeconds: durationSeconds,
                sessionType: sessionType.rawValue,
                sessionIdentifier: normalizedIdentifier,
                track: selectedTrack.rawValue,
                kart: selectedKart.rawValue,
                carNumber: normalizedCarNumber,
                competitorID: normalizedCompetitorID,
                driverName: normalizedDriverName,
                driverNumber: normalizedDriverNumber,
                raceDirection: raceDirection.rawValue
            ),
            summary: LiveSessionExport.Summary(
                lapsCount: laps.count,
                gateCrossingsCount: gateCrossings.count,
                fastestLapSeconds: lapDurations.min(),
                averageLapSeconds: average(of: lapDurations),
                averageCrossingSpeedMPS: average(of: crossingSpeeds),
                topCrossingSpeedMPS: crossingSpeeds.max(),
                averageSampleSpeedMPS: average(of: sampleSpeeds),
                maxSampleSpeedMPS: sampleSpeeds.max(),
                totalDistanceMeters: totalDistanceMeters,
                averageSpeedFromDistanceMPS: durationSeconds > 0 ? totalDistanceMeters / durationSeconds : nil
            ),
            laps: laps.map { lap in
                LiveSessionExport.Lap(
                    number: lap.number,
                    crossedAt: lap.crossedAt,
                    durationSeconds: lap.durationSeconds,
                    speedAtCrossingMPS: lap.speedAtCrossingMPS,
                    route: lap.route.map {
                        LiveSessionExport.LapRoutePoint(
                            latitude: $0.latitude,
                            longitude: $0.longitude
                        )
                    },
                    telemetry: LiveSessionExport.LapTelemetry(
                        maxLongitudinalAccel: lap.telemetry.maxLongitudinalAccel,
                        maxLateralAccel: lap.telemetry.maxLateralAccel,
                        maxYawRate: lap.telemetry.maxYawRate,
                        averageSpeedMPS: lap.telemetry.averageSpeedMPS,
                        peakSpeedMPS: lap.telemetry.peakSpeedMPS,
                        distanceMeters: lap.telemetry.distanceMeters,
                        sampleCount: lap.telemetry.sampleCount
                    )
                )
            },
            gateCrossings: gateCrossings.map { crossing in
                LiveSessionExport.GateCrossing(
                    number: crossing.number,
                    crossedAt: crossing.crossedAt,
                    speedAtCrossingMPS: crossing.speedAtCrossingMPS
                )
            },
            samples: sessionSamples.map { sample in
                LiveSessionExport.Sample(
                    timestamp: sample.timestamp,
                    latitude: sample.coordinate.latitude,
                    longitude: sample.coordinate.longitude,
                    speedMPS: sample.speedMPS,
                    horizontalAccuracyMeters: sample.horizontalAccuracyMeters,
                    courseDegrees: sample.courseDegrees,
                    accelerationX: sample.accelerationX,
                    accelerationY: sample.accelerationY,
                    accelerationZ: sample.accelerationZ,
                    yawRate: sample.yawRate
                )
            }
        )

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        encoder.dateEncodingStrategy = .iso8601

        let data = try encoder.encode(payload)
        guard let json = String(data: data, encoding: .utf8) else {
            throw NSError(
                domain: "LiveTimingExport",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: "Unable to create UTF-8 JSON string."]
            )
        }
        return json
    }

    private func copyToClipboard(_ text: String) {
#if canImport(UIKit)
        UIPasteboard.general.string = text
#endif
    }

    private func accumulatedDistanceMeters(for samples: [TelemetrySample]) -> Double {
        guard samples.count > 1 else { return 0 }
        var distance = 0.0
        for idx in 1..<samples.count {
            let previous = CLLocation(
                latitude: samples[idx - 1].coordinate.latitude,
                longitude: samples[idx - 1].coordinate.longitude
            )
            let current = CLLocation(
                latitude: samples[idx].coordinate.latitude,
                longitude: samples[idx].coordinate.longitude
            )
            distance += current.distance(from: previous)
        }
        return distance
    }

    private func average(of values: [Double]) -> Double? {
        guard !values.isEmpty else { return nil }
        return values.reduce(0, +) / Double(values.count)
    }

    private func normalizeKartForTrack() {
        if !selectedTrack.availableKarts.contains(selectedKart) {
            selectedKart = selectedTrack.defaultKart
        }
    }

    private func normalizeRaceDirectionForTrack() {
        if !selectedTrack.supportedRaceDirections.contains(raceDirection) {
            raceDirection = selectedTrack.defaultRaceDirection
        }
    }

    private func normalized(_ value: String) -> String? {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    private var normalizedIdentifier: String {
        normalized(sessionIdentifier) ?? generatedFallbackIdentifier
    }

    private var normalizedCarNumber: String? {
        normalized(carNumber)
    }

    private var normalizedCompetitorID: String? {
        normalized(competitorID)
    }

    private var normalizedDriverName: String? {
        normalized(driverName)
    }

    private var normalizedDriverNumber: String? {
        normalized(driverNumber)
    }

    private var generatedFallbackIdentifier: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd-HHmmss"
        let started = sessionStartedAt ?? Date()
        return "\(selectedTrack.rawValue.lowercased().replacingOccurrences(of: " ", with: "-"))-\(sessionType.rawValue)-\(formatter.string(from: started))"
    }

    private func expectedForwardVectorFromGateAndDirection() -> Vector2D {
        let gatePoints = selectedTrack.gatePoints
        let center = GeoCoordinate(
            latitude: (gatePoints.pointA.latitude + gatePoints.pointB.latitude) / 2,
            longitude: (gatePoints.pointA.longitude + gatePoints.pointB.longitude) / 2
        )
        let a = Geometry.coordinateToLocalPoint(origin: center, coordinate: gatePoints.pointA)
        let b = Geometry.coordinateToLocalPoint(origin: center, coordinate: gatePoints.pointB)
        let gateVector = (b - a).normalized()
        let normal = Vector2D(x: -gateVector.y, y: gateVector.x).normalized()

        switch raceDirection {
        case .clockwise:
            return normal
        case .counterClockwise:
            return normal * -1
        }
    }

    private func buildHeatFromImportedPayload(_ payload: LiveSessionExport) throws -> Heat {
        guard !payload.laps.isEmpty else {
            throw NSError(
                domain: "LiveTimingImport",
                code: 2,
                userInfo: [NSLocalizedDescriptionKey: "Imported payload has no laps."]
            )
        }

        let track = resolvedTrack(from: payload.metadata.track ?? selectedTrack.rawValue)
        let kart = resolvedKart(from: payload.metadata.kart, track: track)
        let heatType = resolvedHeatType(from: payload.metadata.sessionType)
        let importedDirection = resolvedRaceDirection(from: payload.metadata.raceDirection ?? raceDirection.rawValue)
        let raceDirection = track.supportedRaceDirections.contains(importedDirection)
            ? importedDirection
            : track.defaultRaceDirection

        let competitorID = normalized(payload.metadata.competitorID ?? "")
        let driverName = normalized(payload.metadata.driverName ?? "")
        let driverNumber = normalized(payload.metadata.driverNumber ?? "")

        let endedAt = payload.metadata.sessionEndedAt ?? Date()
        let startedAt = payload.metadata.sessionStartedAt ?? endedAt
        let durationSeconds = payload.metadata.durationSeconds
            ?? max(0, endedAt.timeIntervalSince(startedAt))

        let laps: [Lap] = payload.laps.enumerated().map { index, lap in
            let lapNumber = lap.number > 0 ? lap.number : (index + 1)
            let lapTimestamp = lap.crossedAt ?? endedAt
            let route = resolvedImportedRoute(for: lap, lapIndex: index, payload: payload)
            return Lap(
                track: track,
                kart: kart,
                competitorID: competitorID,
                driverName: driverName,
                driverNumber: driverNumber,
                lapNumber: lapNumber,
                duration: lap.durationSeconds,
                timestamp: lapTimestamp,
                crossedAt: lap.crossedAt,
                speedAtCrossingMPS: lap.speedAtCrossingMPS,
                telemetry: LapTelemetry(
                    maxLongitudinalAccel: lap.telemetry.maxLongitudinalAccel ?? 0,
                    maxLateralAccel: lap.telemetry.maxLateralAccel ?? 0,
                    maxYawRate: lap.telemetry.maxYawRate ?? 0,
                    averageSpeedMPS: lap.telemetry.averageSpeedMPS ?? 0,
                    peakSpeedMPS: lap.telemetry.peakSpeedMPS ?? 0,
                    distanceMeters: lap.telemetry.distanceMeters ?? 0,
                    sampleCount: lap.telemetry.sampleCount ?? 0
                ),
                route: route
            )
        }

        let sampleSpeeds = payload.samples.map(\.speedMPS)
        let peakAcceleration = payload.samples.compactMap(\.accelerationX).map(abs).max() ?? 0
        let peakDeceleration = abs(payload.samples.compactMap(\.accelerationX).min() ?? 0)
        let peakYaw = payload.samples.compactMap(\.yawRate).map(abs).max()
            ?? payload.laps.compactMap(\.telemetry.maxYawRate).max()
            ?? 0

        let metadata = LiveSessionMetadata(
            source: "debug_live_session_json",
            startedAt: startedAt,
            endedAt: endedAt,
            durationSeconds: durationSeconds,
            raceDirection: raceDirection,
            gateCrossingsCount: max(payload.summary.gateCrossingsCount, payload.gateCrossings.count),
            sampleCount: payload.samples.count,
            totalDistanceMeters: payload.summary.totalDistanceMeters,
            averageSpeedMPS: payload.summary.averageSampleSpeedMPS ?? average(of: sampleSpeeds) ?? 0,
            peakSpeedMPS: payload.summary.maxSampleSpeedMPS ?? sampleSpeeds.max() ?? 0,
            peakAccelerationG: peakAcceleration,
            peakDecelerationG: peakDeceleration,
            peakYawRate: peakYaw
        )

        let identifier = normalized(payload.metadata.sessionIdentifier ?? "")
            ?? "imported-\(Int(endedAt.timeIntervalSince1970))"

        return Heat(
            identifier: identifier,
            type: heatType,
            carNumber: normalized(payload.metadata.carNumber ?? ""),
            track: track,
            kart: kart,
            laps: laps,
            date: endedAt,
            sessionMetadata: metadata
        )
    }

    private func importDebugJSONData(_ data: Data, source: String) throws {
        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let payload = try decoder.decode(LiveSessionExport.self, from: data)
            let heat = try buildHeatFromImportedPayload(payload)
            debugImportedHeat = heat
            debugImportStatus = "Imported \(source): \(heat.identifier) (\(heat.lapCount) laps)."
            print("[LiveTimingDebug] Imported \(source) -> heat \(heat.identifier), laps=\(heat.lapCount)")
        } catch {
            debugImportedHeat = nil
            let detail = describeImportError(error)
            debugImportStatus = "Import failed: \(detail)"
            print("[LiveTimingDebug] Import decode/build failed for \(source): \(detail)")
            throw error
        }
    }

    private func describeImportError(_ error: Error) -> String {
        if let decoding = error as? DecodingError {
            switch decoding {
            case .typeMismatch(let type, let context):
                return "Type mismatch (\(type)) at \(context.codingPath.map(\.stringValue).joined(separator: "."))"
            case .valueNotFound(let type, let context):
                return "Missing value (\(type)) at \(context.codingPath.map(\.stringValue).joined(separator: "."))"
            case .keyNotFound(let key, let context):
                return "Missing key '\(key.stringValue)' at \(context.codingPath.map(\.stringValue).joined(separator: "."))"
            case .dataCorrupted(let context):
                return "Data corrupted at \(context.codingPath.map(\.stringValue).joined(separator: ".")): \(context.debugDescription)"
            @unknown default:
                return error.localizedDescription
            }
        }
        return error.localizedDescription
    }

    private func debugSampleCandidateURLs() -> [URL] {
        var urls: [URL] = []
        if let bundled = Bundle.main.url(forResource: "data", withExtension: "json") {
            urls.append(bundled)
        }

        let sourceTreeURL = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("data.json")
        urls.append(sourceTreeURL)

        return urls
    }

    private func resolvedTrack(from raw: String) -> Track {
        if let exact = Track.allCases.first(where: { $0.rawValue == raw }) {
            return exact
        }
        if let folded = Track.allCases.first(where: { $0.rawValue.caseInsensitiveCompare(raw) == .orderedSame }) {
            return folded
        }
        return selectedTrack
    }

    private func resolvedKart(from raw: String?, track: Track) -> Kart {
        guard let raw else { return track.defaultKart }
        if let exact = track.availableKarts.first(where: { $0.rawValue == raw }) {
            return exact
        }
        if let folded = track.availableKarts.first(where: { $0.rawValue.caseInsensitiveCompare(raw) == .orderedSame }) {
            return folded
        }
        return track.defaultKart
    }

    private func resolvedHeatType(from raw: String?) -> HeatType {
        guard let raw else { return .timeTrial }
        if let exact = HeatType(rawValue: raw) {
            return exact
        }
        if let folded = HeatType.allCases.first(where: { $0.rawValue.caseInsensitiveCompare(raw) == .orderedSame }) {
            return folded
        }
        if raw.lowercased().contains("qual") {
            return .quali
        }
        if raw.lowercased().contains("race") {
            return .race
        }
        if raw.lowercased().contains("practice") {
            return .practice
        }
        return .timeTrial
    }

    private func resolvedRaceDirection(from raw: String) -> RaceDirection {
        if let exact = RaceDirection(rawValue: raw) {
            return exact
        }
        if raw.lowercased().contains("counter") {
            return .counterClockwise
        }
        return .clockwise
    }

    private func resolvedImportedRoute(
        for lap: LiveSessionExport.Lap,
        lapIndex: Int,
        payload: LiveSessionExport
    ) -> [GeoCoordinate] {
        if let explicitRoute = lap.route, !explicitRoute.isEmpty {
            return explicitRoute.map { GeoCoordinate(latitude: $0.latitude, longitude: $0.longitude) }
        }

        guard !payload.samples.isEmpty else { return [] }

        let lapEnd = lap.crossedAt ?? payload.metadata.sessionEndedAt ?? payload.samples.last?.timestamp
        let lapStart: Date? = {
            if lapIndex > 0 {
                return payload.laps[lapIndex - 1].crossedAt
            }
            return payload.gateCrossings.first?.crossedAt ?? payload.metadata.sessionStartedAt
        }()

        let start = lapStart ?? payload.samples.first?.timestamp
        let end = lapEnd ?? payload.samples.last?.timestamp

        guard let start, let end, start <= end else { return [] }

        return payload.samples
            .filter { $0.timestamp >= start && $0.timestamp <= end }
            .map { GeoCoordinate(latitude: $0.latitude, longitude: $0.longitude) }
    }
}

extension LiveTimingViewModel {
    var bestLap: RecordedLap? {
        laps.min(by: { $0.durationSeconds < $1.durationSeconds })
    }

    var latestLap: RecordedLap? {
        laps.last
    }

    var currentLapElapsed: TimeInterval? {
        guard isRecording, let now = latestSample?.timestamp else { return nil }
        if let lastCrossing = gateCrossings.last?.crossedAt {
            return max(0, now.timeIntervalSince(lastCrossing))
        }
        guard let startedAt = sessionStartedAt else { return nil }
        return max(0, now.timeIntervalSince(startedAt))
    }

    var currentLapDeltaToBest: TimeInterval? {
        guard let bestLap, let elapsed = currentLapElapsed else { return nil }
        return elapsed - bestLap.durationSeconds
    }

    var sessionElapsed: TimeInterval {
        if let startedAt = sessionStartedAt {
            let end = sessionEndedAt ?? latestSample?.timestamp ?? Date()
            return max(0, end.timeIntervalSince(startedAt))
        }
        return 0
    }

    var peakAccelerationG: Double {
        sessionSamples
            .compactMap(\.accelerationX)
            .map(abs)
            .max() ?? 0
    }

    var peakDecelerationG: Double {
        abs(sessionSamples.compactMap(\.accelerationX).min() ?? 0)
    }

    var sampleCount: Int {
        sessionSamples.count
    }

    var averageSpeedMPS: Double {
        guard !sessionSamples.isEmpty else { return 0 }
        let speedSum = sessionSamples.reduce(0) { partialResult, sample in
            partialResult + sample.speedMPS
        }
        return speedSum / Double(sessionSamples.count)
    }

    var peakSpeedMPS: Double {
        sessionSamples.map(\.speedMPS).max() ?? 0
    }

    var peakYawRate: Double {
        sessionSamples.compactMap(\.yawRate).map(abs).max() ?? 0
    }

    var totalDistanceMeters: Double {
        accumulatedDistanceMeters(for: sessionSamples)
    }

    var preparedHeatForSaving: Heat? {
        guard phase == .summary else { return nil }
        return buildHeatFromCurrentSession()
    }

    func buildHeatFromCurrentSession() -> Heat? {
        guard !laps.isEmpty else { return nil }

        let endedAt = sessionEndedAt ?? sessionSamples.last?.timestamp ?? Date()
        let startedAt = sessionStartedAt ?? sessionSamples.first?.timestamp ?? endedAt
        let durationSeconds = max(0, endedAt.timeIntervalSince(startedAt))

        let mappedLaps = laps.map { lap in
            Lap(
                track: selectedTrack,
                kart: selectedKart,
                competitorID: normalizedCompetitorID,
                driverName: normalizedDriverName,
                driverNumber: normalizedDriverNumber,
                lapNumber: lap.number,
                duration: lap.durationSeconds,
                timestamp: lap.crossedAt,
                crossedAt: lap.crossedAt,
                speedAtCrossingMPS: lap.speedAtCrossingMPS,
                telemetry: LapTelemetry(
                    maxLongitudinalAccel: lap.telemetry.maxLongitudinalAccel,
                    maxLateralAccel: lap.telemetry.maxLateralAccel,
                    maxYawRate: lap.telemetry.maxYawRate,
                    averageSpeedMPS: lap.telemetry.averageSpeedMPS,
                    peakSpeedMPS: lap.telemetry.peakSpeedMPS,
                    distanceMeters: lap.telemetry.distanceMeters,
                    sampleCount: lap.telemetry.sampleCount
                ),
                route: lap.route
            )
        }

        let metadata = LiveSessionMetadata(
            source: "live_timing",
            startedAt: startedAt,
            endedAt: endedAt,
            durationSeconds: durationSeconds,
            raceDirection: raceDirection,
            gateCrossingsCount: gateCrossings.count,
            sampleCount: sampleCount,
            totalDistanceMeters: totalDistanceMeters,
            averageSpeedMPS: averageSpeedMPS,
            peakSpeedMPS: peakSpeedMPS,
            peakAccelerationG: peakAccelerationG,
            peakDecelerationG: peakDecelerationG,
            peakYawRate: peakYawRate
        )

        return Heat(
            identifier: normalizedIdentifier,
            type: sessionType,
            carNumber: normalizedCarNumber,
            track: selectedTrack,
            kart: selectedKart,
            laps: mappedLaps,
            date: endedAt,
            sessionMetadata: metadata
        )
    }
}

private struct LiveSessionExport: Codable {
    struct Metadata: Codable {
        let exportedAt: Date?
        let sessionStartedAt: Date?
        let sessionEndedAt: Date?
        let durationSeconds: TimeInterval?
        let sessionType: String?
        let sessionIdentifier: String?
        let track: String?
        let kart: String?
        let carNumber: String?
        let competitorID: String?
        let driverName: String?
        let driverNumber: String?
        let raceDirection: String?
    }

    struct Summary: Codable {
        let lapsCount: Int
        let gateCrossingsCount: Int
        let fastestLapSeconds: TimeInterval?
        let averageLapSeconds: TimeInterval?
        let averageCrossingSpeedMPS: Double?
        let topCrossingSpeedMPS: Double?
        let averageSampleSpeedMPS: Double?
        let maxSampleSpeedMPS: Double?
        let totalDistanceMeters: Double
        let averageSpeedFromDistanceMPS: Double?
    }

    struct Lap: Codable {
        let number: Int
        let crossedAt: Date?
        let durationSeconds: TimeInterval
        let speedAtCrossingMPS: Double?
        let route: [LapRoutePoint]?
        let telemetry: LapTelemetry
    }

    struct LapRoutePoint: Codable {
        let latitude: Double
        let longitude: Double
    }

    struct LapTelemetry: Codable {
        let maxLongitudinalAccel: Double?
        let maxLateralAccel: Double?
        let maxYawRate: Double?
        let averageSpeedMPS: Double?
        let peakSpeedMPS: Double?
        let distanceMeters: Double?
        let sampleCount: Int?
    }

    struct GateCrossing: Codable {
        let number: Int
        let crossedAt: Date
        let speedAtCrossingMPS: Double
    }

    struct Sample: Codable {
        let timestamp: Date
        let latitude: Double
        let longitude: Double
        let speedMPS: Double
        let horizontalAccuracyMeters: Double
        let courseDegrees: Double?
        let accelerationX: Double?
        let accelerationY: Double?
        let accelerationZ: Double?
        let yawRate: Double?
    }

    let metadata: Metadata
    let summary: Summary
    let laps: [Lap]
    let gateCrossings: [GateCrossing]
    let samples: [Sample]
}
