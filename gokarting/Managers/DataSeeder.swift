import Foundation
import SwiftData

class DataSeeder {
    
    // MARK: - Seed Session Definition
    
    /// Represents a hard-coded session to seed into the database.
    /// To add new sessions, simply append new entries to the appropriate track array below.
    private struct SeedSessionData {
        let identifier: String
        let year: Int
        let month: Int
        let day: Int
        let hour: Int
        let minute: Int
        let note: String
        let track: Track
        let kart: Kart?
        let laps: [Double]

        init(
            identifier: String,
            year: Int,
            month: Int,
            day: Int,
            hour: Int,
            minute: Int,
            note: String,
            track: Track,
            kart: Kart? = nil,
            laps: [Double]
        ) {
            self.identifier = identifier
            self.year = year
            self.month = month
            self.day = day
            self.hour = hour
            self.minute = minute
            self.note = note
            self.track = track
            self.kart = kart
            self.laps = laps
        }
        
        var date: Date {
            var components = DateComponents()
            components.year = year
            components.month = month
            components.day = day
            components.hour = hour
            components.minute = minute
            return Calendar.current.date(from: components) ?? Date()
        }

        var resolvedKart: Kart {
            kart ?? track.defaultKart
        }
    }
    
    // MARK: - Public API
    
    @MainActor
    static func seed(context: ModelContext) {
        assignDefaultKartsToLegacySessions(context: context)

        let existingIdentifiers = fetchExistingSeedIdentifiers(context: context)
        let allSeedSessions = allSeedSessionData()
        
        var insertedCount = 0
        for seedData in allSeedSessions {
            guard !existingIdentifiers.contains(seedData.identifier) else { continue }
            
            let session = Session(
                date: seedData.date,
                note: seedData.note,
                track: seedData.track,
                kart: seedData.resolvedKart,
                seedIdentifier: seedData.identifier
            )
            addLaps(seedData.laps, to: session)
            context.insert(session)
            insertedCount += 1
        }
        
        if insertedCount > 0 {
            print("DataSeeder: Inserted \(insertedCount) new seed session(s)")
        }
    }

    @MainActor
    private static func assignDefaultKartsToLegacySessions(context: ModelContext) {
        let descriptor = FetchDescriptor<Session>()
        do {
            let sessions = try context.fetch(descriptor)
            var updatedCount = 0
            for session in sessions {
                guard session.kart == nil, let track = session.track else { continue }
                session.kart = track.defaultKart
                updatedCount += 1
            }
            if updatedCount > 0 {
                try context.save()
                print("DataSeeder: Backfilled default kart for \(updatedCount) legacy session(s)")
            }
        } catch {
            print("DataSeeder: Failed to backfill legacy kart data: \(error)")
        }
    }
    
    // MARK: - Private Helpers
    
    @MainActor
    private static func fetchExistingSeedIdentifiers(context: ModelContext) -> Set<String> {
        let descriptor = FetchDescriptor<Session>()
        do {
            let sessions = try context.fetch(descriptor)
            return Set(sessions.compactMap { $0.seedIdentifier })
        } catch {
            print("DataSeeder: Failed to fetch existing sessions: \(error)")
            return []
        }
    }
    
    private static func addLaps(_ durations: [Double], to session: Session) {
        for (i, d) in durations.enumerated() {
            let lap = Lap(lapNumber: i + 1, duration: d)
            lap.session = session
        }
    }
    
    // MARK: - Seed Data Definitions
    // To add new sessions, append a new SeedSessionData entry to the appropriate track array.
    // Each entry needs a unique `identifier` string — use the pattern: "track-YYYY-MM-DD-heat-N"
    
    private static func allSeedSessionData() -> [SeedSessionData] {
        return fikSessions + formulaKartSessions + p1SpeedwaySessions
    }
    
    // MARK: FIK Sessions
    
