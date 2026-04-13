import Foundation

//
//  SampleData.swift
//  gokarting
//
//  Created by Andres on 13/4/2026.
//

enum SampleData {
    static let calendar = Calendar(identifier: .gregorian)

    static let standaloneHeats: [Heat] = [
        Heat(
            identifier: "fik-2025-11-22-heat-1",
            track: .fik,
            kart: .fikKart,
            lapDurations: [
                39.158, 33.545, 33.860, 33.734, 30.998,
                31.876, 30.742, 30.274, 30.577, 29.371,
                27.504, 26.786, 26.486
            ],
            date: calendar.date(from: DateComponents(year: 2025, month: 11, day: 22, hour: 15, minute: 46)) ?? Date.distantPast
        ),
        Heat(
            identifier: "fik-2025-11-22-heat-2",
            track: .fik,
            kart: .fikKart,
            lapDurations: [
                51.24, 83.753, 26.593, 26.486, 31.18,
                28.913, 30.397, 60.457, 31.132, 26.614
            ],
            date: calendar.date(from: DateComponents(year: 2025, month: 11, day: 22, hour: 16, minute: 23)) ?? Date.distantPast
        ),
        Heat(
            identifier: "fik-2025-11-22-heat-3",
            track: .fik,
            kart: .fikKart,
            lapDurations: [
                41.484, 26.394, 28.327, 28.798, 27.210,
                30.373, 61.250, 25.888, 25.446, 26.495,
                26.91, 25.925, 31.807
            ],
            date: calendar.date(from: DateComponents(year: 2025, month: 11, day: 22, hour: 16, minute: 30)) ?? Date.distantPast
        ),
        Heat(
            identifier: "fik-2025-11-22-heat-4",
            track: .fik,
            kart: .fikKart,
            lapDurations: [
                55.334, 27.439, 26.324, 26.917, 25.306,
                25.990, 25.553, 24.785, 25.940, 25.809,
                24.899, 27.180, 26.240, 25.561
            ],
            date: calendar.date(from: DateComponents(year: 2025, month: 11, day: 22, hour: 17, minute: 21)) ?? Date.distantPast
        ),
        Heat(
            identifier: "fik-2025-11-22-heat-5",
            track: .fik,
            kart: .fikKart,
            lapDurations: [
                26.725, 24.995, 25.359, 26.574, 25.695,
                27.897, 40.433, 24.882, 24.364, 25.12,
                24.644, 39.677, 25.300, 26.315
            ],
            date: calendar.date(from: DateComponents(year: 2025, month: 11, day: 22, hour: 17, minute: 28)) ?? Date.distantPast
        ),
        Heat(
            identifier: "fik-2025-12-15-heat-1",
            track: .fik,
            kart: .fikKart,
            lapDurations: [
                30.214, 29.396, 28.486, 25.894, 28.864,
                25.989, 25.562, 24.472, 27.734, 25.557,
                24.934, 25.82, 41.801, 25.518
            ],
            date: calendar.date(from: DateComponents(year: 2025, month: 12, day: 15, hour: 15, minute: 6)) ?? Date.distantPast
        ),
        Heat(
            identifier: "fik-2025-12-15-heat-2",
            track: .fik,
            kart: .fikKart,
            lapDurations: [
                26.210, 51.805, 30.304, 28.278, 26.129,
                29.500, 25.896, 25.410, 53.220, 24.263,
                25.929, 25.670, 26.102, 31.428, 30.358,
                25.841, 44.787, 23.893, 24.603, 25.503,
                24.388, 24.591, 24.493, 25.812, 25.832,
                27.35, 26.234, 24.160
            ],
            date: calendar.date(from: DateComponents(year: 2025, month: 12, day: 15, hour: 16, minute: 17)) ?? Date.distantPast
        ),
        Heat(
            identifier: "fik-2026-01-29-heat-1",
            track: .fik,
            kart: .fikKart,
            lapDurations: [
                38.156, 41.551, 24.468, 23.850, 23.588,
                24.547, 23.893, 24.202, 23.760, 23.882,
                23.300, 23.352, 23.138, 23.521, 23.643,
                24.446
            ],
            date: calendar.date(from: DateComponents(year: 2026, month: 1, day: 29, hour: 16, minute: 56)) ?? Date.distantPast
        ),
        Heat(
            identifier: "fik-2026-01-29-heat-2",
            track: .fik,
            kart: .fikKart,
            lapDurations: [
                24.609, 24.157, 24.74, 23.714, 23.85,
                23.692, 23.251, 23.144, 23.158, 22.812,
                22.975, 24.12, 23.443, 23.484, 23.278,
                23.530, 39.369, 23.757, 24.318, 23.361,
                23.207, 24.553, 24.562, 23.940, 24.359,
                56.21, 23.719, 24.731, 27.248, 24.690,
                23.500
            ],
            date: calendar.date(from: DateComponents(year: 2026, month: 1, day: 29, hour: 17, minute: 24)) ?? Date.distantPast
        ),

        Heat(
            identifier: "formulakart-2025-11-30-heat-1",
            track: .formulaKart,
            kart: .fkKart,
            lapDurations: [
                31.723, 29.031, 27.943, 26.875, 26.901,
                28.450, 26.180, 25.332, 26.091, 26.790,
                25.914, 27.802, 26.760
            ],
            date: calendar.date(from: DateComponents(year: 2025, month: 11, day: 30, hour: 13, minute: 10)) ?? Date.distantPast
        ),
        Heat(
            identifier: "formulakart-2026-01-19-heat-1",
            track: .formulaKart,
            kart: .fkKart,
            lapDurations: [
                27.359, 26.834, 26.190, 26.668, 28.574,
                26.535, 25.834, 25.878, 25.336, 25.751,
                25.688, 26.978, 25.546, 25.060, 26.925
            ],
            date: calendar.date(from: DateComponents(year: 2026, month: 1, day: 19, hour: 14, minute: 30)) ?? Date.distantPast
        ),
        Heat(
            identifier: "formulakart-2026-01-19-heat-2",
            track: .formulaKart,
            kart: .fkKart,
            lapDurations: [
                26.768, 26.199, 25.703, 28.863, 25.834,
                24.829, 25.142, 25.023, 25.273, 24.853,
                25.140, 24.392, 24.636, 24.840, 25.133,
                26.575
            ],
            date: calendar.date(from: DateComponents(year: 2026, month: 1, day: 19, hour: 15, minute: 10)) ?? Date.distantPast
        ),
        Heat(
            identifier: "formulakart-2026-01-19-heat-3",
            track: .formulaKart,
            kart: .fkKart,
            lapDurations: [
                25.130, 25.028, 25.256, 25.467, 25.122,
                25.250, 24.757, 24.847, 24.987, 25.978,
                25.747, 25.515, 24.834, 24.890
            ],
            date: calendar.date(from: DateComponents(year: 2026, month: 1, day: 19, hour: 15, minute: 20)) ?? Date.distantPast
        ),
        Heat(
            identifier: "formulakart-2026-01-19-heat-4",
            track: .formulaKart,
            kart: .fkKart,
            lapDurations: [
                25.993, 25.345, 25.148, 28.919, 25.691,
                24.686, 25.838, 24.545, 24.370, 27.517,
                24.485, 24.846, 24.674, 24.507, 24.666,
                25.685
            ],
            date: calendar.date(from: DateComponents(year: 2026, month: 1, day: 19, hour: 15, minute: 40)) ?? Date.distantPast
        ),
        Heat(
            identifier: "formulakart-2026-01-19-heat-5",
            track: .formulaKart,
            kart: .fkKart,
            lapDurations: [
                26.695, 25.784, 24.945, 25.010, 24.883,
                26.234, 24.504, 24.421, 24.382, 24.535,
                24.350, 24.828, 24.786, 24.876, 24.471,
                24.466
            ],
            date: calendar.date(from: DateComponents(year: 2026, month: 1, day: 19, hour: 16, minute: 0)) ?? Date.distantPast
        ),
        Heat(
            identifier: "formulakart-2026-01-27-heat-1",
            track: .formulaKart,
            kart: .fkKart,
            lapDurations: [
                25.563, 26.234, 25.929, 25.790, 25.800,
                26.175, 25.918, 25.396, 26.217, 25.276,
                25.102, 25.211, 25.337, 24.934, 24.817,
                24.788
            ],
            date: calendar.date(from: DateComponents(year: 2026, month: 1, day: 27, hour: 17, minute: 40)) ?? Date.distantPast
        ),
        Heat(
            identifier: "formulakart-2026-01-27-heat-2",
            track: .formulaKart,
            kart: .fkKart,
            lapDurations: [
                24.485, 24.625, 24.804, 24.736, 24.333,
                24.502, 24.516, 24.271, 24.567, 24.220,
                24.391, 24.550, 24.483, 24.935, 24.152,
                24.107, 24.771
            ],
            date: calendar.date(from: DateComponents(year: 2026, month: 1, day: 27, hour: 17, minute: 50)) ?? Date.distantPast
        ),
        Heat(
            identifier: "formulakart-2026-01-27-heat-3",
            track: .formulaKart,
            kart: .fkKart,
            lapDurations: [
                25.080, 25.430, 26.162, 25.175, 24.708,
                24.664, 24.399, 24.778, 24.161, 24.431,
                25.713, 24.347, 24.344, 24.193, 24.535,
                24.342
            ],
            date: calendar.date(from: DateComponents(year: 2026, month: 1, day: 27, hour: 18, minute: 10)) ?? Date.distantPast
        ),
        Heat(
            identifier: "formulakart-2026-01-27-heat-4",
            track: .formulaKart,
            kart: .fkKart,
            lapDurations: [
                24.401, 24.008, 23.697, 23.760, 24.779,
                23.564, 23.868, 23.531, 23.714, 23.890,
                23.872, 23.720, 23.863, 24.406, 23.604,
                25.488
            ],
            date: calendar.date(from: DateComponents(year: 2026, month: 1, day: 27, hour: 18, minute: 20)) ?? Date.distantPast
        ),
        Heat(
            identifier: "formulakart-2026-02-04-heat-1",
            track: .formulaKart,
            kart: .fkKart,
            lapDurations: [
                24.881, 24.588, 24.261, 24.162, 24.342,
                24.145, 24.114, 23.954, 24.070, 24.204,
                24.073, 23.926, 23.772, 24.110, 24.017,
                23.565, 23.625
            ],
            date: calendar.date(from: DateComponents(year: 2026, month: 2, day: 4, hour: 19, minute: 40)) ?? Date.distantPast
        ),
        Heat(
            identifier: "formulakart-2026-02-04-heat-2",
            track: .formulaKart,
            kart: .fkKart,
            lapDurations: [
                23.559, 23.777, 23.385, 23.745, 23.406,
                23.619, 23.661, 23.426, 23.896, 23.705,
                23.377, 23.571, 23.906, 23.393, 23.746,
                23.513, 24.013
            ],
            date: calendar.date(from: DateComponents(year: 2026, month: 2, day: 4, hour: 19, minute: 50)) ?? Date.distantPast
        ),
        Heat(
            identifier: "formulakart-2026-03-03-heat-42",
            track: .formulaKart,
            kart: .fkKart,
            lapDurations: [
                26.836, 25.852, 25.962, 25.334, 25.040,
                24.988, 25.074, 25.063, 24.944, 24.844,
                25.393, 24.401, 24.626, 24.558, 25.010,
                24.803
            ],
            date: calendar.date(from: DateComponents(year: 2026, month: 3, day: 3, hour: 20, minute: 0)) ?? Date.distantPast
        ),
        Heat(
            identifier: "formulakart-2026-03-03-heat-43",
            track: .formulaKart,
            kart: .fkKart,
            lapDurations: [
                24.803, 24.698, 24.421, 24.576, 24.745,
                24.526, 24.730, 24.929, 24.663, 24.590,
                24.586, 24.760, 24.494, 24.628, 24.477,
                24.682
            ],
            date: calendar.date(from: DateComponents(year: 2026, month: 3, day: 3, hour: 20, minute: 10)) ?? Date.distantPast
        ),
        Heat(
            identifier: "formulakart-2026-03-03-heat-48",
            track: .formulaKart,
            kart: .fkKart,
            lapDurations: [
                25.904, 24.487, 24.477, 24.579, 24.517,
                23.964, 24.612, 24.304, 24.167, 24.073,
                23.961, 23.946, 23.811, 23.920, 23.884,
                23.692, 23.921
            ],
            date: calendar.date(from: DateComponents(year: 2026, month: 3, day: 3, hour: 20, minute: 20)) ?? Date.distantPast
        ),
        Heat(
            identifier: "formulakart-2026-03-03-heat-49",
            track: .formulaKart,
            kart: .fkKart,
            lapDurations: [
                24.039, 23.964, 23.884, 23.842, 24.263,
                24.029, 23.531, 23.664, 24.022, 24.320,
                23.880, 23.854, 23.642, 23.593, 27.785,
                24.380, 24.580
            ],
            date: calendar.date(from: DateComponents(year: 2026, month: 3, day: 3, hour: 20, minute: 30)) ?? Date.distantPast
        ),
        Heat(
            identifier: "formulakart-2026-03-03-heat-52",
            track: .formulaKart,
            kart: .fkKart,
            lapDurations: [
                25.308, 24.976, 24.767, 24.120, 24.342,
                24.054, 23.670, 24.028, 23.612, 23.859,
                23.813, 23.917, 24.431, 23.807, 23.803,
                24.065, 23.452
            ],
            date: calendar.date(from: DateComponents(year: 2026, month: 3, day: 3, hour: 20, minute: 40)) ?? Date.distantPast
        ),
        Heat(
            identifier: "formulakart-2026-03-03-heat-53",
            track: .formulaKart,
            kart: .fkKart,
            lapDurations: [
                23.616, 23.378, 23.586, 23.410, 23.727,
                23.666, 23.629, 23.652, 23.676, 23.561,
                30.183, 27.326, 23.412, 23.549, 29.476,
                23.675, 23.944
            ],
            date: calendar.date(from: DateComponents(year: 2026, month: 3, day: 3, hour: 20, minute: 50)) ?? Date.distantPast
        ),
        Heat(
            identifier: "formulakart-2026-03-17-heat-70",
            track: .formulaKart,
            kart: .fkKart,
            lapDurations: [
                26.793, 26.015, 26.403, 26.366, 25.103,
                24.313, 24.468, 24.141, 23.567, 23.902,
                23.661, 24.223, 23.731, 23.684, 23.686,
                23.612, 23.538
            ],
            date: calendar.date(from: DateComponents(year: 2026, month: 3, day: 17, hour: 20, minute: 0)) ?? Date.distantPast
        ),
        Heat(
            identifier: "formulakart-2026-03-17-heat-71",
            track: .formulaKart,
            kart: .fkKart,
            lapDurations: [
                23.852, 23.617, 23.719, 23.585, 23.362,
                23.366, 23.457, 23.337, 23.347, 23.357,
                23.501, 23.393, 23.245, 23.671, 24.235,
                23.587
            ],
            date: calendar.date(from: DateComponents(year: 2026, month: 3, day: 17, hour: 20, minute: 10)) ?? Date.distantPast
        ),
        Heat(
            identifier: "formulakart-2026-03-17-heat-75",
            track: .formulaKart,
            kart: .fkKart,
            lapDurations: [
                25.115, 25.075, 25.938, 30.339, 24.938,
                24.401, 24.440, 24.311, 24.961, 24.758,
                24.414, 24.241, 23.900, 24.009, 24.028,
                24.386, 24.326, 24.380
            ],
            date: calendar.date(from: DateComponents(year: 2026, month: 3, day: 17, hour: 20, minute: 20)) ?? Date.distantPast
        ),
        Heat(
            identifier: "formulakart-2026-03-17-heat-76",
            track: .formulaKart,
            kart: .fkKart,
            lapDurations: [
                23.888, 24.958, 23.874, 23.817, 23.403,
                23.419, 23.502, 23.677, 23.408, 23.480,
                23.473, 23.737, 24.021, 23.402, 23.564,
                23.454, 23.371
            ],
            date: calendar.date(from: DateComponents(year: 2026, month: 3, day: 17, hour: 20, minute: 30)) ?? Date.distantPast
        ),

        Heat(
            identifier: "p1speedway-2026-02-08-heat-1",
            track: .p1Speedway,
            kart: .sodiRental,
            lapDurations: [76.72, 75.35, 80.07, 74.79, 75.61],
            date: calendar.date(from: DateComponents(year: 2026, month: 2, day: 8, hour: 11, minute: 0)) ?? Date.distantPast
        ),
        Heat(
            identifier: "p1speedway-2026-02-08-heat-2",
            track: .p1Speedway,
            kart: .sodiRental,
            lapDurations: [
                75.21, 74.49, 73.73, 73.10, 74.35,
                73.27, 74.18, 73.19, 73.63, 73.49
            ],
            date: calendar.date(from: DateComponents(year: 2026, month: 2, day: 8, hour: 11, minute: 30)) ?? Date.distantPast
        ),
        Heat(
            identifier: "p1speedwayinverse-2026-04-09-heat-1",
            track: .p1SpeedwayInverse,
            kart: .sodiRental,
            lapDurations: [
                87.987, 82.762, 84.400, 80.101, 79.324,
                79.555, 78.731, 80.567, 78.747
            ],
            date: calendar.date(from: DateComponents(year: 2026, month: 4, day: 9, hour: 16, minute: 13)) ?? Date.distantPast
        ),
        Heat(
            identifier: "p1speedwayinverse-2026-04-09-heat-2",
            track: .p1SpeedwayInverse,
            kart: .sodiRental,
            lapDurations: [81.392, 78.362, 78.696, 79.748],
            date: calendar.date(from: DateComponents(year: 2026, month: 4, day: 9, hour: 16, minute: 50)) ?? Date.distantPast
        ),
        Heat(
            identifier: "p1speedwayinverse-2026-04-09-heat-3",
            track: .p1SpeedwayInverse,
            kart: .sodiRental,
            lapDurations: [79.923, 93.808, 79.705, 79.873],
            date: calendar.date(from: DateComponents(year: 2026, month: 4, day: 9, hour: 17, minute: 21)) ?? Date.distantPast
        )
    ]


