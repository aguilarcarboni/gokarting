import SwiftUI
import SwiftData
#if os(watchOS)
import WatchKit
#endif

struct WatchTimerView: View {
    @State private var timerManager = TimerManager()
    @Environment(\.modelContext) private var modelContext
    
    // State for finish confirmation
    @State private var isLongPressing = false
    @State private var showSummary = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                // background color status
                Color.black.ignoresSafeArea()
                
                VStack(spacing: 8) {
                    if timerManager.isRunning {
                        // Current Lap Time
                        Text(timerManager.formatTime(timerManager.elapsedTime))
                            .font(.system(size: 44, weight: .bold, design: .monospaced))
                            // .contentTransition(.numericText()) // iOS 17/watchOS 10
                        
                        // Lap Count
                        Text("LAP \(timerManager.laps.count + 1)")
                            .font(.headline)
                            .foregroundStyle(.yellow)
                        
                        // Previous Lap
                        if let last = timerManager.laps.last {
                            Text("PREV: \(timerManager.formatTime(last))")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    } else {
                        VStack(spacing: 20) {
                            Image(systemName: "flag.checkered")
                                .font(.system(size: 50))
                            Text("TAP TO START")
                                .font(.headline)
                                .fontWeight(.heavy)
                        }
                    }
                }
            }
            // The "Big Button" Logic
            .contentShape(Rectangle()) // Ensure the whole area is tappable
            .onTapGesture {
                handleTap()
            }
            .onLongPressGesture(minimumDuration: 1.0, pressing: { pressing in
                isLongPressing = pressing
            }) {
                // Long press to Stop
                if timerManager.isRunning {
                    stopSession()
                }
            }
            .overlay(alignment: .bottom) {
                if isLongPressing {
                    Text("HOLD TO STOP")
                        .font(.caption)
                        .padding()
                        .background(.red)
                        .cornerRadius(8)
                        .padding(.bottom, 20)
                }
            }
            .navigationDestination(isPresented: $showSummary) {
                Text("Session Saved") // Placeholder for Summary View
            }
        }
    }
    
    private func handleTap() {
        if !timerManager.isRunning {
            timerManager.start()
            playHaptic(.start)
        } else {
            timerManager.lap()
            playHaptic(.directionUp)
        }
    }
    
    private func stopSession() {
        timerManager.stop()
        playHaptic(.stop)
        
        // Save to SwiftData (Syncs via CloudKit automatically)
        timerManager.saveSession(context: modelContext)
        
        timerManager.reset()
        showSummary = true
    }
    
    private func playHaptic(_ type: WKHapticType) {
        #if os(watchOS)
        WKInterfaceDevice.current().play(type)
        #endif
    }
}

#if os(watchOS)
import WatchKit
#else
// Shim for iOS preview/compilation if shared file
enum WKHapticType {
    case start, stop, directionUp, success
}
#endif
