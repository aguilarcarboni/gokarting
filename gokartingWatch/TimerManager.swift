import SwiftUI
import SwiftData

@Observable
class TimerManager {
    var isRunning = false
    var elapsedTime: TimeInterval = 0
    var laps: [Double] = []
    
    // Internal state
    private var startDate: Date?
    private var lastLapDate: Date?
    private var timer: Timer?
    
    // Debounce config
    private let debounceInterval: TimeInterval = 2.0
    
    // Formatter
    static let durationFormatter: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.minute, .second]
        formatter.zeroFormattingBehavior = .pad
        return formatter
    }()
    
    // Helper for milliseconds
    func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        let milliseconds = Int((time.truncatingRemainder(dividingBy: 1)) * 100)
        return String(format: "%02d:%02d.%02d", minutes, seconds, milliseconds)
    }
    
    func toggle() {
        if isRunning {
            stop()
        } else {
            start()
        }
    }
    
    func start() {
        guard !isRunning else { return }
        
        startDate = Date()
        lastLapDate = startDate
        isRunning = true
        
        // Start a timer just for UI updates (display only)
        // High frequency for smooth UI, but logic relies on Date()
        timer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
            guard let self = self, let start = self.startDate else { return }
            self.elapsedTime = Date().timeIntervalSince(start)
        }
    }
    
    func stop() {
        guard isRunning else { return }
        isRunning = false
        timer?.invalidate()
        timer = nil
        // Finalize session logic here if needed
    }
    
    func lap() {
        guard isRunning, let lastLap = lastLapDate else { return }
        
        let now = Date()
        // Debounce check
        guard now.timeIntervalSince(lastLap) > debounceInterval else {
            print("Ignored ghost tap")
            return
        }
        
        // Calculate lap duration
        let lapDuration = now.timeIntervalSince(lastLap)
        laps.append(lapDuration)
        
        lastLapDate = now
        
        // Reset start date for the next lap relative reference if we want split time
        // Or keep startDate as session start and just track splits.
        // User said: "Reference Timing: Store a startDate = Date(). When a split is triggered, record Date().timeIntervalSince(startDate)."
        // This implies `timeIntervalSince(startDate)` is the *total* time? Or the split?
        // Usually a lap timer needs the *lap* time.
        // If I reset `startDate` (or `lastLapDate`), I get the lap time.
        // Let's assume we want Lap Time.
        
        // Logic:
        // Lap 1: Start -> Tap (Duration = Tap - Start)
        // Lap 2: Tap 1 -> Tap 2 (Duration = Tap 2 - Tap 1)
        
        // So `lastLapDate` is the correct anchor.
    }
    
    func reset() {
        stop()
        elapsedTime = 0
        laps.removeAll()
        startDate = nil
        lastLapDate = nil
    }
    
    // Save to SwiftData
    @discardableResult
    func saveSession(context: ModelContext) -> Session? {
        guard !laps.isEmpty else { return nil }
        
        let session = Session(date: startDate ?? Date())
        for (index, duration) in laps.enumerated() {
            let lap = Lap(lapNumber: index + 1, duration: duration)
            lap.session = session // Relationship handles the append
        }
        
        context.insert(session)
        
        // Attempt to save context immediately to generate IDs if needed, 
        // though SwiftData autosaves.
        
        return session
    }
}
