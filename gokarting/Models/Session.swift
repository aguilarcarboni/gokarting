import Foundation
import SwiftData

@Model
final class Session {
    var id: UUID = UUID()
    var date: Date = Date()
    var note: String? = nil
    var track: Track? = nil
    var kart: Kart? = nil
    var seedIdentifier: String? = nil
    
    @Relationship(deleteRule: .cascade, inverse: \Lap.session)
    var laps: [Lap]? = nil
    
    init(
        date: Date = Date(),
        note: String? = nil,
        track: Track? = nil,
        kart: Kart? = nil,
        seedIdentifier: String? = nil
    ) {
        self.id = UUID()
        self.date = date
        self.note = note
        self.track = track
        self.kart = kart
        self.seedIdentifier = seedIdentifier
    }
    
    /// Convenience accessor that unwraps the optional relationship.
    var safeLaps: [Lap] {
        laps ?? []
    }

    var effectiveKart: Kart? {
        if let kart {
            return kart
        }
        guard let track else {
            return nil
        }
        return track.defaultKart
    }

    var trackKartCombo: TrackKartCombo? {
        guard let track, let kart = effectiveKart else {
            return nil
        }
        return TrackKartCombo(track: track, kart: kart)
    }
    
    // Computed properties for stats
    var bestLap: TimeInterval? {
        safeLaps.map { $0.duration }.min()
    }
    
    var averageLap: TimeInterval? {
        guard !safeLaps.isEmpty else { return nil }
        let total = safeLaps.reduce(0) { $0 + $1.duration }
        return total / Double(safeLaps.count)
    }
    
    var consistency: Double? {
        guard safeLaps.count > 1, let avg = averageLap else { return nil }
        let sumOfSquaredDiffs = safeLaps.reduce(0) { $0 + pow($1.duration - avg, 2) }
        return sqrt(sumOfSquaredDiffs / Double(safeLaps.count))
    }
    
    var averageLapClean: TimeInterval? {
        let durations = safeLaps.map { $0.duration }.sorted()
        guard durations.count >= 5 else { return averageLap }
        
        let q1 = durations[Int(Double(durations.count) * 0.25)]
        let q3 = durations[Int(Double(durations.count) * 0.75)]
        let iqr = q3 - q1
        
        let upperBound = q3 + (1.5 * iqr)
        let lowerBound = q1 - (1.5 * iqr)
        
        let cleanLaps = durations.filter { $0 >= lowerBound && $0 <= upperBound }
        
        guard !cleanLaps.isEmpty else { return averageLap }
        return cleanLaps.reduce(0, +) / Double(cleanLaps.count)
    }

    var medianLap: TimeInterval? {
        let durations = safeLaps.map(\.duration).sorted()
        guard !durations.isEmpty else { return nil }

        let middle = durations.count / 2
        if durations.count.isMultiple(of: 2) {
            return (durations[middle - 1] + durations[middle]) / 2
        } else {
            return durations[middle]
        }
    }

    /// Average of the first `count` laps, used as opening race pace.
    func firstLapsAverage(count: Int = 5) -> TimeInterval? {
        let durations = safeLaps.sorted(by: { $0.lapNumber < $1.lapNumber }).map(\.duration)
        guard !durations.isEmpty else { return nil }
        let sampleCount = min(count, durations.count)
        let slice = durations.prefix(sampleCount)
        return slice.reduce(0, +) / Double(sampleCount)
    }

    /// Average of the last `count` laps, used as closing race pace.
    func lastLapsAverage(count: Int = 5) -> TimeInterval? {
        let durations = safeLaps.sorted(by: { $0.lapNumber < $1.lapNumber }).map(\.duration)
        guard !durations.isEmpty else { return nil }
        let sampleCount = min(count, durations.count)
        let slice = durations.suffix(sampleCount)
        return slice.reduce(0, +) / Double(sampleCount)
    }

