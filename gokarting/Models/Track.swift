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

    var mapCSVData: String? {
        switch self {
        case .p1ShortConfig:
            return TrackMapData.p1SpeedwayShortCSV
        case .fik, .formulaKart, .p1Speedway, .p1SpeedwayInverse:
            return nil
        }
    }

    var mapPoints: [TrackMapPoint] {
        guard let mapCSVData else { return [] }
        return TrackMapCSVParser.parsePoints(from: mapCSVData)
    }

    var supportsTrackMap: Bool {
        !mapPoints.isEmpty
    }
}

struct TrackMapPoint: Hashable {
    let latitude: Double
    let longitude: Double
}

private enum TrackMapCSVParser {
    static func parsePoints(from csv: String) -> [TrackMapPoint] {
        let lines = csv
            .split(whereSeparator: \ .isNewline)
            .map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        guard lines.count > 1 else { return [] }

        var indexedPoints: [(Int, TrackMapPoint)] = []
        indexedPoints.reserveCapacity(lines.count - 1)

        for line in lines.dropFirst() {
            let columns = line.split(separator: ",", omittingEmptySubsequences: false).map(String.init)
            guard columns.count >= 5,
                  let latitude = Double(columns[2]),
                  let longitude = Double(columns[3]),
                  let pointIndex = Int(columns[4]) else {
                continue
            }

            indexedPoints.append((pointIndex, TrackMapPoint(latitude: latitude, longitude: longitude)))
        }

        return indexedPoints
            .sorted { $0.0 < $1.0 }
            .map(\ .1)
    }
}

