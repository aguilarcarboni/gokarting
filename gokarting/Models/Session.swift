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