    static let races: [Race] = [
        Race(
            track: .p1Speedway,
            kart: .sodiRental,
            heats: [
                Heat(
                    identifier: "E82E774B72637180-2147484742-1073749963",
                    type: .quali,
                    carNumber: "14",
                    track: .p1Speedway,
                    kart: .sodiRental,
                    laps: qualifierLaps(track: .p1Speedway, kart: .sodiRental, date: calendar.date(from: DateComponents(year: 2026, month: 4, day: 11, hour: 18, minute: 30)) ?? Date.distantPast),
                    date: calendar.date(from: DateComponents(year: 2026, month: 4, day: 11, hour: 18, minute: 30)) ?? Date.distantPast
                ),
                Heat(
                    identifier: "E82E774B72637180-2147484742-1073749966",
                    type: .race,
                    carNumber: "08",
                    track: .p1Speedway,
                    kart: .sodiRental,
                    laps: raceLaps(track: .p1Speedway, kart: .sodiRental, date: calendar.date(from: DateComponents(year: 2026, month: 4, day: 11, hour: 19, minute: 20)) ?? Date.distantPast),
                    date: calendar.date(from: DateComponents(year: 2026, month: 4, day: 11, hour: 19, minute: 20)) ?? Date.distantPast
                )
            ]
        )
    ]

