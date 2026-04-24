import Foundation

struct LapTelemetry: Hashable, Codable {
    let maxLongitudinalAccel: Double
    let maxLateralAccel: Double
    let maxYawRate: Double
    let averageSpeedMPS: Double
    let peakSpeedMPS: Double
    let distanceMeters: Double
    let sampleCount: Int
}

struct Lap: Identifiable, Hashable, Codable {
    let id: UUID
    private(set) var track: Track
    private(set) var kart: Kart
    let competitorID: String?
    let driverName: String?
    let driverNumber: String?
    let lapNumber: Int
    let duration: TimeInterval
    let timestamp: Date
    let crossedAt: Date?
    let speedAtCrossingMPS: Double?
    let telemetry: LapTelemetry?
    let route: [GeoCoordinate]

    init(
        id: UUID = UUID(),
        track: Track,
        kart: Kart,
        competitorID: String? = nil,
        driverName: String? = nil,
        driverNumber: String? = nil,
        lapNumber: Int,
        duration: TimeInterval,
        timestamp: Date = Date(),
        crossedAt: Date? = nil,
        speedAtCrossingMPS: Double? = nil,
        telemetry: LapTelemetry? = nil,
        route: [GeoCoordinate] = []
    ) {
        self.id = id
        self.track = track
        self.kart = kart
        self.competitorID = competitorID
        self.driverName = driverName
        self.driverNumber = driverNumber
        self.lapNumber = lapNumber
        self.duration = duration
        self.timestamp = timestamp
        self.crossedAt = crossedAt
        self.speedAtCrossingMPS = speedAtCrossingMPS
        self.telemetry = telemetry
        self.route = route
    }

    mutating func inheritCombo(track: Track, kart: Kart) {
        self.track = track
        self.kart = kart
    }
}
