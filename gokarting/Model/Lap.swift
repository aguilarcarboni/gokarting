import Foundation

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

    init(
        id: UUID = UUID(),
        track: Track,
        kart: Kart,
        competitorID: String? = nil,
        driverName: String? = nil,
        driverNumber: String? = nil,
        lapNumber: Int,
        duration: TimeInterval,
        timestamp: Date = Date()
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
    }

    mutating func inheritCombo(track: Track, kart: Kart) {
        self.track = track
        self.kart = kart
    }
}