    /// Positive value means pace dropped (slower at the end), negative means improved.
    var paceDeltaLastVsFirstFive: TimeInterval? {
        guard let first = firstLapsAverage(count: 5),
              let last = lastLapsAverage(count: 5) else { return nil }
        return last - first
    }

    /// Percent of laps that are retained by the current IQR clean-lap logic.
    var cleanLapRatio: Double? {
        let durations = safeLaps.map(\.duration).sorted()
        guard !durations.isEmpty else { return nil }
        guard durations.count >= 5 else { return 1.0 }

        let q1 = durations[Int(Double(durations.count) * 0.25)]
        let q3 = durations[Int(Double(durations.count) * 0.75)]
        let iqr = q3 - q1
        let upperBound = q3 + (1.5 * iqr)
        let lowerBound = q1 - (1.5 * iqr)

        let cleanCount = durations.filter { $0 >= lowerBound && $0 <= upperBound }.count
        return Double(cleanCount) / Double(durations.count)
    }
}

enum RaceSessionType: Int, CaseIterable, Codable {
    case race = 0
    case practice = 1
    case quali = 2
    case unknown = -1

    init(runTypeRawValue: Int) {
        self = RaceSessionType(rawValue: runTypeRawValue) ?? .unknown
    }
}

@Model
final class RaceEvent {
    var id: UUID = UUID()
    var eventId: String = ""
    var name: String = ""
    var date: Date = Date()
    var location: String? = nil
    var trackName: String? = nil
    var trackLengthKM: Double? = nil
    var track: Track? = nil

    @Relationship(deleteRule: .cascade, inverse: \RaceSession.event)
    var sessions: [RaceSession]? = nil

    init(
        eventId: String,
        name: String,
        date: Date,
        location: String? = nil,
        trackName: String? = nil,
        trackLengthKM: Double? = nil,
        track: Track? = nil
    ) {
        self.id = UUID()
        self.eventId = eventId
        self.name = name
        self.date = date
        self.location = location
        self.trackName = trackName
        self.trackLengthKM = trackLengthKM
        self.track = track
    }
}

@Model
final class RaceSession {
    var id: UUID = UUID()
    var sessionId: String = ""
    var day: String? = nil
    var runName: String = ""
    var runTypeRaw: Int = RaceSessionType.unknown.rawValue
    var startTime: Date = Date()
    var bestLapTime: TimeInterval? = nil

    var event: RaceEvent? = nil

    @Relationship(deleteRule: .cascade, inverse: \RaceSessionStats.session)
    var stats: RaceSessionStats? = nil

    @Relationship(deleteRule: .cascade, inverse: \RaceResult.session)
    var results: [RaceResult]? = nil

    @Relationship(deleteRule: .cascade, inverse: \RaceCompetitorLap.session)
    var competitorLaps: [RaceCompetitorLap]? = nil

    init(
        sessionId: String,
        day: String? = nil,
        runName: String,
        runTypeRaw: Int,
        startTime: Date,
        bestLapTime: TimeInterval? = nil
    ) {
        self.id = UUID()
        self.sessionId = sessionId
        self.day = day
        self.runName = runName
        self.runTypeRaw = runTypeRaw
        self.startTime = startTime
        self.bestLapTime = bestLapTime
    }

    var runType: RaceSessionType {
        RaceSessionType(runTypeRawValue: runTypeRaw)
    }
}

@Model
final class RaceSessionStats {
    var id: UUID = UUID()
    var bestLapDriver: String? = nil
    var bestLapTime: TimeInterval? = nil
    var totalLaps: Int? = nil
    var totalLapsLeader: Int? = nil
    var numParticipants: Int? = nil
    var numPositions: Int? = nil

    var session: RaceSession? = nil

