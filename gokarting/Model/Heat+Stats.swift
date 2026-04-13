import Foundation

extension Heat {
    var bestLap: TimeInterval? {
        laps.map(\.duration).min()
    }

    var averageLap: TimeInterval? {
        guard !laps.isEmpty else { return nil }
        let total = laps.reduce(0.0) { $0 + $1.duration }
        return total / Double(laps.count)
    }

    var medianLap: TimeInterval? {
        let values = laps.map(\.duration).sorted()
        guard !values.isEmpty else { return nil }
        let mid = values.count / 2
        if values.count.isMultiple(of: 2) {
            return (values[mid - 1] + values[mid]) / 2
        }
        return values[mid]
    }

    var consistency: TimeInterval? {
        guard let avg = averageLap, laps.count > 1 else { return nil }
        let variance = laps.reduce(0.0) { partial, lap in
            let diff = lap.duration - avg
            return partial + (diff * diff)
        } / Double(laps.count)
        return sqrt(variance)
    }

    func firstLapsAverage(count: Int) -> TimeInterval? {
        let subset = laps.sorted(by: { $0.lapNumber < $1.lapNumber }).prefix(count)
        guard !subset.isEmpty else { return nil }
        let total = subset.reduce(0.0) { $0 + $1.duration }
        return total / Double(subset.count)
    }

    func lastLapsAverage(count: Int) -> TimeInterval? {
        let subset = laps.sorted(by: { $0.lapNumber < $1.lapNumber }).suffix(count)
        guard !subset.isEmpty else { return nil }
        let total = subset.reduce(0.0) { $0 + $1.duration }
        return total / Double(subset.count)
    }
}

extension HeatType {
    var label: String {
        switch self {
        case .timeTrial:
            return "Time Trial"
        case .quali:
            return "Qualifying"
        case .race:
            return "Race"
        case .practice:
            return "Practice"
        }
    }
}
