import Foundation
import SwiftData

class DataSeeder {
    @MainActor
    static func seed(context: ModelContext) {
        seedFIK(context: context)
        seedFormulaKart(context: context)
        seedP1Speedway(context: context)
    }
    
    // MARK: - FIK Sessions
    
    @MainActor
    private static func seedFIK(context: ModelContext) {
        let calendar = Calendar.current
        var dateComponents = DateComponents()
        
        // MARK: Nov 22, 2025 Data
        dateComponents.year = 2025
        dateComponents.month = 11
        dateComponents.day = 22
        
        // Heat 1
        dateComponents.hour = 15
        dateComponents.minute = 46

        let date1 = calendar.date(from: dateComponents) ?? Date()
        let session1 = Session(date: date1, note: "Heat 1", track: .fik)
        let laps1 = [
            39.158, 33.545, 33.860, 33.734, 30.998,
            31.876, 30.742, 30.274, 30.577, 29.371,
            27.504, 26.786, 26.486
        ]
        addLaps(laps1, to: session1)
        context.insert(session1)

        // Heat 2
        dateComponents.hour = 16
        dateComponents.minute = 23

        let date2 = calendar.date(from: dateComponents) ?? Date()
        let session2 = Session(date: date2, note: "Heat 2", track: .fik)
        let laps2 = [
            51.24, 83.753, 26.593, 26.486, 31.18,
            28.913, 30.397, 60.457, 31.132, 26.614
        ]
        addLaps(laps2, to: session2)
        context.insert(session2)

        // Heat 3
        dateComponents.hour = 16
        dateComponents.minute = 30

        let date3 = calendar.date(from: dateComponents) ?? Date()
        let session3 = Session(date: date3, note: "Heat 3", track: .fik)
        let laps3 = [
            41.484, 26.394, 28.327, 28.798, 27.210,
            30.373, 61.250, 25.888, 25.446, 26.495,
            26.91, 25.925, 31.807
        ]
        addLaps(laps3, to: session3)
        context.insert(session3)
                
        // Heat 4
        dateComponents.hour = 17
        dateComponents.minute = 21
        let date4 = calendar.date(from: dateComponents) ?? Date()
        let session4 = Session(date: date4, note: "Heat 4", track: .fik)
        let laps4 = [
            55.334, 27.439, 26.324, 26.917, 25.306,
            25.990, 25.553, 24.785, 25.940, 25.809,
            24.899, 27.180, 26.240, 25.561
        ]
        addLaps(laps4, to: session4)
        context.insert(session4)

        // Heat 5
        dateComponents.hour = 17
        dateComponents.minute = 28
        let date5 = calendar.date(from: dateComponents) ?? Date()
        let session5 = Session(date: date5, note: "Heat 5", track: .fik)
        let laps5 = [
            26.725, 24.995, 25.359, 26.574, 25.695,
            27.897, 40.433, 24.882, 24.364, 25.12,
            24.644, 39.677, 25.300, 26.315
        ]
        addLaps(laps5, to: session5)
        context.insert(session5)

        // MARK: Dec 15, 2025 Data
        dateComponents.year = 2025
        dateComponents.month = 12
        dateComponents.day = 15
        
        // Heat 1
        dateComponents.hour = 15
        dateComponents.minute = 06
        let dateDec1 = calendar.date(from: dateComponents) ?? Date()
        let sessionDec1 = Session(date: dateDec1, note: "Heat 1", track: .fik)
        let lapsDec1 = [
            30.214, 29.396, 28.486, 25.894, 28.864,
            25.989, 25.562, 24.472, 27.734, 25.557,
            24.934, 25.82, 41.801, 25.518
        ]
        addLaps(lapsDec1, to: sessionDec1)
        context.insert(sessionDec1)

        // Heat 2
        dateComponents.hour = 16
        dateComponents.minute = 17
        let dateDec2 = calendar.date(from: dateComponents) ?? Date()
        let sessionDec2 = Session(date: dateDec2, note: "Heat 2", track: .fik)
        let lapsDec2 = [
            26.210, 51.805, 30.304, 28.278, 26.129,
            29.500, 25.896, 25.410, 53.220, 24.263,
            25.929, 25.670, 26.102, 31.428, 30.358,
            25.841, 44.787, 23.893, 24.603, 25.503,
            24.388, 24.591, 24.493, 25.812, 25.832,
            27.35, 26.234, 24.160
        ]
        addLaps(lapsDec2, to: sessionDec2)
        context.insert(sessionDec2)

        // MARK: January 2, 2026 Data
        dateComponents.year = 2026
        dateComponents.month = 1
        dateComponents.day = 2
        
        // Heat 1
        dateComponents.hour = 16
        dateComponents.minute = 56
        let dateJan1 = calendar.date(from: dateComponents) ?? Date()
        let sessionJan1 = Session(date: dateJan1, note: "Heat 1", track: .fik)
        let lapsJan1 = [
            38.156, 41.551, 24.468, 23.850, 23.588,
            24.547, 23.893, 24.202, 23.760, 23.882,
            23.300, 23.352, 23.138, 23.521, 23.643,
            24.446
        ]
        addLaps(lapsJan1, to: sessionJan1)
        context.insert(sessionJan1)

        // Heat 2
        dateComponents.hour = 17
        dateComponents.minute = 24
        let dateJan2 = calendar.date(from: dateComponents) ?? Date()
        let sessionJan2 = Session(date: dateJan2, note: "Heat 2", track: .fik)
        let lapsJan2 = [
            24.609, 24.157, 24.74, 23.714, 23.85,
            23.692, 23.251, 23.144, 23.158, 22.812,
            22.975, 24.12, 23.443, 23.484, 23.278,
            23.530, 39.369, 23.757, 24.318, 23.361,
            23.207, 24.553, 24.562, 23.940, 24.359,
            56.21, 23.719, 24.731, 27.248, 24.690,
            23.500
        ]
        addLaps(lapsJan2, to: sessionJan2)
        context.insert(sessionJan2)
    }
    
