import SwiftUI
import MapKit
#if canImport(UIKit)
import UIKit
#endif

struct TracksView: View {
    @State private var selectedTrack: Track = .p1ShortConfig
    @State private var cameraPosition: MapCameraPosition = .automatic
    @State private var draftPoints: [DraftCenterlinePoint] = []
    @State private var draftTrackWidthMeters: Double = 7.0
    @State private var draftMode: DraftMode = .editSavedLayout
    @State private var copyStatus: String?
    private let preferredTrack: Track = .p1ShortConfig

    private var orderedTracks: [Track] {
        var tracks = Track.allCases
        if let index = tracks.firstIndex(of: preferredTrack) {
            tracks.remove(at: index)
            tracks.insert(preferredTrack, at: 0)
        }
        return tracks
    }

    private var gate: StartFinishGate {
        let gatePoints = selectedTrack.gatePoints
        let center = GeoCoordinate(
            latitude: (gatePoints.pointA.latitude + gatePoints.pointB.latitude) / 2.0,
            longitude: (gatePoints.pointA.longitude + gatePoints.pointB.longitude) / 2.0
        )
        let a = Geometry.coordinateToLocalPoint(origin: center, coordinate: gatePoints.pointA)
        let b = Geometry.coordinateToLocalPoint(origin: center, coordinate: gatePoints.pointB)
        let gateVector = (b - a).normalized()
        let normal = Vector2D(x: -gateVector.y, y: gateVector.x).normalized()
        let expectedForward = selectedTrack.defaultRaceDirection == .clockwise ? normal : (normal * -1)
        return StartFinishGate(pointA: gatePoints.pointA, pointB: gatePoints.pointB, expectedForward: expectedForward)
    }

    private var gatePolyline: [CLLocationCoordinate2D] {
        [gate.pointA.clCoordinate, gate.pointB.clCoordinate]
    }

