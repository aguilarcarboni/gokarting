import Foundation
import Combine

@MainActor
final class LiveTimingViewModel: ObservableObject {
    @Published var selectedTrack: Track = .p1Speedway
    @Published var raceDirection: RaceDirection = .clockwise
    @Published var phoneMountOrientation: PhoneMountOrientation = .landscapeLeft

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

    private let sensorRecorder = SensorRecorder()
    private var detector: LapDetectionEngine?

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
        let config = RecordingConfig(
            track: selectedTrack,
            raceDirection: raceDirection,
            phoneMountOrientation: phoneMountOrientation,
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

        sensorRecorder.start()
        isRecording = true
        isSensorCheckRunning = false
    }

    func stopSession() {
        sensorRecorder.stop()
        isRecording = false
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

    private func handle(sample: TelemetrySample) {
        latestSample = sample

        guard let detector else { return }

        if detector.ingest(sample) != nil {
            laps = detector.laps
            gateCrossings = detector.gateCrossings
        } else {
            laps = detector.laps
            gateCrossings = detector.gateCrossings
        }

        route = detector.route
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