    private static func qualifierLaps(track: Track, kart: Kart, date: Date) -> [Lap] {
        allCompetitorLaps(track: track, kart: kart, date: date, competitors: [
            ("13871272", "Esteban Porras", "04", [49.601, 46.589, 46.688, 46.538, 45.993, 46.402, 47.031, 46.143, 45.724]),
            ("7048573", "Santiago Delgado", "09", [49.074, 47.084, 46.242, 46.321, 46.273, 46.041, 46.432, 45.867, 45.967]),
            ("10927270", "Marco Ramirez", "01", [47.315, 47.157, 46.854, 46.310, 48.113, 46.330, 46.590, 46.518, 46.364]),
            ("8228829", "Hans Molina", "12", [47.283, 46.881, 46.844, 46.939, 46.538, 47.197, 46.585, 46.427, 46.395]),
            ("12680280", "Justin Miguel Jimenez", "02", [50.103, 48.251, 46.906, 48.336, 56.050, 49.720, 46.572, 46.489]),
            ("2566194", "Antonio Rojas", "18", [50.331, 50.587, 48.341, 47.018, 47.145, 48.398, 47.243, 47.009, 46.511]),
            ("6824862", "Samuel Villalobos", "11", [49.127, 50.652, 47.314, 47.463, 50.236, 48.383, 47.209, 46.547]),
            ("11548670", "Federico Pacheco", "05", [48.828, 49.114, 47.211, 47.530, 53.889, 47.923, 46.586, 46.677]),
            ("13248252", "Mauricio Garro", "03", [50.208, 47.702, 48.975, 46.628, 46.656, 47.292, 46.745, 46.686, 46.907]),
            ("11609723", "Andres Aguilar", "14", [48.406, 48.167, 47.487, 47.938, 47.339, 47.575, 47.334, 47.354, 47.312]),
            ("4767301", "Patrick Vindas", "16", [48.574, 48.577, 48.158, 47.392, 48.931, 53.276, 47.612, 49.328]),
            ("6101164", "Jose Carlos Gutierrez", "10", [47.399, 48.207, 47.568, 47.420, 138.961, 48.826]),
            ("3774931", "Jonathan Artavia", "24", [51.679, 48.879, 48.335, 50.060, 49.127, 49.687, 47.814, 47.894]),
            ("16595332", "Daniella Sanchez", "06", [51.143, 51.115, 50.127, 49.758, 57.145, 49.776, 49.049, 48.137]),
            ("11024274", "Josue Roberto Rojas", "07", [50.691, 49.847, 49.003, 48.710, 49.690, 49.453, 49.194, 48.287]),
            ("5373404", "Sebastian Montero", "17", [52.534, 62.476, 51.274, 48.779, 50.151, 62.039, 49.812]),
            ("3533068", "Sergio Ramos", "20", [57.636, 50.956, 51.382, 50.339, 51.630, 52.400, 51.436, 50.657]),
            ("13820677", "Maria Paola Sanchez", "08", [55.729, 55.607, 55.435, 59.602, 55.618, 52.922, 51.824]),
        ])
    }

