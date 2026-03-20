import Foundation

enum Track: String, CaseIterable, Codable {
    case fik = "FIK"
    case formulaKart = "Formula Kart"
    case p1Speedway = "P1 Speedway"
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
        }
    }

    var defaultKart: Kart {
        availableKarts.first ?? .fikKart
    }
}
