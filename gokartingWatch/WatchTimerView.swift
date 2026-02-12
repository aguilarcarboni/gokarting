import SwiftUI
import SwiftData
#if os(watchOS)
import WatchKit
import HealthKit
#endif

struct WatchTimerView: View {
    @State private var timerManager = TimerManager()
    @Environment(\.modelContext) private var modelContext
    @Environment(\.isLuminanceReduced) var isLuminanceReduced
    @StateObject private var syncMonitor = CloudSyncMonitor()

    // Workout session keeps the app foregrounded + Always-On Display active
    #if os(watchOS)
    @State private var workoutManager = WorkoutManager()
    #endif

    // State for finish confirmation
    @State private var isLongPressing = false
    @State private var showSummary = false
    @State private var lastSavedSession: Session?

    // Digital Crown state for physical-button lap triggers
    #if os(watchOS)
    @State private var crownValue: Double = 0
    @State private var lastCrownLapValue: Double = 0
    private let crownLapThreshold: Double = 5.0
    #endif

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                VStack(spacing: 6) {
                    if timerManager.isRunning {
                        timerDisplay
                    } else {
                        startPrompt
                    }
                }
            }
            // Full-screen tap target
            .contentShape(Rectangle())
            .onTapGesture {
                handleTap()
            }
            .onLongPressGesture(minimumDuration: 1.0, pressing: { pressing in
                if timerManager.isRunning {
                    isLongPressing = pressing
                }
            }) {
                if timerManager.isRunning {
                    stopSession()
                }
            }
            .overlay(alignment: .bottom) {
                if isLongPressing && timerManager.isRunning {
                    Text("HOLD TO STOP")
                        .font(.caption)
                        .padding()
                        .background(.red)
                        .cornerRadius(8)
                        .padding(.bottom, 20)
                }
            }
            // --- watchOS-specific: Crown laps, double-tap, workout session ---
            #if os(watchOS)
            .focusable(timerManager.isRunning)
            .digitalCrownRotation(
                $crownValue,
                from: 0.0,
                through: 100_000.0,
                sensitivity: .medium,
                isContinuous: false,
                isHapticFeedbackEnabled: true
            )
            .onChange(of: crownValue) { _, newValue in
                guard timerManager.isRunning else { return }
                let delta = abs(newValue - lastCrownLapValue)
                if delta >= crownLapThreshold {
                    timerManager.lap()
                    playHaptic(.directionUp)
                    lastCrownLapValue = newValue
                }
            }
            // Double-tap gesture (Apple Watch Series 9+ / Ultra 2+)
            .background {
                if timerManager.isRunning {
                    lapGestureButton
                }
            }
            .task {
                await workoutManager.requestAuthorization()
            }
            #endif
        }
    }

    // MARK: - Subviews

    @ViewBuilder
    private var timerDisplay: some View {
        let dimmed = isLuminanceReduced

        // Current lap elapsed time
        Text(timerManager.formatTime(timerManager.elapsedTime))
            .font(.system(size: dimmed ? 28 : 34, weight: .bold, design: .monospaced))
            .foregroundStyle(dimmed ? .white.opacity(0.6) : .white)
            .minimumScaleFactor(0.6)
            .lineLimit(1)

        // Lap counter
        Text("LAP \(timerManager.laps.count + 1)")
            .font(.subheadline)
            .foregroundStyle(.yellow)

        // Previous lap (hidden when dimmed to save power)
        if !dimmed, let last = timerManager.laps.last {
            Text("PREV: \(timerManager.formatTime(last))")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }

        // Crown hint (hidden when dimmed)
        if !dimmed {
            HStack(spacing: 4) {
                Image(systemName: "digitalcrown.arrow.clockwise")
                Text("LAP")
            }
            .font(.system(size: 10))
            .foregroundStyle(.secondary)
            .padding(.top, 2)
        }
    }

    private var startPrompt: some View {
        VStack(spacing: 20) {
            Image(systemName: "flag.checkered")
                .font(.system(size: 50))
            Text("TAP TO START")
                .font(.headline)
                .fontWeight(.heavy)
            WatchSyncDot(state: syncMonitor.syncState)
        }
    }

    #if os(watchOS)
    /// Invisible button that registers for the double-tap hand gesture.
    /// This lets the user record a lap by double-tapping thumb-to-index
    /// on Apple Watch Series 9+ / Ultra 2+, even with the wrist lowered.
    @ViewBuilder
    private var lapGestureButton: some View {
        Button(action: {
            timerManager.lap()
            playHaptic(.directionUp)
        }) {
            Color.clear
        }
        .buttonStyle(.plain)
        .handGestureShortcut(.primaryAction)
        .allowsHitTesting(false)
    }
    #endif

    // MARK: - Actions

    private func handleTap() {
        if !timerManager.isRunning {
            timerManager.start()
            playHaptic(.start)
            #if os(watchOS)
            Task { await workoutManager.startWorkout() }
            #endif
        } else {
            timerManager.lap()
            playHaptic(.directionUp)
        }
    }

    private func stopSession() {
        timerManager.stop()
        playHaptic(.stop)

        lastSavedSession = timerManager.saveSession(context: modelContext)

        // Explicitly save so the session is persisted and synced to iCloud immediately
        do {
            try modelContext.save()
        } catch {
            print("⚠️ Failed to save session to store: \(error)")
        }

        timerManager.reset()
        showSummary = true

        #if os(watchOS)
        Task { await workoutManager.stopWorkout() }
        crownValue = 0
        lastCrownLapValue = 0
        #endif
    }

    private func playHaptic(_ type: WKHapticType) {
        #if os(watchOS)
        WKInterfaceDevice.current().play(type)
        #endif
    }
}

struct WatchSyncDot: View {
    let state: SyncState

    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(dotColor)
                .frame(width: 6, height: 6)
            Text(label)
                .font(.system(size: 10))
                .foregroundStyle(.secondary)
        }
    }

    private var dotColor: Color {
        switch state {
        case .synced:       return .green
        case .syncing:      return .orange
        case .error:        return .red
        case .notAvailable: return .gray
        }
    }

    private var label: String {
        switch state {
        case .synced:       return "iCloud"
        case .syncing:      return "Syncing"
        case .error:        return "Sync Error"
        case .notAvailable: return "Offline"
        }
    }
}

#if !os(watchOS)
// Shim for iOS preview/compilation if shared file
enum WKHapticType {
    case start, stop, directionUp, success
}
#endif
