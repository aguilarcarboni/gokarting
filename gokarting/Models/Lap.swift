import Foundation
import SwiftData

@Model
final class Lap {
    var id: UUID = UUID()
    var lapNumber: Int = 0
    var duration: TimeInterval = 0
    var timestamp: Date = Date()
    
    var session: Session? = nil
    
    init(lapNumber: Int, duration: TimeInterval, timestamp: Date = Date()) {
        self.id = UUID()
        self.lapNumber = lapNumber
        self.duration = duration
        self.timestamp = timestamp
    }
}
