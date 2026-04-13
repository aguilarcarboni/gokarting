import Foundation

enum Track: String, CaseIterable, Codable {
    case fik = "FIK"
    case formulaKart = "Formula Kart"
    case p1Speedway = "P1 Speedway (Medium)"
    case p1ShortConfig = "P1 Speedway (Short)"
    case p1SpeedwayInverse = "P1 Speedway (Inverse)"

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
        }
    }

    var defaultKart: Kart {
        availableKarts.first ?? .fikKart
    }
}
