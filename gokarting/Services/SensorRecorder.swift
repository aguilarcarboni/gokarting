import Foundation
import CoreLocation
import CoreMotion
import Combine

@MainActor
final class SensorRecorder: NSObject, ObservableObject {
    @Published private(set) var latestSample: TelemetrySample?
    @Published private(set) var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published private(set) var isRunning = false
    @Published private(set) var locationServicesEnabled = CLLocationManager.locationServicesEnabled()
    @Published private(set) var accelerometerAvailable = false
    @Published private(set) var gyroscopeAvailable = false
    @Published private(set) var lastLocationTimestamp: Date?
    @Published private(set) var lastAccelerometerTimestamp: Date?
    @Published private(set) var lastGyroTimestamp: Date?
    @Published private(set) var lastLocationError: String?

    var onSample: ((TelemetrySample) -> Void)?
    var onMotionSample: ((MotionTelemetrySample) -> Void)?

    private let locationManager = CLLocationManager()
    private let motionManager = CMMotionManager()
    private let motionQueue: OperationQueue = {
        let queue = OperationQueue()
        queue.name = "motion.queue"
        queue.qualityOfService = .userInitiated
        return queue
    }()

    private var latestAcceleration: (x: Double, y: Double, z: Double)?
    private var latestYawRate: Double?
    private var latestLocationSnapshot: LocationSnapshot?
    private var lastAccelerometerLogAt: Date?
    private var lastGyroLogAt: Date?
    private var lastLocationLogAt: Date?
    private let motionLogIntervalSeconds: TimeInterval = 1.0
    private let locationLogIntervalSeconds: TimeInterval = 0.25

