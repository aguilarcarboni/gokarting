import Foundation

struct TrackLayout: Hashable, Codable {
    let centerline: [GeoCoordinate]
    let trackWidthMeters: Double?
}

enum Track: String, CaseIterable, Codable {
    case fik = "FIK"
    case formulaKart = "Formula Kart"
    case p1Speedway = "P1 Speedway (Medium)"
    case p1SpeedwayLong = "P1 Speedway (Long)"
    case p1ShortConfig = "P1 Speedway (Short)"
    case p1SpeedwayInverse = "P1 Speedway (Inverse)"

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let value = try container.decode(String.self)
        switch value {
        case Track.p1Speedway.rawValue, "P1 Speedway":
            self = .p1Speedway
        case Track.p1SpeedwayLong.rawValue:
            self = .p1SpeedwayLong
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
    private static let p1ShortCenterline: [GeoCoordinate] = [
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
        GeoCoordinate(latitude: 9.961686499999999, longitude: -84.134333)
    ]
    private static let p1LongCenterline: [GeoCoordinate] = [
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
        GeoCoordinate(latitude: 9.962048301424472, longitude: -84.13487084606457),
        GeoCoordinate(latitude: 9.962074239168157, longitude: -84.13492893754885),
        GeoCoordinate(latitude: 9.962020075054069, longitude: -84.13511173208592),
        GeoCoordinate(latitude: 9.96195908748757, longitude: -84.13514754167196),
        GeoCoordinate(latitude: 9.961104186737405, longitude: -84.1351007379404),
        GeoCoordinate(latitude: 9.961031931133078, longitude: -84.13514119184481),
        GeoCoordinate(latitude: 9.961227785336641, longitude: -84.13544914136986),
        GeoCoordinate(latitude: 9.961304649704239, longitude: -84.1354640502502),
        GeoCoordinate(latitude: 9.961886043626402, longitude: -84.1353322093249),
        GeoCoordinate(latitude: 9.961960678968559, longitude: -84.1353933562985),
        GeoCoordinate(latitude: 9.961909240480106, longitude: -84.13555717789069),
        GeoCoordinate(latitude: 9.961826230862085, longitude: -84.13560855812364),
        GeoCoordinate(latitude: 9.961547715867697, longitude: -84.13561986318764),
        GeoCoordinate(latitude: 9.961513618882424, longitude: -84.13565200578934),
        GeoCoordinate(latitude: 9.961548788599265, longitude: -84.13576081351951),
        GeoCoordinate(latitude: 9.961877515163724, longitude: -84.13576380017231),
        GeoCoordinate(latitude: 9.961941246797348, longitude: -84.1357271806075),
        GeoCoordinate(latitude: 9.962004343834819, longitude: -84.13566002282559),
        GeoCoordinate(latitude: 9.962274815119564, longitude: -84.134901952911),
        GeoCoordinate(latitude: 9.962548791747947, longitude: -84.1339463620699),
        GeoCoordinate(latitude: 9.962493603517096, longitude: -84.1338436804861),
        GeoCoordinate(latitude: 9.96238056784613, longitude: -84.13383548290136),
        GeoCoordinate(latitude: 9.962299094059011, longitude: -84.13388466840969),
        GeoCoordinate(latitude: 9.962281228701693, longitude: -84.13400633968183),
        GeoCoordinate(latitude: 9.962306691783404, longitude: -84.13419026824293),
        GeoCoordinate(latitude: 9.962152210425257, longitude: -84.1347077971975),
        GeoCoordinate(latitude: 9.962098395327507, longitude: -84.13476055335673),
        GeoCoordinate(latitude: 9.962041521133804, longitude: -84.13467433160643),
        GeoCoordinate(latitude: 9.96214330597664, longitude: -84.1341170192864),
        GeoCoordinate(latitude: 9.96206917561372, longitude: -84.13407265412542),
        GeoCoordinate(latitude: 9.961686499999999, longitude: -84.134333)
    ]
    private static let p1MediumCenterline: [GeoCoordinate] = [
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
        GeoCoordinate(latitude: 9.962048301424472, longitude: -84.13487084606457),
        GeoCoordinate(latitude: 9.962074239168157, longitude: -84.13492893754885),
        GeoCoordinate(latitude: 9.962020075054069, longitude: -84.13511173208592),
        GeoCoordinate(latitude: 9.96204366389568, longitude: -84.13516172329389),
        GeoCoordinate(latitude: 9.962122894765, longitude: -84.13516249679157),
        GeoCoordinate(latitude: 9.962189936254775, longitude: -84.1351493473302),
        GeoCoordinate(latitude: 9.962275270128584, longitude: -84.13489210712501),
        GeoCoordinate(latitude: 9.96253087795634, longitude: -84.1339459192504),
        GeoCoordinate(latitude: 9.962495031053953, longitude: -84.13384685679935),
        GeoCoordinate(latitude: 9.962390110548334, longitude: -84.13382972312084),
        GeoCoordinate(latitude: 9.96229399453109, longitude: -84.13387516461603),
        GeoCoordinate(latitude: 9.962283277441106, longitude: -84.13400744919),
        GeoCoordinate(latitude: 9.962306462285518, longitude: -84.13418376377197),
        GeoCoordinate(latitude: 9.962160629593784, longitude: -84.13469115412343),
        GeoCoordinate(latitude: 9.96209453749793, longitude: -84.13475825798994),
        GeoCoordinate(latitude: 9.96204895673437, longitude: -84.13466030177099),
        GeoCoordinate(latitude: 9.962147907348978, longitude: -84.13412105037585),
        GeoCoordinate(latitude: 9.962064689764041, longitude: -84.13406182735088),
        GeoCoordinate(latitude: 9.961686499999999, longitude: -84.134333)
    ]

    var layout: TrackLayout? {
        switch self {
        case .p1Speedway:
            return TrackLayout(centerline: Track.p1MediumCenterline, trackWidthMeters: 7.0)
        case .p1SpeedwayLong:
            return TrackLayout(centerline: Track.p1LongCenterline, trackWidthMeters: 7.0)
        case .p1ShortConfig:
            return TrackLayout(centerline: Track.p1ShortCenterline, trackWidthMeters: 7.0)
        case .p1SpeedwayInverse:
            return TrackLayout(centerline: Array(Track.p1LongCenterline.reversed()), trackWidthMeters: 7.0)
        case .fik, .formulaKart:
            return nil
        }
    }

    var gatePoints: (pointA: GeoCoordinate, pointB: GeoCoordinate) {
        switch self {
        case .p1Speedway, .p1SpeedwayLong:
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
        }
    }

    var availableKarts: [Kart] {
        switch self {
        case .fik:
            return [.fikKart]
        case .formulaKart:
            return [.fkKart]
        case .p1Speedway, .p1SpeedwayLong:
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

    var supportedRaceDirections: [RaceDirection] {
        switch self {
        case .p1SpeedwayInverse, .fik:
            return [.clockwise]
        case .p1Speedway, .p1SpeedwayLong, .p1ShortConfig, .formulaKart:
            return [.counterClockwise]
        }
    }

    var defaultRaceDirection: RaceDirection {
        supportedRaceDirections.first ?? .clockwise
    }
}