    private static var fikSessions: [SeedSessionData] {
        [
            // Nov 22, 2025
            SeedSessionData(
                identifier: "fik-2025-11-22-heat-1",
                year: 2025, month: 11, day: 22, hour: 15, minute: 46,
                note: "Heat 1", track: .fik, kart: nil,
                laps: [
                    39.158, 33.545, 33.860, 33.734, 30.998,
                    31.876, 30.742, 30.274, 30.577, 29.371,
                    27.504, 26.786, 26.486
                ]
            ),
            SeedSessionData(
                identifier: "fik-2025-11-22-heat-2",
                year: 2025, month: 11, day: 22, hour: 16, minute: 23,
                note: "Heat 2", track: .fik, kart: nil,
                laps: [
                    51.24, 83.753, 26.593, 26.486, 31.18,
                    28.913, 30.397, 60.457, 31.132, 26.614
                ]
            ),
            SeedSessionData(
                identifier: "fik-2025-11-22-heat-3",
                year: 2025, month: 11, day: 22, hour: 16, minute: 30,
                note: "Heat 3", track: .fik, kart: nil,
                laps: [
                    41.484, 26.394, 28.327, 28.798, 27.210,
                    30.373, 61.250, 25.888, 25.446, 26.495,
                    26.91, 25.925, 31.807
                ]
            ),
            SeedSessionData(
                identifier: "fik-2025-11-22-heat-4",
                year: 2025, month: 11, day: 22, hour: 17, minute: 21,
                note: "Heat 4", track: .fik,
                laps: [
                    55.334, 27.439, 26.324, 26.917, 25.306,
                    25.990, 25.553, 24.785, 25.940, 25.809,
                    24.899, 27.180, 26.240, 25.561
                ]
            ),
            SeedSessionData(
                identifier: "fik-2025-11-22-heat-5",
                year: 2025, month: 11, day: 22, hour: 17, minute: 28,
                note: "Heat 5", track: .fik,
                laps: [
                    26.725, 24.995, 25.359, 26.574, 25.695,
                    27.897, 40.433, 24.882, 24.364, 25.12,
                    24.644, 39.677, 25.300, 26.315
                ]
            ),
            
            // Dec 15, 2025
            SeedSessionData(
                identifier: "fik-2025-12-15-heat-1",
                year: 2025, month: 12, day: 15, hour: 15, minute: 06,
                note: "Heat 1", track: .fik,
                laps: [
                    30.214, 29.396, 28.486, 25.894, 28.864,
                    25.989, 25.562, 24.472, 27.734, 25.557,
                    24.934, 25.82, 41.801, 25.518
                ]
            ),
            SeedSessionData(
                identifier: "fik-2025-12-15-heat-2",
                year: 2025, month: 12, day: 15, hour: 16, minute: 17,
                note: "Heat 2", track: .fik,
                laps: [
                    26.210, 51.805, 30.304, 28.278, 26.129,
                    29.500, 25.896, 25.410, 53.220, 24.263,
                    25.929, 25.670, 26.102, 31.428, 30.358,
                    25.841, 44.787, 23.893, 24.603, 25.503,
                    24.388, 24.591, 24.493, 25.812, 25.832,
                    27.35, 26.234, 24.160
                ]
            ),
            
            // January 29, 2026
            SeedSessionData(
                identifier: "fik-2026-01-29-heat-1",
                year: 2026, month: 1, day: 29, hour: 16, minute: 56,
                note: "Heat 1", track: .fik,
                laps: [
                    38.156, 41.551, 24.468, 23.850, 23.588,
                    24.547, 23.893, 24.202, 23.760, 23.882,
                    23.300, 23.352, 23.138, 23.521, 23.643,
                    24.446
                ]
            ),
            SeedSessionData(
                identifier: "fik-2026-01-29-heat-2",
                year: 2026, month: 1, day: 29, hour: 17, minute: 24,
                note: "Heat 2", track: .fik,
                laps: [
                    24.609, 24.157, 24.74, 23.714, 23.85,
                    23.692, 23.251, 23.144, 23.158, 22.812,
                    22.975, 24.12, 23.443, 23.484, 23.278,
                    23.530, 39.369, 23.757, 24.318, 23.361,
                    23.207, 24.553, 24.562, 23.940, 24.359,
                    56.21, 23.719, 24.731, 27.248, 24.690,
                    23.500
                ]
            ),
        ]
    }
    
