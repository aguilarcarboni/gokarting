import Foundation
import SwiftData

@Model
final class Lap {
    var id: UUID
    var lapNumber: Int
    var duration: TimeInterval
    var timestamp: Date
    
    var session: Session?
    
    init(lapNumber: Int, duration: TimeInterval, timestamp: Date = Date()) {
        self.id = UUID()
        self.lapNumber = lapNumber
        self.duration = duration
        self.timestamp = timestamp
    }
}
