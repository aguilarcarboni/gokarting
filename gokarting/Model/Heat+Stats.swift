import Foundation

extension Heat {
    var bestLap: TimeInterval? {
        bestLap(in: laps)
    }

    var averageLap: TimeInterval? {
        averageLap(in: laps)
    }

    var medianLap: TimeInterval? {
        medianLap(in: laps)
    }

    var consistency: TimeInterval? {
        consistency(in: laps)
    }

    func firstLapsAverage(count: Int) -> TimeInterval? {
        firstLapsAverage(in: laps, count: count)
    }

    func lastLapsAverage(count: Int) -> TimeInterval? {
        lastLapsAverage(in: laps, count: count)
    }

    func bestLap(for competitor: HeatCompetitor?) -> TimeInterval? {
        bestLap(in: laps(for: competitor))
    }

    func averageLap(for competitor: HeatCompetitor?) -> TimeInterval? {
        averageLap(in: laps(for: competitor))
    }

    func medianLap(for competitor: HeatCompetitor?) -> TimeInterval? {
        medianLap(in: laps(for: competitor))
    }

    func consistency(for competitor: HeatCompetitor?) -> TimeInterval? {
        consistency(in: laps(for: competitor))
    }

    func firstLapsAverage(for competitor: HeatCompetitor?, count: Int) -> TimeInterval? {
        firstLapsAverage(in: laps(for: competitor), count: count)
    }

    func lastLapsAverage(for competitor: HeatCompetitor?, count: Int) -> TimeInterval? {
        lastLapsAverage(in: laps(for: competitor), count: count)
    }

    func sortedCompetitorsByBestLap() -> [HeatCompetitor] {
        competitors.sorted { lhs, rhs in
            let lhsBest = bestLap(for: lhs)
            let rhsBest = bestLap(for: rhs)

            switch (lhsBest, rhsBest) {
            case let (l?, r?):
                return l < r
            case (_?, nil):
                return true
            case (nil, _?):
                return false
            case (nil, nil):
                return lhs.displayName < rhs.displayName
            }
        }
    }

    func sortedCompetitorsForHeatType() -> [HeatCompetitor] {
        switch type {
        case .race:
            return competitors.sorted { lhs, rhs in
                let lhsLaps = laps(for: lhs).count
                let rhsLaps = laps(for: rhs).count
                if lhsLaps != rhsLaps {
                    return lhsLaps > rhsLaps
                }

                let lhsTotal = totalTime(for: lhs)
                let rhsTotal = totalTime(for: rhs)
                if lhsTotal != rhsTotal {
                    return lhsTotal < rhsTotal
                }

                let lhsBest = bestLap(for: lhs)
                let rhsBest = bestLap(for: rhs)
                switch (lhsBest, rhsBest) {
                case let (l?, r?):
                    return l < r
                case (_?, nil):
                    return true
                case (nil, _?):
                    return false
                case (nil, nil):
                    return lhs.displayName < rhs.displayName
                }
            }
        case .quali, .timeTrial, .practice:
            return sortedCompetitorsByBestLap()
        }
    }

    private func laps(for competitor: HeatCompetitor?) -> [Lap] {
        guard let competitor else { return laps }
        return laps(for: competitor)
    }

    private func bestLap(in laps: [Lap]) -> TimeInterval? {
        laps.map(\.duration).min()
    }

    private func totalTime(for competitor: HeatCompetitor) -> TimeInterval {
        laps(for: competitor).reduce(0) { $0 + $1.duration }
    }

    private func averageLap(in laps: [Lap]) -> TimeInterval? {
        guard !laps.isEmpty else { return nil }
        let total = laps.reduce(0.0) { $0 + $1.duration }
        return total / Double(laps.count)
    }

    private func medianLap(in laps: [Lap]) -> TimeInterval? {
        let values = laps.map(\.duration).sorted()
        guard !values.isEmpty else { return nil }
        let mid = values.count / 2
        if values.count.isMultiple(of: 2) {
            return (values[mid - 1] + values[mid]) / 2
        }
        return values[mid]
    }

    private func consistency(in laps: [Lap]) -> TimeInterval? {
        guard let avg = averageLap(in: laps), laps.count > 1 else { return nil }
        let variance = laps.reduce(0.0) { partial, lap in
            let diff = lap.duration - avg
            return partial + (diff * diff)
        } / Double(laps.count)
        return sqrt(variance)
    }

    private func firstLapsAverage(in laps: [Lap], count: Int) -> TimeInterval? {
        let subset = laps.sorted(by: { $0.lapNumber < $1.lapNumber }).prefix(count)
        guard !subset.isEmpty else { return nil }
        let total = subset.reduce(0.0) { $0 + $1.duration }
        return total / Double(subset.count)
    }

    private func lastLapsAverage(in laps: [Lap], count: Int) -> TimeInterval? {
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
