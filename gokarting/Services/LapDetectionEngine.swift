import Foundation
import CoreLocation

final class LapDetectionEngine {
    private let mergedLapSplitThreshold: Double = 1.6
    private let maxRecoveredSegmentsPerLap: Int = 3
    private let minimumCrossingConfidence: Double = 0.35
    private let minimumSampleQuality: Double = 0.28
    private let gateTimingWindowSeconds: TimeInterval = 1.2

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
    private var currentLapSpeedSum: Double = 0
    private var currentLapPeakSpeed: Double = 0
    private var currentLapDistanceMeters: Double = 0
    private var currentLapSampleCount: Int = 0
    private var currentLapQualityWeightSum: Double = 0
    private var currentLapRoute: [GeoCoordinate] = []
    private var filteredLocalPoint: Vector2D?
    private var filteredVelocity: Vector2D?
    private var previousFilteredSample: FilteredKinematicSample?

    private struct FilteredKinematicSample {
        let timestamp: Date
        let localPoint: Vector2D
        let velocity: Vector2D
        let quality: Double
    }

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
        filteredLocalPoint = nil
        filteredVelocity = nil
        previousFilteredSample = nil
        resetCurrentLapTelemetry()
    }

    @discardableResult
    func ingest(_ sample: TelemetrySample) -> RecordedLap? {
        let sampleQuality = sampleQualityScore(sample)
        guard sampleQuality >= minimumSampleQuality else { return nil }

        guard let previousSample else {
            self.previousSample = sample
            let localOrigin = config.gate.center
            let localPoint = Geometry.coordinateToLocalPoint(origin: localOrigin, coordinate: sample.coordinate)
            filteredLocalPoint = localPoint
            filteredVelocity = velocityVector(for: sample, fallbackHeading: config.gate.expectedForward)
            previousFilteredSample = FilteredKinematicSample(
                timestamp: sample.timestamp,
                localPoint: localPoint,
                velocity: filteredVelocity ?? .init(x: 0, y: 0),
                quality: sampleQuality
            )
            route.append(sample.coordinate)
            currentLapRoute.append(sample.coordinate)
            updateCurrentLapTelemetry(with: sample, quality: sampleQuality)
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

        let filtered = filteredKinematicSample(
            from: sample,
            previousSample: previousSample,
            rawPreviousPoint: p1,
            rawCurrentPoint: p2,
            quality: sampleQuality
        )
        let filteredPoint = filtered.localPoint
        let filteredCoordinate = Geometry.localPointToCoordinate(origin: localOrigin, point: filteredPoint)
        route.append(filteredCoordinate)
        currentLapRoute.append(filteredCoordinate)
        updateCurrentLapTelemetry(with: sample, quality: sampleQuality)

        let crossingResult = inferGateCrossing(
            previous: previousFilteredSample,
            current: filtered,
            gateA: a,
            gateB: b
        ) ?? inferSegmentIntersectionCrossing(
            previousPoint: p1,
            currentPoint: p2,
            previousTimestamp: previousSample.timestamp,
            currentTimestamp: sample.timestamp,
            gateA: a,
            gateB: b
        )

        previousFilteredSample = filtered
        filteredLocalPoint = filtered.localPoint
        filteredVelocity = filtered.velocity

        guard let crossingResult else {
            return nil
        }
        let crossingBlend = max(0, min(1, crossingResult.blend))
        let crossingTimestamp = crossingResult.timestamp

        if let lastAcceptedCrossing,
           crossingTimestamp.timeIntervalSince(lastAcceptedCrossing) < config.cooldownSeconds {
            return nil
        }

        let movement = (p2 - p1).normalized()
        let expected = config.gate.expectedForward.normalized()
        let alignment = movement.dot(expected)
        let crossingConfidence = crossingConfidenceScore(
            alignment: alignment,
            crossingBlend: crossingBlend,
            sampleAccuracy: sample.horizontalAccuracyMeters,
            previousAccuracy: previousSample.horizontalAccuracyMeters,
            sampleQuality: sampleQuality
        )
        let requiredAlignment = dynamicAlignmentThreshold(
            sampleAccuracy: sample.horizontalAccuracyMeters,
            previousAccuracy: previousSample.horizontalAccuracyMeters
        )

        guard alignment >= requiredAlignment else {
            return nil
        }

        guard crossingConfidence >= minimumCrossingConfidence else {
            return nil
        }

        let crossingSpeed = previousSample.speedMPS + ((sample.speedMPS - previousSample.speedMPS) * crossingBlend)
        guard crossingSpeed >= config.minimumSpeedMPS else {
            return nil
        }

        if lapStartTimestamp == nil {
            appendGateCrossing(at: crossingTimestamp, speed: crossingSpeed)
            lapStartTimestamp = crossingTimestamp
            lastAcceptedCrossing = crossingTimestamp
            print(
                "Gate crossed: timer armed at \(crossingTimestamp) (speed \(String(format: "%.2f", crossingSpeed)) m/s)"
            )
            resetCurrentLapTelemetry()
            currentLapRoute.append(sample.coordinate)
            return nil
        }

        guard let lapStartTimestamp else { return nil }
        let duration = crossingTimestamp.timeIntervalSince(lapStartTimestamp)

        guard duration >= config.minimumLapDurationSeconds else {
            return nil
        }

        let combinedTelemetry = LapTelemetrySummary(
            maxLongitudinalAccel: currentLapMaxLongitudinalAccel,
            maxLateralAccel: currentLapMaxLateralAccel,
            maxYawRate: currentLapMaxYawRate,
            averageSpeedMPS: currentLapQualityWeightSum > 0 ? currentLapSpeedSum / currentLapQualityWeightSum : 0,
            peakSpeedMPS: currentLapPeakSpeed,
            distanceMeters: currentLapDistanceMeters,
            sampleCount: currentLapSampleCount
        )

        let recoveredSegments = recoveredSegmentCount(for: duration)
        let completedLap: RecordedLap
        if recoveredSegments > 1 {
            print(
                "Gate crossing recovery: splitting long lap (\(String(format: "%.3f", duration))s) into \(recoveredSegments) laps."
            )
            completedLap = appendRecoveredLaps(
                segmentCount: recoveredSegments,
                lapStart: lapStartTimestamp,
                crossingTimestamp: crossingTimestamp,
                crossingSpeed: crossingSpeed,
                crossingConfidence: crossingConfidence,
                combinedTelemetry: combinedTelemetry,
                combinedRoute: currentLapRoute
            )
        } else {
            appendGateCrossing(at: crossingTimestamp, speed: crossingSpeed)
            let suspectReason = crossingConfidence < 0.55 ? "Low crossing confidence" : nil
            let lap = RecordedLap(
                number: laps.count + 1,
                durationSeconds: duration,
                crossedAt: crossingTimestamp,
                speedAtCrossingMPS: crossingSpeed,
                confidenceScore: crossingConfidence,
                suspectReason: suspectReason,
                isRecovered: false,
                telemetry: combinedTelemetry,
                route: currentLapRoute
            )
            laps.append(lap)
            completedLap = lap
        }

        self.lapStartTimestamp = crossingTimestamp
        lastAcceptedCrossing = crossingTimestamp
        print(
            "Gate crossed: completed lap \(completedLap.number) in \(String(format: "%.3f", completedLap.durationSeconds))s at \(crossingTimestamp)"
        )
        resetCurrentLapTelemetry()
        currentLapRoute.append(sample.coordinate)
        return completedLap
    }

    private func appendGateCrossing(at timestamp: Date, speed: Double) {
        let gateCrossing = RecordedGateCrossing(
            number: gateCrossings.count + 1,
            crossedAt: timestamp,
            speedAtCrossingMPS: speed
        )
        gateCrossings.append(gateCrossing)
        print(
            "Gate crossing \(gateCrossing.number): speed \(String(format: "%.2f", speed)) m/s at \(timestamp)"
        )
    }

    private func recoveredSegmentCount(for duration: TimeInterval) -> Int {
        guard laps.count >= 2 else { return 1 }
        let baseline = rollingMedianLapDuration()
        guard baseline >= config.minimumLapDurationSeconds else { return 1 }
        guard duration > baseline * mergedLapSplitThreshold else { return 1 }

        let estimated = Int((duration / baseline).rounded())
        let clamped = min(maxRecoveredSegmentsPerLap, max(2, estimated))
        let segmentDuration = duration / Double(clamped)
        return segmentDuration >= config.minimumLapDurationSeconds ? clamped : 1
    }

    private func rollingMedianLapDuration() -> TimeInterval {
        let recent = laps.suffix(4).map(\.durationSeconds).sorted()
        guard !recent.isEmpty else { return config.minimumLapDurationSeconds }
        let mid = recent.count / 2
        if recent.count.isMultiple(of: 2) {
            return (recent[mid - 1] + recent[mid]) / 2
        }
        return recent[mid]
    }

    private func appendRecoveredLaps(
        segmentCount: Int,
        lapStart: Date,
        crossingTimestamp: Date,
        crossingSpeed: Double,
        crossingConfidence: Double,
        combinedTelemetry: LapTelemetrySummary,
        combinedRoute: [GeoCoordinate]
    ) -> RecordedLap {
        let totalDuration = crossingTimestamp.timeIntervalSince(lapStart)
        let segmentDuration = totalDuration / Double(segmentCount)
        let routeChunks = splitRoute(combinedRoute, chunks: segmentCount)
        let telemetryChunks = splitTelemetry(combinedTelemetry, chunks: segmentCount)
        var lastLap: RecordedLap?

        for segmentIndex in 0..<segmentCount {
            let endTime = lapStart.addingTimeInterval(segmentDuration * Double(segmentIndex + 1))
            appendGateCrossing(at: endTime, speed: crossingSpeed)
            let lap = RecordedLap(
                number: laps.count + 1,
                durationSeconds: segmentDuration,
                crossedAt: endTime,
                speedAtCrossingMPS: crossingSpeed,
                confidenceScore: min(crossingConfidence, 0.7),
                suspectReason: "Recovered from missed crossing",
                isRecovered: true,
                telemetry: telemetryChunks[segmentIndex],
                route: routeChunks[segmentIndex]
            )
            laps.append(lap)
            lastLap = lap
        }

        return lastLap ?? RecordedLap(
            number: laps.count + 1,
            durationSeconds: totalDuration,
            crossedAt: crossingTimestamp,
            speedAtCrossingMPS: crossingSpeed,
            confidenceScore: crossingConfidence,
            suspectReason: "Recovered from missed crossing",
            isRecovered: true,
            telemetry: combinedTelemetry,
            route: combinedRoute
        )
    }

    private func dynamicAlignmentThreshold(sampleAccuracy: Double, previousAccuracy: Double) -> Double {
        let worstAccuracy = max(sampleAccuracy, previousAccuracy)
        let ratio = max(0, min(1.5, worstAccuracy / max(1, config.maximumHorizontalAccuracyMeters)))
        let adjusted = config.directionAlignmentThreshold + ((ratio - 0.5) * 0.25)
        return max(0.15, min(0.9, adjusted))
    }

    private struct CrossingInference {
        let timestamp: Date
        let blend: Double
    }

    private func sampleQualityScore(_ sample: TelemetrySample) -> Double {
        let horizontal = max(0, min(1, 1 - (sample.horizontalAccuracyMeters / max(1, config.maximumHorizontalAccuracyMeters))))
        let speedAcc = max(0, min(1, 1 - ((sample.speedAccuracyMPS ?? 0.5) / 2.0)))
        let courseAcc = max(0, min(1, 1 - ((sample.courseAccuracyDegrees ?? 25) / 60.0)))
        let jitter = max(0, min(1, 1 - ((sample.timestampJitterSeconds ?? 0.0) / 0.25)))
        return (horizontal * 0.5) + (speedAcc * 0.2) + (courseAcc * 0.15) + (jitter * 0.15)
    }

    private func velocityVector(for sample: TelemetrySample, fallbackHeading: Vector2D) -> Vector2D {
        let heading: Vector2D
        if let course = sample.courseDegrees {
            heading = Geometry.headingToVector(course).normalized()
        } else {
            heading = fallbackHeading.normalized()
        }
        return heading * max(0, sample.speedMPS)
    }

    private func filteredKinematicSample(
        from sample: TelemetrySample,
        previousSample: TelemetrySample,
        rawPreviousPoint: Vector2D,
        rawCurrentPoint: Vector2D,
        quality: Double
    ) -> FilteredKinematicSample {
        let dt = max(0.001, sample.timestamp.timeIntervalSince(previousSample.timestamp))
        let measuredVelocity = velocityVector(for: sample, fallbackHeading: config.gate.expectedForward)
        let prevPoint = filteredLocalPoint ?? rawPreviousPoint
        let prevVelocity = filteredVelocity ?? measuredVelocity
        let predictedPoint = prevPoint + (prevVelocity * dt)
        let predictedVelocity = prevVelocity

        let measurementGain = 0.2 + (quality * 0.6)
        let velocityGain = 0.15 + (quality * 0.55)

        let correctedPoint = predictedPoint + ((rawCurrentPoint - predictedPoint) * measurementGain)
        let correctedVelocity = predictedVelocity + ((measuredVelocity - predictedVelocity) * velocityGain)

        return FilteredKinematicSample(
            timestamp: sample.timestamp,
            localPoint: correctedPoint,
            velocity: correctedVelocity,
            quality: quality
        )
    }

    private func inferSegmentIntersectionCrossing(
        previousPoint: Vector2D,
        currentPoint: Vector2D,
        previousTimestamp: Date,
        currentTimestamp: Date,
        gateA: Vector2D,
        gateB: Vector2D
    ) -> CrossingInference? {
        guard let intersection = Geometry.intersectionParameters(previousPoint, currentPoint, gateA, gateB) else {
            return nil
        }
        let dt = max(0.001, currentTimestamp.timeIntervalSince(previousTimestamp))
        let blend = max(0, min(1, intersection.t))
        let ts = previousTimestamp.addingTimeInterval(dt * blend)
        return CrossingInference(timestamp: ts, blend: blend)
    }

    private func inferGateCrossing(
        previous: FilteredKinematicSample?,
        current: FilteredKinematicSample,
        gateA: Vector2D,
        gateB: Vector2D
    ) -> CrossingInference? {
        guard let previous else { return nil }
        let dt = current.timestamp.timeIntervalSince(previous.timestamp)
        guard dt > 0, dt <= gateTimingWindowSeconds else { return nil }

        let gateVec = (gateB - gateA).normalized()
        let normal = Vector2D(x: -gateVec.y, y: gateVec.x).normalized()
        let center = (gateA + gateB) * 0.5
        let halfLength = (gateB - gateA).magnitude * 0.5

        let prevRel = previous.localPoint - center
        let currRel = current.localPoint - center
        let prevAlong = prevRel.dot(gateVec)
        let currAlong = currRel.dot(gateVec)
        let prevDist = prevRel.dot(normal)
        let currDist = currRel.dot(normal)

        let maxAlongAllowance = halfLength + 6.0
        guard abs(prevAlong) <= maxAlongAllowance || abs(currAlong) <= maxAlongAllowance else {
            return nil
        }

        guard (prevDist <= 0 && currDist > 0) || (prevDist >= 0 && currDist < 0) else {
            return nil
        }

        let denom = abs(prevDist) + abs(currDist)
        guard denom > 1e-6 else { return nil }
        let blend = abs(prevDist) / denom
        let timestamp = previous.timestamp.addingTimeInterval(dt * blend)
        return CrossingInference(timestamp: timestamp, blend: blend)
    }

    private func crossingConfidenceScore(
        alignment: Double,
        crossingBlend: Double,
        sampleAccuracy: Double,
        previousAccuracy: Double,
        sampleQuality: Double
    ) -> Double {
        let threshold = dynamicAlignmentThreshold(sampleAccuracy: sampleAccuracy, previousAccuracy: previousAccuracy)
        let alignmentNorm = max(0, min(1, (alignment - threshold) / max(0.01, 1 - threshold)))
        let worstAccuracy = max(sampleAccuracy, previousAccuracy)
        let accuracyNorm = max(0, min(1, 1 - (worstAccuracy / max(1, config.maximumHorizontalAccuracyMeters))))
        let blendNorm = max(0, min(1, 1 - abs(crossingBlend - 0.5) * 2))
        return (alignmentNorm * 0.35) + (accuracyNorm * 0.25) + (blendNorm * 0.15) + (sampleQuality * 0.25)
    }

    private func splitRoute(_ route: [GeoCoordinate], chunks: Int) -> [[GeoCoordinate]] {
        guard chunks > 1, !route.isEmpty else { return Array(repeating: route, count: max(1, chunks)) }
        let count = route.count
        return (0..<chunks).map { index in
            let start = (count * index) / chunks
            let end = (count * (index + 1)) / chunks
            if start >= end {
                return [route[min(start, count - 1)]]
            }
            return Array(route[start..<end])
        }
    }

    private func splitTelemetry(_ telemetry: LapTelemetrySummary, chunks: Int) -> [LapTelemetrySummary] {
        guard chunks > 1 else { return [telemetry] }
        let baseSamples = telemetry.sampleCount / chunks
        let remainderSamples = telemetry.sampleCount % chunks
        return (0..<chunks).map { index in
            let sampleCount = baseSamples + (index < remainderSamples ? 1 : 0)
            return LapTelemetrySummary(
                maxLongitudinalAccel: telemetry.maxLongitudinalAccel,
                maxLateralAccel: telemetry.maxLateralAccel,
                maxYawRate: telemetry.maxYawRate,
                averageSpeedMPS: telemetry.averageSpeedMPS,
                peakSpeedMPS: telemetry.peakSpeedMPS,
                distanceMeters: telemetry.distanceMeters / Double(chunks),
                sampleCount: sampleCount
            )
        }
    }

    private func updateCurrentLapTelemetry(with sample: TelemetrySample, quality: Double) {
        currentLapSpeedSum += sample.speedMPS * quality
        currentLapQualityWeightSum += quality
        currentLapPeakSpeed = max(currentLapPeakSpeed, sample.speedMPS)
        currentLapSampleCount += quality >= 0.5 ? 1 : 0

        if let previousSample {
            let previous = CLLocation(
                latitude: previousSample.coordinate.latitude,
                longitude: previousSample.coordinate.longitude
            )
            let current = CLLocation(
                latitude: sample.coordinate.latitude,
                longitude: sample.coordinate.longitude
            )
            currentLapDistanceMeters += current.distance(from: previous)
        }

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
        currentLapSpeedSum = 0
        currentLapQualityWeightSum = 0
        currentLapPeakSpeed = 0
        currentLapDistanceMeters = 0
        currentLapSampleCount = 0
        currentLapRoute = []
    }
}
