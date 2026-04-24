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
    @Published var selectedTrack: Track = .p1Speedway
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

    private let sensorRecorder = SensorRecorder()
    private var detector: LapDetectionEngine?
    private var sessionSamples: [TelemetrySample] = []
    private var sessionStartedAt: Date?
    private var sessionEndedAt: Date?

    init() {
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
                track: selectedTrack.rawValue,
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
                    telemetry: LiveSessionExport.LapTelemetry(
                        maxLongitudinalAccel: lap.telemetry.maxLongitudinalAccel,
                        maxLateralAccel: lap.telemetry.maxLateralAccel,
                        maxYawRate: lap.telemetry.maxYawRate
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
}

private struct LiveSessionExport: Codable {
    struct Metadata: Codable {
        let exportedAt: Date
        let sessionStartedAt: Date
        let sessionEndedAt: Date
        let durationSeconds: TimeInterval
        let track: String
        let raceDirection: String
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
        let crossedAt: Date
        let durationSeconds: TimeInterval
        let speedAtCrossingMPS: Double
        let telemetry: LapTelemetry
    }

    struct LapTelemetry: Codable {
        let maxLongitudinalAccel: Double
        let maxLateralAccel: Double
        let maxYawRate: Double
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
