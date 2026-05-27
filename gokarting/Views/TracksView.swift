import SwiftUI
import MapKit

struct TracksView: View {
    @State private var selectedTrack: Track = .p1ShortConfig
    @State private var cameraPosition: MapCameraPosition = .automatic
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
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Tracks")
                            .font(.system(.largeTitle, design: .rounded, weight: .bold))
                            .foregroundStyle(.white)
                        Text("Browse layouts, gates, and track metadata.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    HStack(spacing: 10) {
                        Menu {
                            Picker("Track", selection: $selectedTrack) {
                                ForEach(orderedTracks, id: \.self) { track in
                                    Text(track.rawValue).tag(track)
                                }
                            }
                        } label: {
                            Label(selectedTrack.rawValue, systemImage: "map")
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
                            sectionTitle("Map")

                            Map(position: $cameraPosition, interactionModes: [.zoom, .pan]) {
                                if !layoutPolyline.isEmpty {
                                    MapPolyline(coordinates: layoutPolyline)
                                        .stroke(.blue, lineWidth: 4)
                                }

                                MapPolyline(coordinates: gatePolyline)
                                    .stroke(.red, lineWidth: 5)

                                Marker("A", coordinate: gate.pointA.clCoordinate).tint(.red)
                                Marker("B", coordinate: gate.pointB.clCoordinate).tint(.red)
                            }
                            .mapStyle(.imagery(elevation: .realistic))
                            .mapControls {
                                MapUserLocationButton()
                            }
                            .frame(height: 360)
                            .clipShape(RoundedRectangle(cornerRadius: 20))

                            Text(layoutPolyline.isEmpty ? "Gate-only track (no saved layout)." : "Layout loaded (\(layoutPolyline.count) points).")
                                .font(.subheadline)
                                .foregroundStyle(.secondary.opacity(0.9))
                        }
                    }

                    card {
                        VStack(alignment: .leading, spacing: 10) {
                            sectionTitle("Info")
                            statRow("Default Direction", selectedTrack.defaultRaceDirection.rawValue)
                            statRow("Supported Directions", selectedTrack.supportedRaceDirections.map(\.rawValue).joined(separator: ", "))
                            statRow("Available Karts", selectedTrack.availableKarts.map(\.rawValue).joined(separator: ", "))
                            statRow("Layout Points", "\(layoutPolyline.count)")
                            statRow("Gate A", coordinateText(selectedTrack.gatePoints.pointA))
                            statRow("Gate B", coordinateText(selectedTrack.gatePoints.pointB))
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 24)
            }
            .appScreenBackground()
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(.hidden, for: .navigationBar)
            .onAppear {
                cameraPosition = .region(mapRegion(for: selectedTrack))
            }
            .onChange(of: selectedTrack) { _, newTrack in
                cameraPosition = .region(mapRegion(for: newTrack))
            }
        }
    }

    private func card<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            content()
        }
        .padding(20)
        .glassCard(radius: 30)
    }

    private func sectionTitle(_ title: String) -> some View {
        Text(title)
            .font(.title3.weight(.semibold))
            .foregroundStyle(.white)
    }

    private func statRow(_ title: String, _ value: String) -> some View {
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

    private func coordinateText(_ point: GeoCoordinate) -> String {
        String(format: "%.6f, %.6f", point.latitude, point.longitude)
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

#Preview {
    TracksView()
}
