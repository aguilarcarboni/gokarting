import Foundation

enum HeatType: String, CaseIterable, Codable {
    case timeTrial
    case quali
    case race
    case practice
}

struct Heat: Identifiable, Hashable, Codable {
    let id: UUID
    private(set) var identifier: String
    private(set) var type: HeatType
    private(set) var carNumber: String?
    private(set) var track: Track
    private(set) var kart: Kart
    private(set) var laps: [Lap]
    private(set) var date: Date

    static let minimumLaps = 1
    static let maximumLaps = 200

    var availableKarts: [Kart] {
        track.availableKarts
    }

    var lapCount: Int {
        laps.count
    }

    init(
        id: UUID = UUID(),
        identifier: String = "",
        type: HeatType = .timeTrial,
        carNumber: String? = nil,
        track: Track,
        kart: Kart,
        laps: [Lap],
        date: Date = Date()
    ) {
        self.id = id
        self.identifier = identifier
        self.type = type
        self.carNumber = carNumber
        self.track = track

        self.kart = track.availableKarts.contains(kart)
            ? kart
            : track.defaultKart

        self.laps = Self.normalizeLaps(laps, track: self.track, kart: self.kart)
        self.date = date
    }

    init(
        id: UUID = UUID(),
        identifier: String = "",
        type: HeatType = .timeTrial,
        carNumber: String? = nil,
        track: Track,
        kart: Kart,
        lapDurations: [TimeInterval],
        date: Date = Date()
    ) {
        let mappedLaps = lapDurations.enumerated().map { index, duration in
            Lap(track: track, kart: kart, lapNumber: index + 1, duration: duration, timestamp: date)
        }
        self.init(id: id, identifier: identifier, type: type, carNumber: carNumber, track: track, kart: kart, laps: mappedLaps, date: date)
    }

    mutating func pickTrack(_ track: Track) {
        self.track = track
        if !track.availableKarts.contains(kart) {
            kart = track.defaultKart
        }
    }

    mutating func pickKart(_ kart: Kart) {
        guard track.availableKarts.contains(kart) else { return }
        self.kart = kart
    }

    mutating func replaceLaps(_ laps: [Lap]) {
        self.laps = Self.normalizeLaps(laps, track: track, kart: kart)
    }

    mutating func inheritCombo(track: Track, kart: Kart) {
        pickTrack(track)
        pickKart(kart)
        laps = laps.map { lap in
            var inherited = lap
            inherited.inheritCombo(track: self.track, kart: self.kart)
            return inherited
        }
    }

    private static func normalizeLaps(_ laps: [Lap], track: Track, kart: Kart) -> [Lap] {
        let capped = Array(laps.prefix(maximumLaps)).map { lap in
            var inherited = lap
            inherited.inheritCombo(track: track, kart: kart)
            return inherited
        }
        if capped.isEmpty {
            return [Lap(track: track, kart: kart, lapNumber: 1, duration: 0)]
        }
        return capped
    }
}