    private var layoutPolyline: [CLLocationCoordinate2D] {
        selectedTrack.layout?.centerline.map(\.clCoordinate) ?? []
    }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 14) {
                    card {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Track")
                                .font(.headline)

                            Picker("Track", selection: $selectedTrack) {
                                ForEach(orderedTracks, id: \.self) { track in
                                    Text(track.rawValue).tag(track)
                                }
                            }
                            .pickerStyle(.menu)
                        }
                    }

                    card {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Map")
                                .font(.headline)

                            MapReader { proxy in
                                Map(position: $cameraPosition, interactionModes: [.zoom, .pan]) {
                                    if !layoutPolyline.isEmpty {
                                        MapPolyline(coordinates: layoutPolyline)
                                            .stroke(.cyan, lineWidth: 4)
                                    }

                                    let draftCenterline = draftPoints.map {
                                        CLLocationCoordinate2D(latitude: $0.latitude, longitude: $0.longitude)
                                    }
                                    if draftCenterline.count >= 2 {
                                        MapPolyline(coordinates: draftCenterline)
                                            .stroke(.yellow, style: StrokeStyle(lineWidth: 3, dash: [6, 4]))
                                    }

                                    MapPolyline(coordinates: gatePolyline)
                                        .stroke(.red, lineWidth: 5)

                                    Marker("A", coordinate: gate.pointA.clCoordinate).tint(.red)
                                    Marker("B", coordinate: gate.pointB.clCoordinate).tint(.red)

                                    ForEach(draftPoints) { point in
                                        Annotation("#\(point.order)", coordinate: CLLocationCoordinate2D(latitude: point.latitude, longitude: point.longitude)) {
                                            Text("#\(point.order)")
                                                .font(.caption2.weight(.bold))
                                                .padding(.horizontal, 6)
                                                .padding(.vertical, 3)
                                                .background(.thinMaterial, in: Capsule())
                                        }
                                    }
                                }
                                .gesture(
                                    SpatialTapGesture()
                                        .onEnded { value in
                                            guard let coord = proxy.convert(value.location, from: .local) else { return }
                                            draftPoints.append(
                                                DraftCenterlinePoint(
                                                    order: draftPoints.count + 1,
                                                    latitude: coord.latitude,
                                                    longitude: coord.longitude
                                                )
                                            )
                                        }
                                )
                            }
                            .mapStyle(.imagery(elevation: .realistic))
                            .mapControls {
                                MapUserLocationButton()
                            }
                            .frame(height: 420)
                            .clipShape(RoundedRectangle(cornerRadius: 14))

                            Text(layoutPolyline.isEmpty ? "Gate-only track (no saved layout)." : "Layout loaded (\(layoutPolyline.count) points).")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }

                    card {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Layout Draft Helper")
                                .font(.headline)

                            Picker("Draft Mode", selection: $draftMode) {
                                ForEach(DraftMode.allCases, id: \.self) { mode in
                                    Text(mode.rawValue).tag(mode)
                                }
                            }
                            .pickerStyle(.segmented)

                            HStack(spacing: 10) {
                                Button("Load Mode") {
                                    applyDraftMode()
                                }
                                .buttonStyle(.borderedProminent)

                                Button("Clear Draft") {
                                    draftPoints.removeAll()
                                    copyStatus = nil
                                }
                                .buttonStyle(.bordered)
                            }

                            HStack {
                                Text("Track Width")
                                Spacer()
                                TextField("Width", value: $draftTrackWidthMeters, format: .number.precision(.fractionLength(1)))
                                    .keyboardType(.decimalPad)
                                    .multilineTextAlignment(.trailing)
                                    .frame(width: 90)
                                Text("m")
                                    .foregroundStyle(.secondary)
                            }
                            .font(.subheadline)

                            HStack(spacing: 10) {
                                Button("Use Gate Center") {
                                    draftPoints.append(
                                        DraftCenterlinePoint(
                                            order: draftPoints.count + 1,
                                            latitude: gate.center.latitude,
                                            longitude: gate.center.longitude
                                        )
                                    )
                                }
                                .buttonStyle(.bordered)

                                Button("Undo Last") {
                                    guard !draftPoints.isEmpty else { return }
                                    draftPoints.removeLast()
                                    reindexDraftPoints()
                                }
                                .buttonStyle(.bordered)

                                Button("Clear") {
                                    draftPoints.removeAll()
                                    copyStatus = nil
                                }
                                .buttonStyle(.bordered)
                            }

                            Button("Copy Draft JSON") {
                                let json = draftJSON()
                                copyToClipboard(json)
                                copyStatus = "Draft JSON copied to clipboard."
                            }
                            .buttonStyle(.borderedProminent)

                            if let copyStatus {
                                Text(copyStatus)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            if draftPoints.isEmpty {
                                Text("Tap on map to add centerline points in driving order.")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            } else {
                                ForEach(draftPoints) { point in
                                    HStack {
                                        Text("#\(point.order)")
                                        Spacer()
                                        Text(String(format: "%.5f, %.5f", point.latitude, point.longitude))
                                            .font(.caption.monospacedDigit())
                                            .foregroundStyle(.secondary)
                                    }
                                    .font(.subheadline)
                                }
                            }
                        }
                    }

                    card {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Info")
                                .font(.headline)
                            statRow("Default Direction", selectedTrack.defaultRaceDirection.rawValue)
                            statRow("Supported Directions", selectedTrack.supportedRaceDirections.map(\.rawValue).joined(separator: ", "))
                            statRow("Available Karts", selectedTrack.availableKarts.map(\.rawValue).joined(separator: ", "))
                            statRow("Layout Points", "\(layoutPolyline.count)")
                            statRow("Gate A", coordinateText(selectedTrack.gatePoints.pointA))
                            statRow("Gate B", coordinateText(selectedTrack.gatePoints.pointB))
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 12)
            }
            .appScreenBackground()
            .navigationTitle("Tracks")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                cameraPosition = .region(mapRegion(for: selectedTrack))
                applyDraftMode()
            }
            .onChange(of: selectedTrack) { _, newTrack in
                cameraPosition = .region(mapRegion(for: newTrack))
                applyDraftMode()
            }
        }
    }

    private func card<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            content()
        }
        .padding(14)
        .glassCard(radius: 18)
    }

    private func statRow(_ title: String, _ value: String) -> some View {
        HStack(alignment: .top) {
            Text(title)
                .foregroundStyle(.secondary)
            Spacer(minLength: 16)
            Text(value)
                .multilineTextAlignment(.trailing)
        }
        .font(.subheadline)
    }

    private func coordinateText(_ point: GeoCoordinate) -> String {
        String(format: "%.6f, %.6f", point.latitude, point.longitude)
    }

    private func reindexDraftPoints() {
        draftPoints = draftPoints.enumerated().map { index, point in
            DraftCenterlinePoint(
                id: point.id,
                order: index + 1,
                latitude: point.latitude,
                longitude: point.longitude
            )
        }
    }

    private func draftJSON() -> String {
        let payload = TrackLayoutDraftExport(
            exportedAt: Date(),
            track: selectedTrack.rawValue,
            trackWidthMeters: draftTrackWidthMeters,
            gate: GateDraftExport(
                pointA: CoordinateDraft(latitude: gate.pointA.latitude, longitude: gate.pointA.longitude),
                pointB: CoordinateDraft(latitude: gate.pointB.latitude, longitude: gate.pointB.longitude),
                center: CoordinateDraft(latitude: gate.center.latitude, longitude: gate.center.longitude)
            ),
            points: draftPoints.map {
                CenterlinePointExport(
                    order: $0.order,
                    latitude: $0.latitude,
                    longitude: $0.longitude
                )
            }
        )

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        encoder.dateEncodingStrategy = .iso8601
        guard let data = try? encoder.encode(payload),
              let json = String(data: data, encoding: .utf8) else {
            return "{ \"error\": \"Unable to encode draft.\" }"
        }
        return json
    }

    private func applyDraftMode() {
        switch draftMode {
        case .editSavedLayout:
            let savedPoints = selectedTrack.layout?.centerline ?? []
            draftPoints = savedPoints.enumerated().map { index, point in
                DraftCenterlinePoint(
                    order: index + 1,
                    latitude: point.latitude,
                    longitude: point.longitude
                )
            }
            if let width = selectedTrack.layout?.trackWidthMeters {
                draftTrackWidthMeters = width
            }
            copyStatus = savedPoints.isEmpty ? "No saved layout for this track. Draft is empty." : "Loaded saved layout into draft."
        case .newLine:
            draftPoints.removeAll()
            copyStatus = "Started a new empty draft."
        }
    }

    private func copyToClipboard(_ text: String) {
#if canImport(UIKit)
        UIPasteboard.general.string = text
#endif
    }

    private func mapRegion(for track: Track) -> MKCoordinateRegion {
        if let layout = track.layout, !layout.centerline.isEmpty {
            return regionFitting(layout.centerline.map(\.clCoordinate))
        }

        let gatePoints = track.gatePoints
        let center = GeoCoordinate(
            latitude: (gatePoints.pointA.latitude + gatePoints.pointB.latitude) / 2.0,
            longitude: (gatePoints.pointA.longitude + gatePoints.pointB.longitude) / 2.0
        )
        return MKCoordinateRegion(
            center: center.clCoordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.003, longitudeDelta: 0.003)
        )
    }

    private func regionFitting(_ coordinates: [CLLocationCoordinate2D]) -> MKCoordinateRegion {
        guard let first = coordinates.first else {
            return MKCoordinateRegion(
                center: gate.center.clCoordinate,
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
        return MKCoordinateRegion(center: center, span: span)
    }
}

private struct DraftCenterlinePoint: Identifiable, Hashable {
    let id: UUID
    let order: Int
    let latitude: Double
    let longitude: Double

    init(id: UUID = UUID(), order: Int, latitude: Double, longitude: Double) {
        self.id = id
        self.order = order
        self.latitude = latitude
        self.longitude = longitude
    }
}

private enum DraftMode: String, CaseIterable, Hashable {
    case editSavedLayout = "Edit Saved Layout"
    case newLine = "New Line"
}

private struct TrackLayoutDraftExport: Codable {
    let exportedAt: Date
    let track: String
    let trackWidthMeters: Double
    let gate: GateDraftExport
    let points: [CenterlinePointExport]
}

private struct GateDraftExport: Codable {
    let pointA: CoordinateDraft
    let pointB: CoordinateDraft
    let center: CoordinateDraft
}

private struct CoordinateDraft: Codable {
    let latitude: Double
    let longitude: Double
}

private struct CenterlinePointExport: Codable {
    let order: Int
    let latitude: Double
    let longitude: Double
}

#Preview {
    TracksView()
}
