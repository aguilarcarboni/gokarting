import Foundation
import SwiftData

@Model
final class Session {
    var id: UUID
    var date: Date
    var note: String?
    var track: Track?
    
    @Relationship(deleteRule: .cascade, inverse: \Lap.session)
    var laps: [Lap] = []
    
    init(date: Date = Date(), note: String? = nil, track: Track? = nil) {
        self.id = UUID()
        self.date = date
        self.note = note
        self.track = track
    }
    
    // Computed properties for stats
    var bestLap: TimeInterval? {
        laps.map { $0.duration }.min()
    }
    
    var averageLap: TimeInterval? {
        guard !laps.isEmpty else { return nil }
        let total = laps.reduce(0) { $0 + $1.duration }
        return total / Double(laps.count)
    }
    
    var consistency: Double? {
        guard laps.count > 1, let avg = averageLap else { return nil }
        let sumOfSquaredDiffs = laps.reduce(0) { $0 + pow($1.duration - avg, 2) }
        return sqrt(sumOfSquaredDiffs / Double(laps.count))
    }
    
    var averageLapClean: TimeInterval? {
        let durations = laps.map { $0.duration }.sorted()
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
}
