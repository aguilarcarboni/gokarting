import Foundation

enum HeatType: String, CaseIterable, Codable {
    case timeTrial
    case quali
    case race
    case practice
}

struct LiveSessionMetadata: Hashable, Codable {
    let source: String
    let startedAt: Date
    let endedAt: Date
    let durationSeconds: TimeInterval
    let raceDirection: RaceDirection
    let gateCrossingsCount: Int
    let sampleCount: Int
    let totalDistanceMeters: Double
    let averageSpeedMPS: Double
    let peakSpeedMPS: Double
    let peakAccelerationG: Double
    let peakDecelerationG: Double
    let peakYawRate: Double
}

struct HeatCompetitor: Identifiable, Hashable {
    let id: String
    let competitorID: String?
    let driverNumber: String?
    let driverName: String?

    var displayName: String {
        if let driverName, !driverName.isEmpty {
            if let driverNumber, !driverNumber.isEmpty {
                return "#\(driverNumber) \(driverName)"
            }
            return driverName
        }

        if let driverNumber, !driverNumber.isEmpty {
            return "Driver #\(driverNumber)"
        }

        return "Unknown Driver"
    }
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
    private(set) var sessionMetadata: LiveSessionMetadata?

    static let minimumLaps = 1
    static let maximumLaps = 200

    var availableKarts: [Kart] {
        track.availableKarts
    }

    var lapCount: Int {
        laps.count
    }

    var competitors: [HeatCompetitor] {
        if type == .timeTrial {
            return [HeatCompetitor(id: "you", competitorID: "you", driverNumber: nil, driverName: "You")]
        }

        var seen = Set<String>()
        var unique: [HeatCompetitor] = []

        for lap in laps {
            let key = competitorKey(for: lap)
            guard !seen.contains(key) else { continue }
            seen.insert(key)
            unique.append(
                HeatCompetitor(
                    id: key,
                    competitorID: lap.competitorID,
                    driverNumber: lap.driverNumber,
                    driverName: lap.driverName
                )
            )
        }

        return unique
    }

    init(
        id: UUID = UUID(),
        identifier: String = "",
        type: HeatType = .timeTrial,
        carNumber: String? = nil,
        track: Track,
        kart: Kart,
        laps: [Lap],
        date: Date = Date(),
        sessionMetadata: LiveSessionMetadata? = nil
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
        self.sessionMetadata = sessionMetadata
    }

    init(
        id: UUID = UUID(),
        identifier: String = "",
        type: HeatType = .timeTrial,
        carNumber: String? = nil,
        track: Track,
        kart: Kart,
        lapDurations: [TimeInterval],
        date: Date = Date(),
        sessionMetadata: LiveSessionMetadata? = nil
    ) {
        let mappedLaps = lapDurations.enumerated().map { index, duration in
            Lap(track: track, kart: kart, lapNumber: index + 1, duration: duration, timestamp: date)
        }
        self.init(
            id: id,
            identifier: identifier,
            type: type,
            carNumber: carNumber,
            track: track,
            kart: kart,
            laps: mappedLaps,
            date: date,
            sessionMetadata: sessionMetadata
        )
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

    func laps(for competitor: HeatCompetitor) -> [Lap] {
        if type == .timeTrial {
            return laps
        }
        return laps.filter { competitorKey(for: $0) == competitor.id }
    }

    func competitor(for lap: Lap) -> HeatCompetitor {
        if type == .timeTrial {
            return HeatCompetitor(id: "you", competitorID: "you", driverNumber: nil, driverName: "You")
        }
        return HeatCompetitor(
            id: competitorKey(for: lap),
            competitorID: lap.competitorID,
            driverNumber: lap.driverNumber,
            driverName: lap.driverName
        )
    }

    private func competitorKey(for lap: Lap) -> String {
        if type == .timeTrial {
            return "you"
        }

        if let competitorID = lap.competitorID, !competitorID.isEmpty {
            return "id:\(competitorID)"
        }
        if let driverNumber = lap.driverNumber, !driverNumber.isEmpty {
            return "num:\(driverNumber)"
        }
        if let driverName = lap.driverName, !driverName.isEmpty {
            return "name:\(driverName)"
        }
        return "unknown"
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