    // MARK: - Formula Kart Sessions
    
    @MainActor
    private static func seedFormulaKart(context: ModelContext) {
        let calendar = Calendar.current
        var dateComponents = DateComponents()
        
        // MARK: Nov 30, 2025 Data
        dateComponents.year = 2025
        dateComponents.month = 11
        dateComponents.day = 30
        
        // Heat 1
        dateComponents.hour = 13
        dateComponents.minute = 10
        let dateNov30 = calendar.date(from: dateComponents) ?? Date()
        let sessionNov30 = Session(date: dateNov30, note: "Heat 1", track: .formulaKart)
        let lapsNov30 = [
            31.723, 29.031, 27.943, 26.875, 26.901,
            28.450, 26.180, 25.332, 26.091, 26.790,
            25.914, 27.802, 26.760
        ]
        addLaps(lapsNov30, to: sessionNov30)
        context.insert(sessionNov30)

        // MARK: January 19, 2026 Data
        dateComponents.year = 2026
        dateComponents.month = 1
        dateComponents.day = 19
        
        // Heat 1
        dateComponents.hour = 14
        dateComponents.minute = 30
        let dateJan19_1 = calendar.date(from: dateComponents) ?? Date()
        let sessionJan19_1 = Session(date: dateJan19_1, note: "Heat 1", track: .formulaKart)
        let lapsJan19_1 = [
            27.359, 26.834, 26.190, 26.668, 28.574,
            26.535, 25.834, 25.878, 25.336, 25.751,
            25.688, 26.978, 25.546, 25.060, 26.925
        ]
        addLaps(lapsJan19_1, to: sessionJan19_1)
        context.insert(sessionJan19_1)

        // Heat 2
        dateComponents.hour = 15
        dateComponents.minute = 10
        let dateJan19_2 = calendar.date(from: dateComponents) ?? Date()
        let sessionJan19_2 = Session(date: dateJan19_2, note: "Heat 2", track: .formulaKart)
        let lapsJan19_2 = [
            26.768, 26.199, 25.703, 28.863, 25.834,
            24.829, 25.142, 25.023, 25.273, 24.853,
            25.140, 24.392, 24.636, 24.840, 25.133,
            26.575
        ]
        addLaps(lapsJan19_2, to: sessionJan19_2)
        context.insert(sessionJan19_2)

        // Heat 3
        dateComponents.hour = 15
        dateComponents.minute = 20
        let dateJan19_3 = calendar.date(from: dateComponents) ?? Date()
        let sessionJan19_3 = Session(date: dateJan19_3, note: "Heat 3", track: .formulaKart)
        let lapsJan19_3 = [
            25.130, 25.028, 25.256, 25.467, 25.122,
            25.250, 24.757, 24.847, 24.987, 25.978,
            25.747, 25.515, 24.834, 24.890
        ]
        addLaps(lapsJan19_3, to: sessionJan19_3)
        context.insert(sessionJan19_3)

        // Heat 4
        dateComponents.hour = 15
        dateComponents.minute = 40
        let dateJan19_4 = calendar.date(from: dateComponents) ?? Date()
        let sessionJan19_4 = Session(date: dateJan19_4, note: "Heat 4", track: .formulaKart)
        let lapsJan19_4 = [
            25.993, 25.345, 25.148, 28.919, 25.691,
            24.686, 25.838, 24.545, 24.370, 27.517,
            24.485, 24.846, 24.674, 24.507, 24.666,
            25.685
        ]
        addLaps(lapsJan19_4, to: sessionJan19_4)
        context.insert(sessionJan19_4)

        // Heat 5
        dateComponents.hour = 16
        dateComponents.minute = 00
        let dateJan19_5 = calendar.date(from: dateComponents) ?? Date()
        let sessionJan19_5 = Session(date: dateJan19_5, note: "Heat 5", track: .formulaKart)
        let lapsJan19_5 = [
            26.695, 25.784, 24.945, 25.010, 24.883,
            26.234, 24.504, 24.421, 24.382, 24.535,
            24.350, 24.828, 24.786, 24.876, 24.471,
            24.466
        ]
        addLaps(lapsJan19_5, to: sessionJan19_5)
        context.insert(sessionJan19_5)

        // MARK: January 27, 2026 Data
        dateComponents.year = 2026
        dateComponents.month = 1
        dateComponents.day = 27
        
        // Heat 1
        dateComponents.hour = 17
        dateComponents.minute = 40
        let dateJan27_1 = calendar.date(from: dateComponents) ?? Date()
        let sessionJan27_1 = Session(date: dateJan27_1, note: "Heat 1", track: .formulaKart)
        let lapsJan27_1 = [
            25.563, 26.234, 25.929, 25.790, 25.800,
            26.175, 25.918, 25.396, 26.217, 25.276,
            25.102, 25.211, 25.337, 24.934, 24.817,
            24.788
        ]
        addLaps(lapsJan27_1, to: sessionJan27_1)
        context.insert(sessionJan27_1)

        // Heat 2
        dateComponents.hour = 17
        dateComponents.minute = 50
        let dateJan27_2 = calendar.date(from: dateComponents) ?? Date()
        let sessionJan27_2 = Session(date: dateJan27_2, note: "Heat 2", track: .formulaKart)
        let lapsJan27_2 = [
            24.485, 24.625, 24.804, 24.736, 24.333,
            24.502, 24.516, 24.271, 24.567, 24.220,
            24.391, 24.550, 24.483, 24.935, 24.152,
            24.107, 24.771
        ]
        addLaps(lapsJan27_2, to: sessionJan27_2)
        context.insert(sessionJan27_2)

        // Heat 3
        dateComponents.hour = 18
        dateComponents.minute = 10
        let dateJan27_3 = calendar.date(from: dateComponents) ?? Date()
        let sessionJan27_3 = Session(date: dateJan27_3, note: "Heat 3", track: .formulaKart)
        let lapsJan27_3 = [
            25.080, 25.430, 26.162, 25.175, 24.708,
            24.664, 24.399, 24.778, 24.161, 24.431,
            25.713, 24.347, 24.344, 24.193, 24.535,
            24.342
        ]
        addLaps(lapsJan27_3, to: sessionJan27_3)
        context.insert(sessionJan27_3)

        // Heat 4
        dateComponents.hour = 18
        dateComponents.minute = 20
        let dateJan27_4 = calendar.date(from: dateComponents) ?? Date()
        let sessionJan27_4 = Session(date: dateJan27_4, note: "Heat 4", track: .formulaKart)
        let lapsJan27_4 = [
            24.401, 24.008, 23.697, 23.760, 24.779,
            23.564, 23.868, 23.531, 23.714, 23.890,
            23.872, 23.720, 23.863, 24.406, 23.604,
            25.488
        ]
        addLaps(lapsJan27_4, to: sessionJan27_4)
        context.insert(sessionJan27_4)

        // MARK: February 4, 2026 Data
        dateComponents.year = 2026
        dateComponents.month = 2
        dateComponents.day = 4
        
        // Heat 1
        dateComponents.hour = 19
        dateComponents.minute = 40
        let dateFeb4_1 = calendar.date(from: dateComponents) ?? Date()
        let sessionFeb4_1 = Session(date: dateFeb4_1, note: "Heat 1", track: .formulaKart)
        let lapsFeb4_1 = [
            24.881, 24.588, 24.261, 24.162, 24.342,
            24.145, 24.114, 23.954, 24.070, 24.204,
            24.073, 23.926, 23.772, 24.110, 24.017,
            23.565, 23.625
        ]
        addLaps(lapsFeb4_1, to: sessionFeb4_1)
        context.insert(sessionFeb4_1)

        // Heat 2
        dateComponents.hour = 19
        dateComponents.minute = 50
        let dateFeb4_2 = calendar.date(from: dateComponents) ?? Date()
        let sessionFeb4_2 = Session(date: dateFeb4_2, note: "Heat 2", track: .formulaKart)
        let lapsFeb4_2 = [
            23.559, 23.777, 23.385, 23.745, 23.406,
            23.619, 23.661, 23.426, 23.896, 23.705,
            23.377, 23.571, 23.906, 23.393, 23.746,
            23.513, 24.013
        ]
        addLaps(lapsFeb4_2, to: sessionFeb4_2)
        context.insert(sessionFeb4_2)
    }
    
