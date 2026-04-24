import Foundation

enum Track: String, CaseIterable, Codable {
    case fik = "FIK"
    case formulaKart = "Formula Kart"
    case p1Speedway = "P1 Speedway (Medium)"
    case p1ShortConfig = "P1 Speedway (Short)"
    case p1SpeedwayInverse = "P1 Speedway (Inverse)"
    case test = "test"

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let value = try container.decode(String.self)
        switch value {
        case Track.p1Speedway.rawValue, "P1 Speedway":
            self = .p1Speedway
        case Track.p1ShortConfig.rawValue, "P1 (Short Config)":
            self = .p1ShortConfig
        case Track.p1SpeedwayInverse.rawValue:
            self = .p1SpeedwayInverse
        case Track.fik.rawValue:
            self = .fik
        case Track.formulaKart.rawValue:
            self = .formulaKart
        case Track.test.rawValue:
            self = .test
        default:
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Invalid Track value: \(value)"
            )
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }
}

enum Kart: String, CaseIterable, Codable {
    case fikKart = "FIK Kart"
    case fkKart = "FK Kart"
    case sodiRental = "Sodi Rental"
    case tillotsonT4 = "Tillotson T4"
}

struct TrackKartCombo: Hashable, Identifiable {
    let track: Track
    let kart: Kart

    var id: String { "\(track.rawValue)|\(kart.rawValue)" }
    var displayName: String { "\(track.rawValue) • \(kart.rawValue)" }

    static var allCases: [TrackKartCombo] {
        Track.allCases.flatMap { track in
            track.availableKarts.map { kart in
                TrackKartCombo(track: track, kart: kart)
            }
        }
    }
}

extension Track {
    var gatePoints: (pointA: GeoCoordinate, pointB: GeoCoordinate) {
        switch self {
        case .p1Speedway:
            return (
                pointA: GeoCoordinate(latitude: 9.961719, longitude: -84.134378),
                pointB: GeoCoordinate(latitude: 9.961654, longitude: -84.134288)
            )
        case .p1ShortConfig:
            return (
                pointA: GeoCoordinate(latitude: 9.961719, longitude: -84.134378),
                pointB: GeoCoordinate(latitude: 9.961654, longitude: -84.134288)
            )
        case .p1SpeedwayInverse:
            return (
                pointA: GeoCoordinate(latitude: 9.961719, longitude: -84.134378),
                pointB: GeoCoordinate(latitude: 9.961654, longitude: -84.134288)
            )
        case .fik:
            return (
                pointA: GeoCoordinate(latitude: 9.96260, longitude: -84.19974),
                pointB: GeoCoordinate(latitude: 9.96258, longitude: -84.19973)
            )
        case .formulaKart:
            return (
                pointA: GeoCoordinate(latitude: 9.92237, longitude: -84.03611),
                pointB: GeoCoordinate(latitude: 9.92233, longitude: -84.03616)
            )
        case .test:
            return (
                pointA: GeoCoordinate(latitude: 9.93727, longitude: -84.19439),
                pointB: GeoCoordinate(latitude: 9.93722, longitude: -84.19447)
            )
        }
    }

    var availableKarts: [Kart] {
        switch self {
        case .fik:
            return [.fikKart]
        case .formulaKart:
            return [.fkKart]
        case .p1Speedway:
            return [.sodiRental, .tillotsonT4]
        case .p1ShortConfig:
            return [.sodiRental]
        case .p1SpeedwayInverse:
            return [.sodiRental, .tillotsonT4]
        case .test:
            return [.sodiRental]
        }
    }

    var defaultKart: Kart {
        availableKarts.first ?? .fikKart
    }

    var supportedRaceDirections: [RaceDirection] {
        switch self {
        case .p1SpeedwayInverse, .fik:
            return [.clockwise]
        case .p1Speedway, .p1ShortConfig, .test, .formulaKart:
            return [.counterClockwise]
        }
    }

    var defaultRaceDirection: RaceDirection {
        supportedRaceDirections.first ?? .clockwise
    }
}
