import Foundation

final class LapDetectionEngine {
    private(set) var config: RecordingConfig
    private(set) var laps: [RecordedLap] = []
    private(set) var gateCrossings: [RecordedGateCrossing] = []
    private(set) var route: [GeoCoordinate] = []

    private var previousSample: TelemetrySample?
    private var lapStartTimestamp: Date?
    private var lastAcceptedCrossing: Date?
    private var currentLapMaxLongitudinalAccel: Double = 0
    private var currentLapMaxLateralAccel: Double = 0
    private var currentLapMaxYawRate: Double = 0

    init(config: RecordingConfig) {
        self.config = config
    }

    func reset(config: RecordingConfig) {
        self.config = config
        laps.removeAll()
        gateCrossings.removeAll()
        route.removeAll()
        previousSample = nil
        lapStartTimestamp = nil
        lastAcceptedCrossing = nil
        resetCurrentLapTelemetry()
    }

    @discardableResult
    func ingest(_ sample: TelemetrySample) -> RecordedLap? {
        route.append(sample.coordinate)
        updateCurrentLapTelemetry(with: sample)

        guard let previousSample else {
            self.previousSample = sample
            return nil
        }

        defer {
            self.previousSample = sample
        }

        guard sample.horizontalAccuracyMeters <= config.maximumHorizontalAccuracyMeters,
              previousSample.horizontalAccuracyMeters <= config.maximumHorizontalAccuracyMeters else {
            return nil
        }

        let localOrigin = config.gate.center
        let p1 = Geometry.coordinateToLocalPoint(origin: localOrigin, coordinate: previousSample.coordinate)
        let p2 = Geometry.coordinateToLocalPoint(origin: localOrigin, coordinate: sample.coordinate)
        let a = Geometry.coordinateToLocalPoint(origin: localOrigin, coordinate: config.gate.pointA)
        let b = Geometry.coordinateToLocalPoint(origin: localOrigin, coordinate: config.gate.pointB)

        guard Geometry.segmentsIntersect(p1, p2, a, b) else {
            return nil
        }

        if let lastAcceptedCrossing,
           sample.timestamp.timeIntervalSince(lastAcceptedCrossing) < config.cooldownSeconds {
            return nil
        }

        let movement = (p2 - p1).normalized()
        let expected = config.gate.expectedForward.normalized()
        let alignment = movement.dot(expected)

        guard alignment >= config.directionAlignmentThreshold else {
            return nil
        }

        let crossingSpeed = max(previousSample.speedMPS, sample.speedMPS)
        guard crossingSpeed >= config.minimumSpeedMPS else {
            return nil
        }

        let gateCrossing = RecordedGateCrossing(
            number: gateCrossings.count + 1,
            crossedAt: sample.timestamp,
            speedAtCrossingMPS: crossingSpeed
        )
        gateCrossings.append(gateCrossing)
        print(
            "Gate crossing \(gateCrossing.number): speed \(String(format: "%.2f", crossingSpeed)) m/s at \(sample.timestamp)"
        )

        if lapStartTimestamp == nil {
            lapStartTimestamp = sample.timestamp
            lastAcceptedCrossing = sample.timestamp
            print(
                "Gate crossed: timer armed at \(sample.timestamp) (speed \(String(format: "%.2f", crossingSpeed)) m/s)"
            )
            resetCurrentLapTelemetry()
            return nil
        }

        guard let lapStartTimestamp else { return nil }
        let duration = sample.timestamp.timeIntervalSince(lapStartTimestamp)

        guard duration >= config.minimumLapDurationSeconds else {
            return nil
        }

        let lap = RecordedLap(
            number: laps.count + 1,
            durationSeconds: duration,
            crossedAt: sample.timestamp,
            speedAtCrossingMPS: crossingSpeed,
            telemetry: LapTelemetrySummary(
                maxLongitudinalAccel: currentLapMaxLongitudinalAccel,
                maxLateralAccel: currentLapMaxLateralAccel,
                maxYawRate: currentLapMaxYawRate
            )
        )

        laps.append(lap)
        self.lapStartTimestamp = sample.timestamp
        lastAcceptedCrossing = sample.timestamp
        print(
            "Gate crossed: completed lap \(lap.number) in \(String(format: "%.3f", lap.durationSeconds))s at \(sample.timestamp)"
        )
        resetCurrentLapTelemetry()
        return lap
    }

    private func updateCurrentLapTelemetry(with sample: TelemetrySample) {
        if let accelerationX = sample.accelerationX {
            currentLapMaxLongitudinalAccel = max(currentLapMaxLongitudinalAccel, abs(accelerationX))
        }
        if let accelerationY = sample.accelerationY {
            currentLapMaxLateralAccel = max(currentLapMaxLateralAccel, abs(accelerationY))
        }
        if let yawRate = sample.yawRate {
            currentLapMaxYawRate = max(currentLapMaxYawRate, abs(yawRate))
        }
    }

    private func resetCurrentLapTelemetry() {
        currentLapMaxLongitudinalAccel = 0
        currentLapMaxLateralAccel = 0
        currentLapMaxYawRate = 0
    }
}
