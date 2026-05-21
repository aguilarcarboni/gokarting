import Foundation

struct TrackLayout: Hashable, Codable {
    let centerline: [GeoCoordinate]
    let trackWidthMeters: Double?
}

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
    var layout: TrackLayout? {
        switch self {
        case .p1ShortConfig:
            return TrackLayout(centerline: [
                GeoCoordinate(latitude: 9.961686499999999, longitude: -84.134333),
                GeoCoordinate(latitude: 9.961273846631125, longitude: -84.13460323064015),
                GeoCoordinate(latitude: 9.961257871405623, longitude: -84.13466424775481),
                GeoCoordinate(latitude: 9.961263957205892, longitude: -84.13471831355261),
                GeoCoordinate(latitude: 9.96128449678098, longitude: -84.13473993987166),
                GeoCoordinate(latitude: 9.961331661726309, longitude: -84.13476620040204),
                GeoCoordinate(latitude: 9.961405452030252, longitude: -84.13475538724246),
                GeoCoordinate(latitude: 9.961518799990493, longitude: -84.13466193064917),
                GeoCoordinate(latitude: 9.96165116601496, longitude: -84.13455379905362),
                GeoCoordinate(latitude: 9.961829936135175, longitude: -84.1344116832423),
                GeoCoordinate(latitude: 9.961860987238694, longitude: -84.13440665578933),
                GeoCoordinate(latitude: 9.96192126766667, longitude: -84.13441905137141),
                GeoCoordinate(latitude: 9.961938817662578, longitude: -84.13445081505041),
                GeoCoordinate(latitude: 9.961915926363375, longitude: -84.13450736989351),
                GeoCoordinate(latitude: 9.9617029295374, longitude: -84.13475217041744),
                GeoCoordinate(latitude: 9.961730742674963, longitude: -84.13481178582938),
                GeoCoordinate(latitude: 9.96222734465435, longitude: -84.1349127236112),
                GeoCoordinate(latitude: 9.962276855354364, longitude: -84.1349080834278),
                GeoCoordinate(latitude: 9.9625495275737, longitude: -84.13392981197495),
                GeoCoordinate(latitude: 9.96249427549866, longitude: -84.13385851666716),
                GeoCoordinate(latitude: 9.962376421980853, longitude: -84.13383009794178),
                GeoCoordinate(latitude: 9.962290241568967, longitude: -84.13389142255969),
                GeoCoordinate(latitude: 9.962285169482909, longitude: -84.13401542360147),
                GeoCoordinate(latitude: 9.962304623097612, longitude: -84.134180116503),
                GeoCoordinate(latitude: 9.96214523616743, longitude: -84.13471155096482),
                GeoCoordinate(latitude: 9.96210113185192, longitude: -84.13474838980919),
                GeoCoordinate(latitude: 9.96205670413649, longitude: -84.13468770408488),
                GeoCoordinate(latitude: 9.962139744110704, longitude: -84.13412937443914),
                GeoCoordinate(latitude: 9.962077911264522, longitude: -84.13407569002466),
                GeoCoordinate(latitude: 9.961695877372511, longitude: -84.13432061134361)
            ], trackWidthMeters: 7.0)
        case .fik, .formulaKart, .p1Speedway, .p1SpeedwayInverse, .test:
            return nil
        }
    }

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
