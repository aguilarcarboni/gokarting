import Foundation

final class Race: Identifiable, Codable, Hashable {
    let id: UUID
    private(set) var track: Track
    private(set) var kart: Kart
    private(set) var heats: [Heat]

    init(
        id: UUID = UUID(),
        track: Track,
        kart: Kart,
        heats: [Heat] = []
    ) {
        let normalizedKart = track.availableKarts.contains(kart)
            ? kart
            : track.defaultKart

        self.id = id
        self.track = track
        self.kart = normalizedKart
        self.heats = heats
        synchronizeHeatsWithRaceCombo()
    }

    func pickTrack(_ track: Track) {
        self.track = track
        if !track.availableKarts.contains(kart) {
            kart = track.defaultKart
        }
        synchronizeHeatsWithRaceCombo()
    }

    func pickKart(_ kart: Kart) {
        guard track.availableKarts.contains(kart) else { return }
        self.kart = kart
        synchronizeHeatsWithRaceCombo()
    }

    func addHeat(_ heat: Heat) {
        var inherited = heat
        inherited.inheritCombo(track: track, kart: kart)
        heats.append(inherited)
    }

    func updateHeatLaps(heatID: UUID, laps: [Lap]) {
        guard let index = heats.firstIndex(where: { $0.id == heatID }) else { return }
        heats[index].replaceLaps(laps)
    }

    func removeHeat(heatID: UUID) {
        heats.removeAll { $0.id == heatID }
    }

    private func synchronizeHeatsWithRaceCombo() {
        heats = heats.map { heat in
            var inherited = heat
            inherited.inheritCombo(track: track, kart: kart)
            return inherited
        }
    }

    static func == (lhs: Race, rhs: Race) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