    private struct LocationSnapshot {
        let coordinate: CLLocationCoordinate2D
        let speedMPS: Double
        let courseDegrees: Double?
        let horizontalAccuracyMeters: Double
    }

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        locationManager.activityType = .automotiveNavigation
        locationManager.distanceFilter = kCLDistanceFilterNone
        locationManager.pausesLocationUpdatesAutomatically = false
        accelerometerAvailable = motionManager.isAccelerometerAvailable
        gyroscopeAvailable = motionManager.isGyroAvailable
    }

    func requestPermissions() {
        locationManager.requestWhenInUseAuthorization()
    }

    func start() {
        isRunning = true
        locationServicesEnabled = CLLocationManager.locationServicesEnabled()
        requestPermissions()
        startMotionUpdatesIfAvailable()

        if authorizationStatus == .authorizedAlways || authorizationStatus == .authorizedWhenInUse {
            locationManager.startUpdatingLocation()
            locationManager.startUpdatingHeading()
        }
    }

    func stop() {
        isRunning = false
        locationManager.stopUpdatingLocation()
        locationManager.stopUpdatingHeading()
        motionManager.stopAccelerometerUpdates()
        motionManager.stopGyroUpdates()
        motionManager.stopDeviceMotionUpdates()
    }

    private func startMotionUpdatesIfAvailable() {
        if motionManager.isDeviceMotionAvailable {
            motionManager.deviceMotionUpdateInterval = 1.0 / 20.0
            motionManager.startDeviceMotionUpdates(to: motionQueue) { [weak self] update, _ in
                guard let data = update else { return }
                Task { @MainActor in
                    guard let self else { return }
                    let now = Date()
                    self.latestAcceleration = (
                        x: data.userAcceleration.x,
                        y: data.userAcceleration.y,
                        z: data.userAcceleration.z
                    )
                    self.latestYawRate = data.rotationRate.z
                    self.lastAccelerometerTimestamp = now
                    self.lastGyroTimestamp = now
                    self.logAccelerometerIfNeeded(data.userAcceleration, at: now)
                    self.logGyroIfNeeded(data.rotationRate, at: now)
                    self.emitMotionSample(at: now)
                }
            }
            return
        }

        if motionManager.isAccelerometerAvailable && motionManager.isGyroAvailable {
            motionManager.accelerometerUpdateInterval = 1.0 / 20.0
            motionManager.gyroUpdateInterval = 1.0 / 20.0
            motionManager.startAccelerometerUpdates(to: motionQueue) { [weak self] update, _ in
                guard let data = update?.acceleration else { return }
                Task { @MainActor in
                    self?.latestAcceleration = (x: data.x, y: data.y, z: data.z)
                    guard let self else { return }
                    let now = Date()
                    self.lastAccelerometerTimestamp = now
                    self.logAccelerometerIfNeeded(data, at: now)
                    self.emitMotionSample(at: now)
                }
            }
            motionManager.startGyroUpdates(to: motionQueue) { [weak self] update, _ in
                guard let data = update?.rotationRate else { return }
                Task { @MainActor in
                    guard let self else { return }
                    let now = Date()
                    self.latestYawRate = data.z
                    self.lastGyroTimestamp = now
                    self.logGyroIfNeeded(data, at: now)
                    self.emitMotionSample(at: now)
                }
            }
        }
    }

    private func emitMotionSample(at timestamp: Date) {
        guard let acceleration = latestAcceleration, let yawRate = latestYawRate else { return }
        let snapshot = latestLocationSnapshot
        let sample = MotionTelemetrySample(
            timestamp: timestamp,
            accelerationX: acceleration.x,
            accelerationY: acceleration.y,
            accelerationZ: acceleration.z,
            yawRate: yawRate,
            latitude: snapshot?.coordinate.latitude,
            longitude: snapshot?.coordinate.longitude,
            speedMPS: snapshot?.speedMPS,
            courseDegrees: snapshot?.courseDegrees,
            horizontalAccuracyMeters: snapshot?.horizontalAccuracyMeters
        )
        onMotionSample?(sample)
    }

    private func logAccelerometerIfNeeded(_ acceleration: CMAcceleration, at now: Date) {
        guard shouldLog(lastLoggedAt: lastAccelerometerLogAt, now: now, minInterval: motionLogIntervalSeconds) else { return }
        lastAccelerometerLogAt = now
        print(
            String(
                format: "[Sensor][ACCEL] x: %.3f y: %.3f z: %.3f",
                acceleration.x,
                acceleration.y,
                acceleration.z
            )
        )
    }

    private func logGyroIfNeeded(_ rotationRate: CMRotationRate, at now: Date) {
        guard shouldLog(lastLoggedAt: lastGyroLogAt, now: now, minInterval: motionLogIntervalSeconds) else { return }
        lastGyroLogAt = now
        print(
            String(
                format: "[Sensor][GYRO] x: %.3f y: %.3f z(yaw): %.3f rad/s",
                rotationRate.x,
                rotationRate.y,
                rotationRate.z
            )
        )
    }

    private func logLocationIfNeeded(_ location: CLLocation, speed: Double, course: Double?, at now: Date) {
        guard shouldLog(lastLoggedAt: lastLocationLogAt, now: now, minInterval: locationLogIntervalSeconds) else { return }
        lastLocationLogAt = now
        let courseText = course.map { String(format: "%.1f°", $0) } ?? "n/a"
        print(
            String(
                format: "[Sensor][GPS] lat: %.6f lon: %.6f speed: %.2f m/s acc: %.1f m course: %@",
                location.coordinate.latitude,
                location.coordinate.longitude,
                speed,
                location.horizontalAccuracy,
                courseText
            )
        )
    }

    private func shouldLog(lastLoggedAt: Date?, now: Date, minInterval: TimeInterval) -> Bool {
        guard let lastLoggedAt else { return true }
        return now.timeIntervalSince(lastLoggedAt) >= minInterval
    }
}

extension SensorRecorder: CLLocationManagerDelegate {
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
        locationServicesEnabled = CLLocationManager.locationServicesEnabled()

        guard isRunning else { return }
        if authorizationStatus == .authorizedAlways || authorizationStatus == .authorizedWhenInUse {
            manager.startUpdatingLocation()
            manager.startUpdatingHeading()
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        for location in locations {
            let speed = max(0, location.speed)
            let course: Double? = location.course >= 0 ? location.course : nil
            logLocationIfNeeded(location, speed: speed, course: course, at: Date())
            let sample = TelemetrySample(
                coordinate: GeoCoordinate(location.coordinate),
                timestamp: location.timestamp,
                speedMPS: speed,
                courseDegrees: course,
                horizontalAccuracyMeters: location.horizontalAccuracy,
                accelerationX: latestAcceleration?.x,
                accelerationY: latestAcceleration?.y,
                accelerationZ: latestAcceleration?.z,
                yawRate: latestYawRate
            )

            latestSample = sample
            latestLocationSnapshot = LocationSnapshot(
                coordinate: location.coordinate,
                speedMPS: speed,
                courseDegrees: course,
                horizontalAccuracyMeters: location.horizontalAccuracy
            )
            lastLocationTimestamp = location.timestamp
            lastLocationError = nil
            onSample?(sample)
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: any Error) {
        lastLocationError = error.localizedDescription
    }
}