    init(
        bestLapDriver: String? = nil,
        bestLapTime: TimeInterval? = nil,
        totalLaps: Int? = nil,
        totalLapsLeader: Int? = nil,
        numParticipants: Int? = nil,
        numPositions: Int? = nil
    ) {
        self.id = UUID()
        self.bestLapDriver = bestLapDriver
        self.bestLapTime = bestLapTime
        self.totalLaps = totalLaps
        self.totalLapsLeader = totalLapsLeader
        self.numParticipants = numParticipants
        self.numPositions = numPositions
    }
}

@Model
final class RaceResult {
    var id: UUID = UUID()
    var position: Int? = nil
    var driverName: String? = nil
    var driverNumber: String? = nil
    var competitorId: String? = nil
    var lapsCompleted: Int? = nil
    var bestLapTime: TimeInterval? = nil
    var lastLapTime: TimeInterval? = nil
    var totalTime: TimeInterval? = nil
    var gapToLeader: String? = nil
    var gapToPrevious: String? = nil
    var avgSpeed: Double? = nil
    var avgTime: TimeInterval? = nil
    var marker: Int? = nil
    var finished: Bool = false

    var session: RaceSession? = nil

    init(
        position: Int? = nil,
        driverName: String? = nil,
        driverNumber: String? = nil,
        competitorId: String? = nil,
        lapsCompleted: Int? = nil,
        bestLapTime: TimeInterval? = nil,
        lastLapTime: TimeInterval? = nil,
        totalTime: TimeInterval? = nil,
        gapToLeader: String? = nil,
        gapToPrevious: String? = nil,
        avgSpeed: Double? = nil,
        avgTime: TimeInterval? = nil,
        marker: Int? = nil,
        finished: Bool = false
    ) {
        self.id = UUID()
        self.position = position
        self.driverName = driverName
        self.driverNumber = driverNumber
        self.competitorId = competitorId
        self.lapsCompleted = lapsCompleted
        self.bestLapTime = bestLapTime
        self.lastLapTime = lastLapTime
        self.totalTime = totalTime
        self.gapToLeader = gapToLeader
        self.gapToPrevious = gapToPrevious
        self.avgSpeed = avgSpeed
        self.avgTime = avgTime
        self.marker = marker
        self.finished = finished
    }
}

@Model
final class RaceCompetitorLap {
    var id: UUID = UUID()
    var competitorId: String? = nil
    var driverName: String? = nil
    var driverNumber: String? = nil
    var lapNumber: Int? = nil
    var lapTime: TimeInterval? = nil
    var lastTimeOfDay: String? = nil
    var gapToLeader: String? = nil
    var gapToPrevious: String? = nil
    var gapToBest: String? = nil
    var isBestLap: Bool = false
    var finished: Bool = false
    var sector1: TimeInterval? = nil
    var sector2: TimeInterval? = nil
    var sector3: TimeInterval? = nil

    var session: RaceSession? = nil

    init(
        competitorId: String? = nil,
        driverName: String? = nil,
        driverNumber: String? = nil,
        lapNumber: Int? = nil,
        lapTime: TimeInterval? = nil,
        lastTimeOfDay: String? = nil,
        gapToLeader: String? = nil,
        gapToPrevious: String? = nil,
        gapToBest: String? = nil,
        isBestLap: Bool = false,
        finished: Bool = false,
        sector1: TimeInterval? = nil,
        sector2: TimeInterval? = nil,
        sector3: TimeInterval? = nil
    ) {
        self.id = UUID()
        self.competitorId = competitorId
        self.driverName = driverName
        self.driverNumber = driverNumber
        self.lapNumber = lapNumber
        self.lapTime = lapTime
        self.lastTimeOfDay = lastTimeOfDay
        self.gapToLeader = gapToLeader
        self.gapToPrevious = gapToPrevious
        self.gapToBest = gapToBest
        self.isBestLap = isBestLap
        self.finished = finished
        self.sector1 = sector1
        self.sector2 = sector2
        self.sector3 = sector3
    }
}
