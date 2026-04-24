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
    @State private var debugPreviewHeat: Heat?

    private var gatePolyline: [CLLocationCoordinate2D] {
        [viewModel.currentGate.pointA.clCoordinate, viewModel.currentGate.pointB.clCoordinate]
    }

    private var gateDirectionArrowShaft: [CLLocationCoordinate2D] {
        let gate = viewModel.currentGate
        let center = gate.center
        let forward = gate.expectedForward.normalized()

        let start = Geometry.localPointToCoordinate(
            origin: center,
            point: forward * 2
        )
        let tip = Geometry.localPointToCoordinate(
            origin: center,
            point: forward * 26
        )
        return [start.clCoordinate, tip.clCoordinate]
    }

    private var gateDirectionArrowHead: [CLLocationCoordinate2D] {
        let gate = viewModel.currentGate
        let center = gate.center
        let forward = gate.expectedForward.normalized()
        let tipPoint = forward * 26
        let wingBack = forward * -9
        let perpendicular = Vector2D(x: -forward.y, y: forward.x).normalized()

        let leftWing = tipPoint + wingBack + (perpendicular * 6)
        let rightWing = tipPoint + wingBack + (perpendicular * -6)

        let tip = Geometry.localPointToCoordinate(origin: center, point: tipPoint)
        let left = Geometry.localPointToCoordinate(origin: center, point: leftWing)
        let right = Geometry.localPointToCoordinate(origin: center, point: rightWing)

        return [left.clCoordinate, tip.clCoordinate, right.clCoordinate]
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
            .sheet(item: $debugPreviewHeat) { heat in
                NavigationStack {
                    HeatView(heat: heat)
                        .navigationTitle("Imported Heat")
                        .navigationBarTitleDisplayMode(.inline)
                }
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

                    Picker("Kart", selection: $viewModel.selectedKart) {
                        ForEach(viewModel.selectedTrack.availableKarts, id: \.self) { kart in
                            Text(kart.rawValue).tag(kart)
                        }
                    }
                    .pickerStyle(.menu)

                    Picker("Session Type", selection: $viewModel.sessionType) {
                        ForEach(HeatType.allCases, id: \.self) { type in
                            Text(type.label).tag(type)
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
                        MapPolyline(coordinates: gateDirectionArrowShaft)
                            .stroke(.yellow, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                        MapPolyline(coordinates: gateDirectionArrowHead)
                            .stroke(.yellow, style: StrokeStyle(lineWidth: 4, lineCap: .round, lineJoin: .round))

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
            
            debugImportCard
        }
    }

    private var livePanel: some View {
        VStack(spacing: 14) {
            VStack(spacing: 10) {
                HStack(spacing: 8) {
                    ForEach(0..<12, id: \.self) { index in
                        Circle()
                            .fill(liveDashLightColor(at: index))
                            .frame(width: 11, height: 11)
                    }
                }
                .padding(.top, 4)

                HStack(spacing: 10) {
                    liveDashPill(title: "Type", value: viewModel.sessionType.label)
                    liveDashPill(title: "Track", value: viewModel.selectedTrack.rawValue)
                    liveDashPill(title: "Laps", value: "\(viewModel.laps.count)")
                }

                HStack(alignment: .center, spacing: 12) {
                    VStack(spacing: 8) {
                        liveDashSideMetric(
                            title: "DELTA",
                            value: formattedDelta(viewModel.currentLapDeltaToBest),
                            accent: (viewModel.currentLapDeltaToBest ?? 0) <= 0 ? .green : .red
                        )
                        liveDashSideMetric(
                            title: "BEST",
                            value: formattedTime(viewModel.bestLap?.durationSeconds),
                            accent: .mint
                        )
                    }

                    VStack(spacing: 6) {
                        Text("\(currentLiveLapNumber)")
                            .font(.system(size: 72, weight: .bold, design: .rounded))
                            .monospacedDigit()
                            .foregroundStyle(.white)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)

                        Text("CURRENT LAP")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(.secondary)

                        Text(formattedTime(viewModel.currentLapElapsed))
                            .font(.title2.weight(.semibold).monospacedDigit())
                            .foregroundStyle(.white)
                    }
                    .frame(maxWidth: .infinity)

                    VStack(spacing: 8) {
                        liveDashSideMetric(
                            title: "SPEED",
                            value: formattedSpeed(viewModel.latestSample?.speedMPS ?? 0),
                            accent: .yellow
                        )
                        liveDashSideMetric(
                            title: "SESSION",
                            value: formattedTime(viewModel.sessionElapsed),
                            accent: .orange
                        )
                    }
                }

                HStack(spacing: 10) {
                    liveDashPill(title: "AVG", value: formattedSpeed(viewModel.averageSpeedMPS))
                    liveDashPill(title: "PEAK", value: formattedSpeed(viewModel.peakSpeedMPS))
                    liveDashPill(title: "YAW", value: String(format: "%.2f", viewModel.peakYawRate))
                }
            }
            .padding(14)
            .frame(maxWidth: .infinity)
            .background(
                LinearGradient(
                    colors: [Color.black.opacity(0.82), Color.black.opacity(0.56)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(Color.white.opacity(0.14), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 18))

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

            metricButtonCard(
                title: "Laps",
                value: "\(viewModel.laps.count) completed",
                accent: .blue,
                isActive: showLiveLaps
            ) {
                showLiveLaps.toggle()
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
                    Text("Session Laps")
                        .font(.headline)

                    if viewModel.laps.isEmpty {
                        Text("No completed laps in this session.")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(viewModel.laps) { lap in
                            Button {
                                selectedLapNumber = lap.number
                            } label: {
                                HStack(spacing: 10) {
                                    Text("L\(lap.number)")
                                        .font(.caption.bold())
                                        .foregroundStyle(.secondary)
                                        .frame(width: 30, alignment: .leading)

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(formattedTime(lap.durationSeconds))
                                            .fontWeight(selectedLapNumber == lap.number ? .bold : .regular)
                                            .monospacedDigit()
                                        Text(String(format: "Cross %.2f m/s", lap.speedAtCrossingMPS))
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }

                                    Spacer()
                                    Text(String(format: "%.2f g", lap.telemetry.maxLateralAccel))
                                        .font(.caption.monospacedDigit())
                                        .foregroundStyle(.secondary)
                                }
                                .padding(10)
                                .frame(maxWidth: .infinity)
                                .glassRoundedBackground(radius: 10)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(
                                            selectedLapNumber == lap.number ? Color.red.opacity(0.65) : .clear,
                                            lineWidth: 1.4
                                        )
                                )
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
                        Text("Avg speed: \(String(format: "%.2f m/s", selectedLap.telemetry.averageSpeedMPS))")
                        Text("Peak speed: \(String(format: "%.2f m/s", selectedLap.telemetry.peakSpeedMPS))")
                        Text("Distance: \(String(format: "%.1f m", selectedLap.telemetry.distanceMeters))")
                        Text("Samples: \(selectedLap.telemetry.sampleCount)")
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
                    Text("Distance: \(String(format: "%.1f m", viewModel.totalDistanceMeters))")
                }
            }

            if let preview = viewModel.preparedHeatForSaving {
                card {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Savable Session Preview")
                            .font(.headline)
                        Text("Type: \(preview.type.label)")
                        Text("Identifier: \(preview.identifier)")
                        Text("Track/Kart: \(preview.track.rawValue) • \(preview.kart.rawValue)")
                        Text("Laps prepared: \(preview.lapCount)")
                        if let metadata = preview.sessionMetadata {
                            Text("Gate crossings: \(metadata.gateCrossingsCount)")
                            Text("Duration: \(formattedTime(metadata.durationSeconds))")
                        }
                    }
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

            debugImportCard
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

    private var currentLiveLapNumber: Int {
        (viewModel.latestLap?.number ?? 0) + 1
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

    private func liveDashPill(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)
            Text(value)
                .font(.caption.weight(.semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 9))
    }

    private func liveDashSideMetric(title: String, value: String, accent: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)
            Text(value)
                .font(.headline.monospacedDigit())
                .foregroundStyle(accent)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 10))
    }

    private func liveDashLightColor(at index: Int) -> Color {
        let speed = viewModel.latestSample?.speedMPS ?? 0
        let ratio = min(max(speed / 22.0, 0), 1)
        let litCount = Int(round(ratio * 12))
        guard index < litCount else { return Color.white.opacity(0.3) }

        if index < 5 {
            return .green
        } else if index < 9 {
            return .yellow
        } else {
            return .red
        }
    }

    private func card<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        content()
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .glassCard(radius: 16)
    }

    private var debugImportCard: some View {
        card {
            VStack(alignment: .leading, spacing: 10) {
                Text("Debug JSON Import")
                    .font(.headline)

                Text("Load `gokarting/data.json` and generate a Heat preview without saving.")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                HStack(spacing: 10) {
                    Button("Load Sample Session (data.json)") {
                        viewModel.importDebugSampleSessionFromFile()
                        if let imported = viewModel.debugImportedHeat {
                            debugPreviewHeat = imported
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.blue)

                    Button("Clear") {
                        viewModel.clearDebugImport()
                    }
                    .buttonStyle(.bordered)
                }

                if let status = viewModel.debugImportStatus {
                    Text(status)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                if let imported = viewModel.debugImportedHeat {
                    HStack {
                        Text("\(imported.type.label) • \(imported.identifier)")
                            .font(.caption.weight(.semibold))
                            .lineLimit(1)

                        Spacer()

                        Button("Open Preview") {
                            debugPreviewHeat = imported
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    }
                }
            }
        }
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