    // MARK: - P1 Speedway Sessions
    
    @MainActor
    private static func seedP1Speedway(context: ModelContext) {
        let calendar = Calendar.current
        var dateComponents = DateComponents()
        
        // MARK: February 8, 2026 Data
        dateComponents.year = 2026
        dateComponents.month = 2
        dateComponents.day = 8
        
        // Heat 1
        dateComponents.hour = 11
        dateComponents.minute = 00
        let dateFeb8_1 = calendar.date(from: dateComponents) ?? Date()
        let sessionFeb8_1 = Session(date: dateFeb8_1, note: "Heat 1", track: .p1Speedway)
        let lapsFeb8_1 = [
            76.72, 75.35, 80.07, 74.79, 75.61
        ]
        addLaps(lapsFeb8_1, to: sessionFeb8_1)
        context.insert(sessionFeb8_1)

        // Heat 2
        dateComponents.hour = 11
        dateComponents.minute = 30
        let dateFeb8_2 = calendar.date(from: dateComponents) ?? Date()
        let sessionFeb8_2 = Session(date: dateFeb8_2, note: "Heat 2", track: .p1Speedway)
        let lapsFeb8_2 = [
            75.21, 74.49, 73.73, 73.10, 74.35,
            73.27, 74.18, 73.19, 73.63, 73.49
        ]
        addLaps(lapsFeb8_2, to: sessionFeb8_2)
        context.insert(sessionFeb8_2)
    }
    
    private static func addLaps(_ durations: [Double], to session: Session) {
        for (i, d) in durations.enumerated() {
            let lap = Lap(lapNumber: i+1, duration: d)
            lap.session = session
        }
    }
}