    private static func raceLaps(track: Track, kart: Kart, date: Date) -> [Lap] {
        allCompetitorLaps(track: track, kart: kart, date: date, competitors: [
            ("12864952", "Marco Ramirez", "13", [48.425, 46.045, 46.708, 45.700, 45.947, 45.935, 45.907, 45.989, 46.874]),
            ("3774931", "Hans Molina", "24", [49.750, 46.357, 46.127, 45.738, 45.560, 45.796, 45.725, 45.852, 46.310]),
            ("10927270", "Esteban Porras", "01", [51.471, 46.780, 46.408, 46.248, 47.066, 46.849, 46.588, 46.645, 47.009]),
            ("7048573", "Samuel Villalobos", "09", [50.957, 47.481, 46.868, 46.341, 46.457, 46.267, 46.479, 47.279, 46.115]),
            ("5373404", "Santiago Hidalgo", "17", [52.176, 46.565, 47.220, 46.277, 46.506, 46.088, 46.972, 48.399, 45.925]),
            ("6824862", "Federico Pacheco", "11", [49.942, 46.900, 46.430, 45.996, 48.170, 47.016, 47.996, 47.607, 46.102]),
            ("13820677", "Andres Aguilar", "08", [50.759, 48.923, 47.393, 46.583, 46.618, 46.799, 46.645, 47.347, 45.881]),
            ("2566194", "Mauricio Garro", "18", [53.138, 47.643, 47.703, 47.113, 46.364, 46.277, 46.107, 46.513, 45.761]),
            ("3533068", "Patrick Vindas", "20", [52.688, 47.318, 48.484, 47.181, 46.661, 46.638, 46.491, 47.266, 46.654]),
            ("11548670", "Daniella Sanchez", "05", [53.853, 49.932, 48.430, 46.745, 49.183, 47.553, 47.342, 47.176, 47.224]),
            ("13248252", "Jose Carlos Gutierrez", "03", [53.360, 50.766, 50.104, 46.871, 48.487, 47.892, 47.147, 46.851, 46.654]),
            ("11609723", "Justin Jimenez", "14", [54.385, 50.663, 48.492, 48.172, 49.188, 48.510, 48.340, 48.320, 51.550]),
            ("8228829", "Jonathan Lopez", "12", [55.270, 50.871, 48.768, 49.232, 48.987, 48.951, 49.061, 48.259, 47.875]),
            ("16595332", "Antonio Rojas", "06", [55.200, 52.444, 49.234, 50.068, 48.954, 48.933, 49.233, 49.264, 47.535]),
            ("13871272", "Josue Roberto Rojas", "04", [55.768, 49.900, 48.365, 49.510, 50.019, 49.693, 48.803, 48.955, 47.803]),
            ("11024274", "Sebastian Montero", "07", [53.807, 59.878, 53.353, 49.868, 48.839, 49.626, 51.807, 63.192]),
            ("6101164", "Maria Paola Sanchez", "10", [57.005, 59.377, 51.473, 51.982, 51.413, 53.346, 77.642, 51.045]),
            ("12680280", "Sergio Ramos", "02", [56.380, 88.165, 50.425, 55.089, 53.597, 53.756, 53.511, 50.302]),
        ])
    }

    private static func allCompetitorLaps(
        track: Track,
        kart: Kart,
        date: Date,
        competitors: [(id: String, name: String, number: String, lapTimes: [TimeInterval])]
    ) -> [Lap] {
        competitors.flatMap { competitor in
            competitor.lapTimes.enumerated().map { index, duration in
                Lap(
                    track: track,
                    kart: kart,
                    competitorID: competitor.id,
                    driverName: competitor.name,
                    driverNumber: competitor.number,
                    lapNumber: index + 1,
                    duration: duration,
                    timestamp: date
                )
            }
        }
    }
}
