import SwiftUI
import MapKit
#if canImport(UIKit)
import UIKit
#endif

struct LiveTimingView: View {
    @StateObject private var viewModel = LiveTimingViewModel()
    @State private var setupCameraPosition: MapCameraPosition = .automatic
    @State private var summaryCameraPosition: MapCameraPosition = .automatic
    @State private var selectedLapNumber: Int?
    @State private var showLiveLaps = false

    private var gatePolyline: [CLLocationCoordinate2D] {
        [viewModel.currentGate.pointA.clCoordinate, viewModel.currentGate.pointB.clCoordinate]
    }

    private var routePolyline: [CLLocationCoordinate2D] {
        viewModel.route.map(\.clCoordinate)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 14) {
                phaseContent
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 12)
            .appScreenBackground()
            .navigationTitle("Session")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(viewModel.phase == .live ? .hidden : .visible, for: .tabBar)
            .toolbar(viewModel.phase == .live ? .hidden : .visible, for: .navigationBar)
            .onAppear {
                viewModel.requestPermissions()
                setupCameraPosition = .region(mapRegion(for: viewModel.currentGate))
                summaryCameraPosition = .region(mapRegion(for: viewModel.currentGate))
                updateOrientation(for: viewModel.phase)
            }
            .onChange(of: viewModel.selectedTrack) { _, _ in
                setupCameraPosition = .region(mapRegion(for: viewModel.currentGate))
                if viewModel.phase == .summary {
                    summaryCameraPosition = .region(mapRegion(for: viewModel.currentGate))
                }
            }
            .onChange(of: viewModel.phase) { _, newPhase in
                if newPhase == .live || newPhase == .summary {
                    summaryCameraPosition = .region(mapRegion(for: viewModel.currentGate))
                }
                if newPhase != .live {
                    showLiveLaps = false
                }
                updateOrientation(for: newPhase)
            }
            .onChange(of: viewModel.latestLap?.number) { _, newNumber in
                if let newNumber {
                    selectedLapNumber = newNumber
                }
            }
            .onDisappear {
                requestOrientation(.portrait)
            }
        }
    }

    private var phaseContent: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 14) {
                if viewModel.phase == .setup {
                    setupPanel
                }

                if viewModel.phase == .live {
                    HStack {
                        Spacer()
                        Button(role: .destructive, action: viewModel.finishSession) {
                            Image(systemName: "xmark")
                                .font(.caption.bold())
                                .frame(width: 28, height: 28)
                        }
                        .buttonStyle(.plain)
                        .glassCircleBackground()
                    }
                    livePanel
                }

                if viewModel.phase == .summary {
                    summaryPanel
                }
            }
            .padding(.bottom, 10)
        }
    }

    private var setupPanel: some View {
        VStack(spacing: 14) {
            card {
                VStack(spacing: 12) {
                    Text("Session Configuration")
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Picker("Track", selection: $viewModel.selectedTrack) {
                        ForEach(Track.allCases, id: \.self) { track in
                            Text(track.rawValue).tag(track)
                        }
                    }
                    .pickerStyle(.menu)

                    Picker("Direction", selection: $viewModel.raceDirection) {
                        ForEach(RaceDirection.allCases) { direction in
                            Text(direction.rawValue).tag(direction)
                        }
                    }
                    .pickerStyle(.segmented)
                }
            }

            card {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Start / Finish Gate")
                        .font(.headline)

                    Map(position: $setupCameraPosition, interactionModes: [.zoom, .pan]) {
                        MapPolyline(coordinates: gatePolyline)
                            .stroke(.red, lineWidth: 5)

                        Marker("A", coordinate: viewModel.currentGate.pointA.clCoordinate)
                            .tint(.red)
                        Marker("B", coordinate: viewModel.currentGate.pointB.clCoordinate)
                            .tint(.red)
                    }
                    .mapStyle(.imagery(elevation: .flat))
                    .mapControls {
                        MapUserLocationButton()
                    }
                    .frame(height: 220)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }
            }

            Button(action: viewModel.startSession) {
                Label("Start Live Session", systemImage: "bolt.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(.red)
            .controlSize(.large)

            Button("Request Sensor Permissions") {
                viewModel.requestPermissions()
            }
            .buttonStyle(.bordered)
            .controlSize(.large)
        }
    }

    private var livePanel: some View {
        VStack(spacing: 14) {
            HStack(spacing: 10) {
                metricCard(title: "Speed", value: formattedSpeed(viewModel.latestSample?.speedMPS ?? 0), accent: .green)
                metricCard(title: "Current", value: formattedTime(viewModel.currentLapElapsed), accent: .orange)
                metricCard(title: "Delta", value: formattedDelta(viewModel.currentLapDeltaToBest), accent: .yellow)
            }

            HStack(spacing: 10) {
                metricCard(title: "Best", value: formattedTime(viewModel.bestLap?.durationSeconds), accent: .mint)
                metricButtonCard(
                    title: "Laps",
                    value: "\(viewModel.laps.count)",
                    accent: .blue,
                    isActive: showLiveLaps
                ) {
                    showLiveLaps.toggle()
                }
                metricCard(title: "Session", value: formattedTime(viewModel.sessionElapsed), accent: .purple)
            }

            if showLiveLaps {
                card {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("All Laps")
                            .font(.headline)

                        if viewModel.laps.isEmpty {
                            Text("No completed laps yet.")
                                .foregroundStyle(.secondary)
                        } else {
                            ForEach(viewModel.laps.reversed()) { lap in
                                HStack {
                                    Text("Lap \(lap.number)")
                                        .fontWeight(.semibold)
                                    Spacer()
                                    Text(formattedTime(lap.durationSeconds))
                                        .monospacedDigit()
                                    Text(String(format: "%.2f m/s", lap.speedAtCrossingMPS))
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                .padding(.vertical, 2)
                            }
                        }
                    }
                }
            }
        }
    }

    private var summaryPanel: some View {
        VStack(spacing: 14) {
            HStack(spacing: 10) {
                metricCard(title: "Fastest", value: formattedTime(viewModel.bestLap?.durationSeconds), accent: .mint)
                metricCard(title: "Average", value: formattedTime(averageLapDuration), accent: .blue)
                metricCard(title: "Top Speed", value: formattedSpeed(viewModel.peakSpeedMPS), accent: .pink)
            }

            card {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Track Map")
                        .font(.headline)

                    Map(position: $summaryCameraPosition, interactionModes: [.zoom, .pan]) {
                        if !routePolyline.isEmpty {
                            MapPolyline(coordinates: routePolyline)
                                .stroke(.cyan, lineWidth: 4)
                        }

                        MapPolyline(coordinates: gatePolyline)
                            .stroke(.red, lineWidth: 4)
                    }
                    .mapStyle(.imagery(elevation: .realistic))
                    .frame(height: 220)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }
            }

            card {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Laps")
                        .font(.headline)

                    if viewModel.laps.isEmpty {
                        Text("No completed laps in this session.")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(viewModel.laps) { lap in
                            Button {
                                selectedLapNumber = lap.number
                            } label: {
                                HStack {
                                    Text("Lap \(lap.number)")
                                        .fontWeight(selectedLapNumber == lap.number ? .bold : .regular)
                                    Spacer()
                                    Text(formattedTime(lap.durationSeconds))
                                        .monospacedDigit()
                                    Text(String(format: "%.2f m/s", lap.speedAtCrossingMPS))
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                .padding(10)
                                .frame(maxWidth: .infinity)
                                .glassRoundedBackground(radius: 10)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }

            if let selectedLap {
                card {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Lap \(selectedLap.number) Telemetry")
                            .font(.headline)
                        Text("Longitudinal accel: \(String(format: "%.2f g", selectedLap.telemetry.maxLongitudinalAccel))")
                        Text("Lateral accel: \(String(format: "%.2f g", selectedLap.telemetry.maxLateralAccel))")
                        Text("Max yaw rate: \(String(format: "%.2f rad/s", selectedLap.telemetry.maxYawRate))")
                    }
                }
            }

            card {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Session Telemetry")
                        .font(.headline)
                    Text("Samples: \(viewModel.sampleCount)")
                    Text("Average speed: \(formattedSpeed(viewModel.averageSpeedMPS))")
                    Text("Peak acceleration: \(String(format: "%.2f g", viewModel.peakAccelerationG))")
                    Text("Peak deceleration: \(String(format: "%.2f g", viewModel.peakDecelerationG))")
                    Text("Peak yaw: \(String(format: "%.2f rad/s", viewModel.peakYawRate))")
                }
            }

            if let exportStatus = viewModel.exportStatus {
                Text(exportStatus)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            Button("Copy Session JSON") {
                viewModel.exportSessionJSON()
            }
            .buttonStyle(.borderedProminent)
            .tint(.orange)
            .controlSize(.large)

            HStack(spacing: 12) {
                Button("Save Session") {
                    // Placeholder until persistence is implemented.
                }
                .buttonStyle(.borderedProminent)
                .tint(.blue)

                Button("Discard Data") {
                    viewModel.discardAndReturnToSetup()
                }
                .buttonStyle(.bordered)
                .tint(.red)
            }
        }
    }

    private var selectedLap: RecordedLap? {
        guard let selectedLapNumber else { return viewModel.latestLap }
        return viewModel.laps.first(where: { $0.number == selectedLapNumber })
    }

    private var averageLapDuration: TimeInterval? {
        guard !viewModel.laps.isEmpty else { return nil }
        let sum = viewModel.laps.reduce(0) { $0 + $1.durationSeconds }
        return sum / Double(viewModel.laps.count)
    }

    private func metricCard(title: String, value: String, accent: Color) -> some View {
        card {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(title)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Circle()
                        .fill(accent)
                        .frame(width: 8, height: 8)
                }

                Text(value)
                    .font(.headline.monospacedDigit())
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func metricButtonCard(
        title: String,
        value: String,
        accent: Color,
        isActive: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(title)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Circle()
                        .fill(accent)
                        .frame(width: 8, height: 8)
                }

                Text(value)
                    .font(.headline.monospacedDigit())
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(14)
            .glassCard(radius: 16)
            .overlay {
                if isActive {
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.red.opacity(0.6), lineWidth: 1.5)
                }
            }
        }
        .buttonStyle(.plain)
    }

    private func card<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        content()
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .glassCard(radius: 16)
    }

    private func formattedTime(_ duration: TimeInterval?) -> String {
        guard let duration else { return "--" }
        return String(format: "%.3fs", duration)
    }

    private func formattedDelta(_ delta: TimeInterval?) -> String {
        guard let delta else { return "--" }
        return String(format: "%+.3fs", delta)
    }

    private func formattedSpeed(_ speed: Double) -> String {
        String(format: "%.2f m/s", speed)
    }

    private func mapRegion(for gate: StartFinishGate) -> MKCoordinateRegion {
        MKCoordinateRegion(
            center: gate.center.clCoordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.003, longitudeDelta: 0.003)
        )
    }

    private func updateOrientation(for phase: LiveTimingViewModel.SessionPhase) {
        switch phase {
        case .live:
            requestOrientation(.landscape)
        case .setup, .summary:
            requestOrientation(.portrait)
        }
    }

    private func requestOrientation(_ mask: UIInterfaceOrientationMask) {
#if canImport(UIKit)
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene else { return }
        let preferences = UIWindowScene.GeometryPreferences.iOS(interfaceOrientations: mask)
        try? windowScene.requestGeometryUpdate(preferences)
#endif
    }
}

#Preview {
    LiveTimingView()
}