private enum TrackMapData {
    static let p1SpeedwayShortCSV = """
track_id,track_name,latitude,longitude,point_index
8b0ac4c4-0e41-4276-96bf-6870a280868a,Oval Track,52.320676,4.839504,0
8b0ac4c4-0e41-4276-96bf-6870a280868a,Oval Track,52.32067599894592,4.840003683363385,1
8b0ac4c4-0e41-4276-96bf-6870a280868a,Oval Track,52.320675997891854,4.840503366726741,2
8b0ac4c4-0e41-4276-96bf-6870a280868a,Oval Track,52.320675996837785,4.841003050090099,3
8b0ac4c4-0e41-4276-96bf-6870a280868a,Oval Track,52.320675995783716,4.84150273345343,4
8b0ac4c4-0e41-4276-96bf-6870a280868a,Oval Track,52.320675994729655,4.8420024168167615,5
8b0ac4c4-0e41-4276-96bf-6870a280868a,Oval Track,52.320675993675586,4.842502100180067,6
8b0ac4c4-0e41-4276-96bf-6870a280868a,Oval Track,52.320770374916464,4.842977328312446,7
8b0ac4c4-0e41-4276-96bf-6870a280868a,Oval Track,52.32094989982837,4.843381583147489,8
8b0ac4c4-0e41-4276-96bf-6870a280868a,Oval Track,52.3211969952568,4.843675293117407,9
8b0ac4c4-0e41-4276-96bf-6870a280868a,Oval Track,52.32148747368172,4.8438297066002,10
8b0ac4c4-0e41-4276-96bf-6870a280868a,Oval Track,52.32179290087832,4.8438297066002,11
8b0ac4c4-0e41-4276-96bf-6870a280868a,Oval Track,52.32209832807492,4.8438297066002,12
8b0ac4c4-0e41-4276-96bf-6870a280868a,Oval Track,52.32240375527152,4.8438297066002,13
8b0ac4c4-0e41-4276-96bf-6870a280868a,Oval Track,52.32270918246813,4.8438297066002,14
8b0ac4c4-0e41-4276-96bf-6870a280868a,Oval Track,52.32301460966473,4.8438297066002,15
8b0ac4c4-0e41-4276-96bf-6870a280868a,Oval Track,52.32332003686133,4.8438297066002,16
8b0ac4c4-0e41-4276-96bf-6870a280868a,Oval Track,52.323610515286255,4.843675285708267,17
8b0ac4c4-0e41-4276-96bf-6870a280868a,Oval Track,52.32385761071464,4.84338155807683,18
8b0ac4c4-0e41-4276-96bf-6870a280868a,Oval Track,52.32403713562647,4.842977275035,19
8b0ac4c4-0e41-4276-96bf-6870a280868a,Oval Track,52.32413151686723,4.842502010801723,20
8b0ac4c4-0e41-4276-96bf-6870a280868a,Oval Track,52.32413151581303,4.842002288413902,21
8b0ac4c4-0e41-4276-96bf-6870a280868a,Oval Track,52.324131514758825,4.8415025660260795,22
8b0ac4c4-0e41-4276-96bf-6870a280868a,Oval Track,52.32413151370462,4.841002843638284,23
8b0ac4c4-0e41-4276-96bf-6870a280868a,Oval Track,52.32413151265042,4.840503121250488,24
8b0ac4c4-0e41-4276-96bf-6870a280868a,Oval Track,52.32413151159621,4.840003398862717,25
8b0ac4c4-0e41-4276-96bf-6870a280868a,Oval Track,52.32413151054201,4.839503676474947,26
8b0ac4c4-0e41-4276-96bf-6870a280868a,Oval Track,52.3241315094878,4.839003954087202,27
8b0ac4c4-0e41-4276-96bf-6870a280868a,Oval Track,52.3241315084336,4.838504231699456,28
8b0ac4c4-0e41-4276-96bf-6870a280868a,Oval Track,52.32413150737939,4.838004509311737,29
8b0ac4c4-0e41-4276-96bf-6870a280868a,Oval Track,52.324131506325195,4.8375047869240175,30
8b0ac4c4-0e41-4276-96bf-6870a280868a,Oval Track,52.324131505271,4.837005064536323,31
8b0ac4c4-0e41-4276-96bf-6870a280868a,Oval Track,52.32413150421679,4.836505342148629,32
8b0ac4c4-0e41-4276-96bf-6870a280868a,Oval Track,52.32413150316259,4.836005619760961,33
8b0ac4c4-0e41-4276-96bf-6870a280868a,Oval Track,52.32413150210839,4.835505897373292,34
8b0ac4c4-0e41-4276-96bf-6870a280868a,Oval Track,52.32413150105419,4.835006174985623,35
8b0ac4c4-0e41-4276-96bf-6870a280868a,Oval Track,52.324131499999986,4.83450645259798,36
8b0ac4c4-0e41-4276-96bf-6870a280868a,Oval Track,52.32413149894578,4.834006730210336,37
8b0ac4c4-0e41-4276-96bf-6870a280868a,Oval Track,52.32413149789158,4.8335070078227185,38
8b0ac4c4-0e41-4276-96bf-6870a280868a,Oval Track,52.32413149683738,4.833007285435101,39
8b0ac4c4-0e41-4276-96bf-6870a280868a,Oval Track,52.32413149578318,4.832507563047509,40
8b0ac4c4-0e41-4276-96bf-6870a280868a,Oval Track,52.324131494728974,4.832007840659916,41
8b0ac4c4-0e41-4276-96bf-6870a280868a,Oval Track,52.32403711158115,4.831532577440701,42
8b0ac4c4-0e41-4276-96bf-6870a280868a,Oval Track,52.32385758528936,4.831128296039503,43
8b0ac4c4-0e41-4276-96bf-6870a280868a,Oval Track,52.323610489132555,4.830834570048622,44
8b0ac4c4-0e41-4276-96bf-6870a280868a,Oval Track,52.323320010506315,4.830680150170573,45
8b0ac4c4-0e41-4276-96bf-6870a280868a,Oval Track,52.32301458330972,4.830680150170573,46
8b0ac4c4-0e41-4276-96bf-6870a280868a,Oval Track,52.322709156113135,4.830680150170573,47
8b0ac4c4-0e41-4276-96bf-6870a280868a,Oval Track,52.32240372891653,4.830680150170573,48
8b0ac4c4-0e41-4276-96bf-6870a280868a,Oval Track,52.32209830171993,4.830680150170573,49
8b0ac4c4-0e41-4276-96bf-6870a280868a,Oval Track,52.32179287452333,4.830680150170573,50
8b0ac4c4-0e41-4276-96bf-6870a280868a,Oval Track,52.32148744732674,4.830680150170573,51
8b0ac4c4-0e41-4276-96bf-6870a280868a,Oval Track,52.321196968700505,4.830834562639609,52
8b0ac4c4-0e41-4276-96bf-6870a280868a,Oval Track,52.320949872543736,4.831128270969251,53
8b0ac4c4-0e41-4276-96bf-6870a280868a,Oval Track,52.320770346252026,4.831532524163942,54
8b0ac4c4-0e41-4276-96bf-6870a280868a,Oval Track,52.320675963104314,4.832007751282386,55
8b0ac4c4-0e41-4276-96bf-6870a280868a,Oval Track,52.320675962050245,4.832507434645335,56
8b0ac4c4-0e41-4276-96bf-6870a280868a,Oval Track,52.32067596099618,4.833007118008285,57
8b0ac4c4-0e41-4276-96bf-6870a280868a,Oval Track,52.32067595994211,4.833506801371209,58
8b0ac4c4-0e41-4276-96bf-6870a280868a,Oval Track,52.32067595888803,4.834006484734134,59
8b0ac4c4-0e41-4276-96bf-6870a280868a,Oval Track,52.32067595783396,4.834506168097058,60
8b0ac4c4-0e41-4276-96bf-6870a280868a,Oval Track,52.3206759567799,4.835005851459957,61
8b0ac4c4-0e41-4276-96bf-6870a280868a,Oval Track,52.32067595572584,4.835505534822856,62
8b0ac4c4-0e41-4276-96bf-6870a280868a,Oval Track,52.32067595467178,4.836005218185729,63
8b0ac4c4-0e41-4276-96bf-6870a280868a,Oval Track,52.32067595361771,4.836504901548603,64
8b0ac4c4-0e41-4276-96bf-6870a280868a,Oval Track,52.32067595256363,4.837004584911451,65
8b0ac4c4-0e41-4276-96bf-6870a280868a,Oval Track,52.32067595162993,4.837474875135311,66
8b0ac4c4-0e41-4276-96bf-6870a280868a,Oval Track,52.32067595069623,4.837945165359145,67
8b0ac4c4-0e41-4276-96bf-6870a280868a,Oval Track,52.320675949762524,4.83841545558298,68
8b0ac4c4-0e41-4276-96bf-6870a280868a,Oval Track,52.32067594882882,4.838885745806789,69
8b0ac4c4-0e41-4276-96bf-6870a280868a,Oval Track,52.32067594789511,4.839356036030598,70
8b0ac4c4-0e41-4276-96bf-6870a280868a,Oval Track,52.320676,4.839504,71
"""
}