    // MARK: Formula Kart Sessions
    
    private static var formulaKartSessions: [SeedSessionData] {
        [
            // Nov 30, 2025
            SeedSessionData(
                identifier: "formulakart-2025-11-30-heat-1",
                year: 2025, month: 11, day: 30, hour: 13, minute: 10,
                note: "Heat 1", track: .formulaKart,
                laps: [
                    31.723, 29.031, 27.943, 26.875, 26.901,
                    28.450, 26.180, 25.332, 26.091, 26.790,
                    25.914, 27.802, 26.760
                ]
            ),
            
            // January 19, 2026
            SeedSessionData(
                identifier: "formulakart-2026-01-19-heat-1",
                year: 2026, month: 1, day: 19, hour: 14, minute: 30,
                note: "Heat 1", track: .formulaKart,
                laps: [
                    27.359, 26.834, 26.190, 26.668, 28.574,
                    26.535, 25.834, 25.878, 25.336, 25.751,
                    25.688, 26.978, 25.546, 25.060, 26.925
                ]
            ),
            SeedSessionData(
                identifier: "formulakart-2026-01-19-heat-2",
                year: 2026, month: 1, day: 19, hour: 15, minute: 10,
                note: "Heat 2", track: .formulaKart,
                laps: [
                    26.768, 26.199, 25.703, 28.863, 25.834,
                    24.829, 25.142, 25.023, 25.273, 24.853,
                    25.140, 24.392, 24.636, 24.840, 25.133,
                    26.575
                ]
            ),
            SeedSessionData(
                identifier: "formulakart-2026-01-19-heat-3",
                year: 2026, month: 1, day: 19, hour: 15, minute: 20,
                note: "Heat 3", track: .formulaKart,
                laps: [
                    25.130, 25.028, 25.256, 25.467, 25.122,
                    25.250, 24.757, 24.847, 24.987, 25.978,
                    25.747, 25.515, 24.834, 24.890
                ]
            ),
            SeedSessionData(
                identifier: "formulakart-2026-01-19-heat-4",
                year: 2026, month: 1, day: 19, hour: 15, minute: 40,
                note: "Heat 4", track: .formulaKart,
                laps: [
                    25.993, 25.345, 25.148, 28.919, 25.691,
                    24.686, 25.838, 24.545, 24.370, 27.517,
                    24.485, 24.846, 24.674, 24.507, 24.666,
                    25.685
                ]
            ),
            SeedSessionData(
                identifier: "formulakart-2026-01-19-heat-5",
                year: 2026, month: 1, day: 19, hour: 16, minute: 00,
                note: "Heat 5", track: .formulaKart,
                laps: [
                    26.695, 25.784, 24.945, 25.010, 24.883,
                    26.234, 24.504, 24.421, 24.382, 24.535,
                    24.350, 24.828, 24.786, 24.876, 24.471,
                    24.466
                ]
            ),
            
            // January 27, 2026
            SeedSessionData(
                identifier: "formulakart-2026-01-27-heat-1",
                year: 2026, month: 1, day: 27, hour: 17, minute: 40,
                note: "Heat 1", track: .formulaKart,
                laps: [
                    25.563, 26.234, 25.929, 25.790, 25.800,
                    26.175, 25.918, 25.396, 26.217, 25.276,
                    25.102, 25.211, 25.337, 24.934, 24.817,
                    24.788
                ]
            ),
            SeedSessionData(
                identifier: "formulakart-2026-01-27-heat-2",
                year: 2026, month: 1, day: 27, hour: 17, minute: 50,
                note: "Heat 2", track: .formulaKart,
                laps: [
                    24.485, 24.625, 24.804, 24.736, 24.333,
                    24.502, 24.516, 24.271, 24.567, 24.220,
                    24.391, 24.550, 24.483, 24.935, 24.152,
                    24.107, 24.771
                ]
            ),
            SeedSessionData(
                identifier: "formulakart-2026-01-27-heat-3",
                year: 2026, month: 1, day: 27, hour: 18, minute: 10,
                note: "Heat 3", track: .formulaKart,
                laps: [
                    25.080, 25.430, 26.162, 25.175, 24.708,
                    24.664, 24.399, 24.778, 24.161, 24.431,
                    25.713, 24.347, 24.344, 24.193, 24.535,
                    24.342
                ]
            ),
            SeedSessionData(
                identifier: "formulakart-2026-01-27-heat-4",
                year: 2026, month: 1, day: 27, hour: 18, minute: 20,
                note: "Heat 4", track: .formulaKart,
                laps: [
                    24.401, 24.008, 23.697, 23.760, 24.779,
                    23.564, 23.868, 23.531, 23.714, 23.890,
                    23.872, 23.720, 23.863, 24.406, 23.604,
                    25.488
                ]
            ),
            
            // February 4, 2026
            SeedSessionData(
                identifier: "formulakart-2026-02-04-heat-1",
                year: 2026, month: 2, day: 4, hour: 19, minute: 40,
                note: "Heat 1", track: .formulaKart,
                laps: [
                    24.881, 24.588, 24.261, 24.162, 24.342,
                    24.145, 24.114, 23.954, 24.070, 24.204,
                    24.073, 23.926, 23.772, 24.110, 24.017,
                    23.565, 23.625
                ]
            ),
            SeedSessionData(
                identifier: "formulakart-2026-02-04-heat-2",
                year: 2026, month: 2, day: 4, hour: 19, minute: 50,
                note: "Heat 2", track: .formulaKart,
                laps: [
                    23.559, 23.777, 23.385, 23.745, 23.406,
                    23.619, 23.661, 23.426, 23.896, 23.705,
                    23.377, 23.571, 23.906, 23.393, 23.746,
                    23.513, 24.013
                ]
            ),
            
            // March 3, 2026
            SeedSessionData(
                identifier: "formulakart-2026-03-03-heat-42",
                year: 2026, month: 3, day: 3, hour: 20, minute: 0,
                note: "Heat 42", track: .formulaKart,
                laps: [
                    26.836, 25.852, 25.962, 25.334, 25.040,
                    24.988, 25.074, 25.063, 24.944, 24.844,
                    25.393, 24.401, 24.626, 24.558, 25.010,
                    24.803
                ]
            ),
            SeedSessionData(
                identifier: "formulakart-2026-03-03-heat-43",
                year: 2026, month: 3, day: 3, hour: 20, minute: 10,
                note: "Heat 43", track: .formulaKart,
                laps: [
                    24.803, 24.698, 24.421, 24.576, 24.745,
                    24.526, 24.730, 24.929, 24.663, 24.590,
                    24.586, 24.760, 24.494, 24.628, 24.477,
                    24.682
                ]
            ),
            SeedSessionData(
                identifier: "formulakart-2026-03-03-heat-48",
                year: 2026, month: 3, day: 3, hour: 20, minute: 20,
                note: "Heat 48", track: .formulaKart,
                laps: [
                    25.904, 24.487, 24.477, 24.579, 24.517,
                    23.964, 24.612, 24.304, 24.167, 24.073,
                    23.961, 23.946, 23.811, 23.920, 23.884,
                    23.692, 23.921
                ]
            ),
            SeedSessionData(
                identifier: "formulakart-2026-03-03-heat-49",
                year: 2026, month: 3, day: 3, hour: 20, minute: 30,
                note: "Heat 49", track: .formulaKart,
                laps: [
                    24.039, 23.964, 23.884, 23.842, 24.263,
                    24.029, 23.531, 23.664, 24.022, 24.320,
                    23.880, 23.854, 23.642, 23.593, 27.785,
                    24.380, 24.580
                ]
            ),
            SeedSessionData(
                identifier: "formulakart-2026-03-03-heat-52",
                year: 2026, month: 3, day: 3, hour: 20, minute: 40,
                note: "Heat 52", track: .formulaKart,
                laps: [
                    25.308, 24.976, 24.767, 24.120, 24.342,
                    24.054, 23.670, 24.028, 23.612, 23.859,
                    23.813, 23.917, 24.431, 23.807, 23.803,
                    24.065, 23.452
                ]
            ),
            SeedSessionData(
                identifier: "formulakart-2026-03-03-heat-53",
                year: 2026, month: 3, day: 3, hour: 20, minute: 50,
                note: "Heat 53", track: .formulaKart,
                laps: [
                    23.616, 23.378, 23.586, 23.410, 23.727,
                    23.666, 23.629, 23.652, 23.676, 23.561,
                    30.183, 27.326, 23.412, 23.549, 29.476,
                    23.675, 23.944
                ]
            ),
            
            // March 17, 2026
            SeedSessionData(
                identifier: "formulakart-2026-03-17-heat-70",
                year: 2026, month: 3, day: 17, hour: 20, minute: 0,
                note: "Heat 70", track: .formulaKart,
                laps: [
                    26.793, 26.015, 26.403, 26.366, 25.103,
                    24.313, 24.468, 24.141, 23.567, 23.902,
                    23.661, 24.223, 23.731, 23.684, 23.686,
                    23.612, 23.538
                ]
            ),
            SeedSessionData(
                identifier: "formulakart-2026-03-17-heat-71",
                year: 2026, month: 3, day: 17, hour: 20, minute: 10,
                note: "Heat 71", track: .formulaKart,
                laps: [
                    23.852, 23.617, 23.719, 23.585, 23.362,
                    23.366, 23.457, 23.337, 23.347, 23.357,
                    23.501, 23.393, 23.245, 23.671, 24.235,
                    23.587
                ]
            ),
            SeedSessionData(
                identifier: "formulakart-2026-03-17-heat-75",
                year: 2026, month: 3, day: 17, hour: 20, minute: 20,
                note: "Heat 75", track: .formulaKart,
                laps: [
                    25.115, 25.075, 25.938, 30.339, 24.938,
                    24.401, 24.440, 24.311, 24.961, 24.758,
                    24.414, 24.241, 23.900, 24.009, 24.028,
                    24.386, 24.326, 24.380
                ]
            ),
            SeedSessionData(
                identifier: "formulakart-2026-03-17-heat-76",
                year: 2026, month: 3, day: 17, hour: 20, minute: 30,
                note: "Heat 76", track: .formulaKart,
                laps: [
                    23.888, 24.958, 23.874, 23.817, 23.403,
                    23.419, 23.502, 23.677, 23.408, 23.480,
                    23.473, 23.737, 24.021, 23.402, 23.564,
                    23.454, 23.371
                ]
            ),
        ]
    }
    
    // MARK: P1 Speedway Sessions
    
    private static var p1SpeedwaySessions: [SeedSessionData] {
        [
            // February 8, 2026
            SeedSessionData(
                identifier: "p1speedway-2026-02-08-heat-1",
                year: 2026, month: 2, day: 8, hour: 11, minute: 00,
                note: "Heat 1", track: .p1Speedway, kart: .sodiRental,
                laps: [
                    76.72, 75.35, 80.07, 74.79, 75.61
                ]
            ),
            SeedSessionData(
                identifier: "p1speedway-2026-02-08-heat-2",
                year: 2026, month: 2, day: 8, hour: 11, minute: 30,
                note: "Heat 2", track: .p1Speedway, kart: .tillotsonT4,
                laps: [
                    75.21, 74.49, 73.73, 73.10, 74.35,
                    73.27, 74.18, 73.19, 73.63, 73.49
                ]
            ),
        ]
    }
}
