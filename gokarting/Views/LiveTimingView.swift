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
    @State private var debugPreviewHeat: Heat?
    @State private var showDebugImportPicker = false
    private let preferredTrack: Track = .p1ShortConfig

    private var orderedTracks: [Track] {
        var tracks = Track.allCases
        if let index = tracks.firstIndex(of: preferredTrack) {
            tracks.remove(at: index)
            tracks.insert(preferredTrack, at: 0)
        }
        return tracks
    }

    private var gatePolyline: [CLLocationCoordinate2D] {
        [viewModel.currentGate.pointA.clCoordinate, viewModel.currentGate.pointB.clCoordinate]
    }

    private var trackLayoutPolyline: [CLLocationCoordinate2D] {
        viewModel.selectedTrack.layout?.centerline.map(\.clCoordinate) ?? []
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
            VStack(spacing: viewModel.phase == .live ? 0 : 20) {
                phaseContent
            }
            .padding(.horizontal, viewModel.phase == .live ? 0 : 20)
            .padding(.top, viewModel.phase == .live ? 0 : 12)
            .padding(.bottom, viewModel.phase == .live ? 0 : 24)
            .appScreenBackground()
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(viewModel.phase == .live ? .hidden : .visible, for: .tabBar)
            .toolbar(.hidden, for: .navigationBar)
            .onAppear {
                viewModel.requestPermissions()
                setupCameraPosition = .region(mapRegion(for: viewModel.selectedTrack, gate: viewModel.currentGate))
                summaryCameraPosition = .region(mapRegion(for: viewModel.selectedTrack, gate: viewModel.currentGate))
                UIDevice.current.beginGeneratingDeviceOrientationNotifications()
                syncPhoneMountOrientationFromDevice()
                updateOrientation(for: viewModel.phase)
            }
            .onChange(of: viewModel.selectedTrack) { _, _ in
                setupCameraPosition = .region(mapRegion(for: viewModel.selectedTrack, gate: viewModel.currentGate))
                if viewModel.phase == .summary {
                    summaryCameraPosition = .region(mapRegion(for: viewModel.selectedTrack, gate: viewModel.currentGate))
                }
            }
            .onChange(of: viewModel.phase) { _, newPhase in
                if newPhase == .live || newPhase == .summary {
                    summaryCameraPosition = .region(mapRegion(for: viewModel.selectedTrack, gate: viewModel.currentGate))
                }
                syncPhoneMountOrientationFromDevice()
                updateOrientation(for: newPhase)
            }
            .onChange(of: viewModel.phoneMountOrientation) { _, _ in
                if viewModel.phase == .live {
                    updateOrientation(for: .live)
                }
            }
            .onChange(of: viewModel.latestLap?.number) { _, newNumber in
                if let newNumber {
                    selectedLapNumber = newNumber
                }
            }
            .onDisappear {
                UIDevice.current.endGeneratingDeviceOrientationNotifications()
                requestOrientation(.portrait)
            }
            .onReceive(NotificationCenter.default.publisher(for: UIDevice.orientationDidChangeNotification)) { _ in
                syncPhoneMountOrientationFromDevice()
            }
            .sheet(item: $debugPreviewHeat) { heat in
                NavigationStack {
                    HeatView(heat: heat)
                        .navigationTitle("Imported Heat")
                        .navigationBarTitleDisplayMode(.inline)
                }
            }
            .confirmationDialog(
                "Select Debug JSON",
                isPresented: $showDebugImportPicker,
                titleVisibility: .visible
            ) {
                Button("data.json") {
                    viewModel.importDebugSampleSessionFromFile(named: "data.json")
                    if let imported = viewModel.debugImportedHeat {
                        debugPreviewHeat = imported
                    }
                }
                Button("data2.json") {
                    viewModel.importDebugSampleSessionFromFile(named: "data2.json")
                    if let imported = viewModel.debugImportedHeat {
                        debugPreviewHeat = imported
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Choose which sample file to import.")
            }
        }
    }

    private var phaseContent: some View {
        Group {
            if viewModel.phase == .summary, let completedHeat = viewModel.preparedHeatForSaving {
                HeatView(heat: completedHeat)
            } else if viewModel.phase == .live {
                VStack(spacing: 10) {
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
                    .padding(.horizontal, 12)
                    .padding(.top, 8)

                    livePanel
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            } else {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Session")
                                .font(.system(.largeTitle, design: .rounded, weight: .bold))
                                .foregroundStyle(.white)
                            Text("Configure, run, and review your live timing session.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)

                        if viewModel.phase == .setup {
                            setupPanel
                        }

                        if viewModel.phase == .summary {
                            summaryPanel
                        }
                    }
                    .padding(.bottom, 10)
                }
            }
        }
    }

    private var setupPanel: some View {
        VStack(spacing: 20) {
            VStack(spacing: 14) {
                HStack(spacing: 10) {
                    ForEach(HeatType.allCases, id: \.self) { type in
                        Button {
                            viewModel.sessionType = type
                        } label: {
                            Text(type.label)
                                .font(.subheadline.weight(.semibold))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .foregroundStyle(viewModel.sessionType == type ? Color.white : Color.primary)
                        }
                        .buttonStyle(.plain)
                        .glassCapsuleBackground(accented: viewModel.sessionType == type)
                    }
                }

                Menu {
                    Picker("Track", selection: $viewModel.selectedTrack) {
                        ForEach(orderedTracks, id: \.self) { track in
                            Text(track.rawValue).tag(track)
                        }
                    }
                } label: {
                    Label(viewModel.selectedTrack.rawValue, systemImage: "map")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.blue)
                        .lineLimit(1)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .glassCapsuleBackground(accented: false)
                }

                Menu {
                    Picker("Kart", selection: $viewModel.selectedKart) {
                        ForEach(viewModel.selectedTrack.availableKarts, id: \.self) { kart in
                            Text(kart.rawValue).tag(kart)
                        }
                    }
                } label: {
                    Label(viewModel.selectedKart.rawValue, systemImage: "steeringwheel")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.blue)
                        .lineLimit(1)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .glassCapsuleBackground(accented: false)
                }

                Menu {
                    Picker("Phone Mount", selection: $viewModel.phoneMountOrientation) {
                        ForEach(PhoneMountOrientation.allCases, id: \.self) { orientation in
                            Text(orientation.rawValue).tag(orientation)
                        }
                    }
                } label: {
                    Label(viewModel.phoneMountOrientation.rawValue, systemImage: "iphone")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.blue)
                        .lineLimit(1)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .glassCapsuleBackground(accented: false)
                }
            }

            card {
                VStack(alignment: .leading, spacing: 14) {
                    Text("Start / Finish Gate")
                        .font(.title3.weight(.semibold))

                    Map(position: $setupCameraPosition, interactionModes: [.zoom, .pan]) {
                        if !trackLayoutPolyline.isEmpty {
                            MapPolyline(coordinates: trackLayoutPolyline)
                                .stroke(.blue, lineWidth: 4)
                        }
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
                    .clipShape(RoundedRectangle(cornerRadius: 20))
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
        VStack(spacing: 10) {
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
                        .font(.system(size: 96, weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)

                    Text("CURRENT LAP")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.secondary)

                    Text(formattedTime(viewModel.currentLapElapsed))
                        .font(.system(size: 56, weight: .bold, design: .rounded).monospacedDigit())
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.65)
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

            Spacer(minLength: 0)

            HStack(spacing: 10) {
                liveDashPill(title: "AVG", value: formattedSpeed(viewModel.averageSpeedMPS))
                liveDashPill(title: "PEAK", value: formattedSpeed(viewModel.peakSpeedMPS))
            }
        }
        .padding(.horizontal, 14)
        .padding(.top, 14)
        .padding(.bottom, 22)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(
            LinearGradient(
                colors: [Color.black.opacity(0.82), Color.black.opacity(0.56)],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .overlay(
            Rectangle()
                .stroke(Color.white.opacity(0.14), lineWidth: 1)
        )
    }

    private var summaryPanel: some View {
        VStack(spacing: 20) {
            HStack(spacing: 10) {
                metricCard(title: "Fastest", value: formattedTime(viewModel.bestLap?.durationSeconds), accent: .mint)
                metricCard(title: "Average", value: formattedTime(averageLapDuration), accent: .blue)
                metricCard(title: "Top Speed", value: formattedSpeed(viewModel.peakSpeedMPS), accent: .pink)
            }

            card {
                VStack(alignment: .leading, spacing: 14) {
                    Text("Track Map")
                        .font(.title3.weight(.semibold))

                    Map(position: $summaryCameraPosition, interactionModes: [.zoom, .pan]) {
                        if !trackLayoutPolyline.isEmpty {
                            MapPolyline(coordinates: trackLayoutPolyline)
                                .stroke(.white.opacity(0.9), lineWidth: 3)
                        }

                        if !routePolyline.isEmpty {
                            MapPolyline(coordinates: routePolyline)
                                .stroke(.blue, lineWidth: 4)
                        }

                        MapPolyline(coordinates: gatePolyline)
                            .stroke(.red, lineWidth: 4)
                    }
                    .mapStyle(.imagery(elevation: .realistic))
                    .frame(height: 220)
                    .clipShape(RoundedRectangle(cornerRadius: 20))

                    if trackLayoutPolyline.isEmpty {
                        Text("This track currently uses gate-only mode (no saved layout yet).")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            card {
                VStack(alignment: .leading, spacing: 14) {
                    Text("Session Laps")
                        .font(.title3.weight(.semibold))

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
                                .padding(.horizontal, 14)
                                .padding(.vertical, 12)
                                .frame(maxWidth: .infinity)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(Color.white.opacity(0.05))
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
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
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Lap \(selectedLap.number) Telemetry")
                            .font(.title3.weight(.semibold))
                        summaryStatRow("Longitudinal accel", String(format: "%.2f g", selectedLap.telemetry.maxLongitudinalAccel))
                        summaryStatRow("Lateral accel", String(format: "%.2f g", selectedLap.telemetry.maxLateralAccel))
                        summaryStatRow("Max yaw rate", String(format: "%.2f rad/s", selectedLap.telemetry.maxYawRate))
                        summaryStatRow("Avg speed", String(format: "%.2f m/s", selectedLap.telemetry.averageSpeedMPS))
                        summaryStatRow("Peak speed", String(format: "%.2f m/s", selectedLap.telemetry.peakSpeedMPS))
                        summaryStatRow("Distance", String(format: "%.1f m", selectedLap.telemetry.distanceMeters))
                        summaryStatRow("Samples", "\(selectedLap.telemetry.sampleCount)")
                    }
                }
            }

            card {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Session Telemetry")
                        .font(.title3.weight(.semibold))
                    summaryStatRow("Samples", "\(viewModel.sampleCount)")
                    summaryStatRow("Average speed", formattedSpeed(viewModel.averageSpeedMPS))
                    summaryStatRow("Peak acceleration", String(format: "%.2f g", viewModel.peakAccelerationG))
                    summaryStatRow("Peak deceleration", String(format: "%.2f g", viewModel.peakDecelerationG))
                    summaryStatRow("Peak yaw", String(format: "%.2f rad/s", viewModel.peakYawRate))
                    summaryStatRow("Distance", String(format: "%.1f m", viewModel.totalDistanceMeters))
                }
            }

            if let preview = viewModel.preparedHeatForSaving {
                card {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Savable Session Preview")
                            .font(.title3.weight(.semibold))
                        summaryStatRow("Type", preview.type.label)
                        summaryStatRow("Identifier", preview.identifier)
                        summaryStatRow("Track/Kart", "\(preview.track.rawValue) • \(preview.kart.rawValue)")
                        summaryStatRow("Laps prepared", "\(preview.lapCount)")
                        if let metadata = preview.sessionMetadata {
                            summaryStatRow("Gate crossings", "\(metadata.gateCrossingsCount)")
                            summaryStatRow("Duration", formattedTime(metadata.durationSeconds))
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
                    .font(.title3.weight(.semibold).monospacedDigit())
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func liveDashPill(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
            Text(value)
                .font(.title2.weight(.semibold).monospacedDigit())
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
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
            Text(value)
                .font(.title2.weight(.semibold).monospacedDigit())
                .foregroundStyle(accent)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 10))
    }

    private func card<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        content()
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .glassCard(radius: 30)
    }

    private func summaryStatRow(_ title: String, _ value: String) -> some View {
        HStack(alignment: .top) {
            Text(title)
                .foregroundStyle(.secondary)
                .font(.subheadline)
            Spacer(minLength: 16)
            Text(value)
                .multilineTextAlignment(.trailing)
                .foregroundStyle(.white)
                .font(.subheadline.weight(.semibold))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
        )
    }

    private var debugImportCard: some View {
        card {
            VStack(alignment: .leading, spacing: 10) {
                Text("Debug JSON Import")
                    .font(.headline)

                Text("Load `gokarting/data.json` or `gokarting/data2.json` and generate a Heat preview without saving.")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                HStack(spacing: 10) {
                    Button("Load Sample Session (data.json/data2.json)") {
                        showDebugImportPicker = true
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

    private func mapRegion(for track: Track, gate: StartFinishGate) -> MKCoordinateRegion {
        if let layout = track.layout, !layout.centerline.isEmpty {
            return regionFitting(layout.centerline.map(\.clCoordinate))
        }
        
        return MKCoordinateRegion(
            center: gate.center.clCoordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.003, longitudeDelta: 0.003)
        )
    }

    private func regionFitting(_ coordinates: [CLLocationCoordinate2D]) -> MKCoordinateRegion {
        guard let first = coordinates.first else {
            return MKCoordinateRegion(
                center: viewModel.currentGate.center.clCoordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.003, longitudeDelta: 0.003)
            )
        }

        var minLat = first.latitude
        var maxLat = first.latitude
        var minLon = first.longitude
        var maxLon = first.longitude

        for coordinate in coordinates.dropFirst() {
            minLat = min(minLat, coordinate.latitude)
            maxLat = max(maxLat, coordinate.latitude)
            minLon = min(minLon, coordinate.longitude)
            maxLon = max(maxLon, coordinate.longitude)
        }

        let center = CLLocationCoordinate2D(
            latitude: (minLat + maxLat) / 2.0,
            longitude: (minLon + maxLon) / 2.0
        )
        let span = MKCoordinateSpan(
            latitudeDelta: max((maxLat - minLat) * 1.25, 0.0008),
            longitudeDelta: max((maxLon - minLon) * 1.25, 0.0008)
        )

        return MKCoordinateRegion(
            center: center,
            span: span
        )
    }

    private func updateOrientation(for phase: LiveTimingViewModel.SessionPhase) {
        switch phase {
        case .live:
            switch viewModel.phoneMountOrientation {
            case .landscapeLeft:
                requestOrientation(.landscapeLeft)
            case .landscapeRight:
                requestOrientation(.landscapeRight)
            case .portrait:
                requestOrientation(.portrait)
            }
        case .setup, .summary:
            requestOrientation(.portrait)
        }
    }

    private func syncPhoneMountOrientationFromDevice() {
#if canImport(UIKit)
        let interfaceOrientation = (UIApplication.shared.connectedScenes.first as? UIWindowScene)?.interfaceOrientation
        if let orientation = phoneMountOrientation(from: interfaceOrientation) {
            viewModel.setPhoneMountOrientation(orientation)
            return
        }

        if let orientation = phoneMountOrientation(from: UIDevice.current.orientation) {
            viewModel.setPhoneMountOrientation(orientation)
        }
#endif
    }

    private func phoneMountOrientation(from interfaceOrientation: UIInterfaceOrientation?) -> PhoneMountOrientation? {
        guard let interfaceOrientation else { return nil }
        switch interfaceOrientation {
        case .landscapeLeft:
            return .landscapeLeft
        case .landscapeRight:
            return .landscapeRight
        case .portrait, .portraitUpsideDown:
            return .portrait
        default:
            return nil
        }
    }

    private func phoneMountOrientation(from deviceOrientation: UIDeviceOrientation) -> PhoneMountOrientation? {
        switch deviceOrientation {
        case .landscapeLeft:
            return .landscapeLeft
        case .landscapeRight:
            return .landscapeRight
        case .portrait, .portraitUpsideDown:
            return .portrait
        default:
            return nil
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
