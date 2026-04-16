import SwiftUI
import MapKit

struct LiveTimingView: View {
    @StateObject private var viewModel = LiveTimingViewModel()
    @State private var cameraPosition: MapCameraPosition = .automatic

    private var gatePolyline: [CLLocationCoordinate2D] {
        [viewModel.currentGate.pointA.clCoordinate, viewModel.currentGate.pointB.clCoordinate]
    }

    private var routePolyline: [CLLocationCoordinate2D] {
        viewModel.route.map(\.clCoordinate)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Session Setup") {
                    Picker("Track", selection: $viewModel.selectedTrack) {
                        ForEach(Track.allCases, id: \.self) { track in
                            Text(track.rawValue).tag(track)
                        }
                    }

                    Picker("Race Direction", selection: $viewModel.raceDirection) {
                        ForEach(RaceDirection.allCases) { direction in
                            Text(direction.rawValue).tag(direction)
                        }
                    }

                    Picker("Phone Mount", selection: $viewModel.phoneMountOrientation) {
                        ForEach(PhoneMountOrientation.allCases) { orientation in
                            Text(orientation.rawValue).tag(orientation)
                        }
                    }
                }
                
                Section("Gate") {
                    Map(position: $cameraPosition, interactionModes: []) {
                        UserAnnotation()

                        if !routePolyline.isEmpty {
                            MapPolyline(coordinates: routePolyline)
                                .stroke(.blue, lineWidth: 3)
                        }

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
                    .frame(height: 260)
                    .clipped()
                }

                Section("Lap Times") {
                    if viewModel.laps.isEmpty {
                        Text("No laps yet")
                            .foregroundStyle(.secondary)
                    }

                    ForEach(viewModel.laps) { lap in
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Lap \(lap.number): \(String(format: "%.3f", lap.durationSeconds))s")
                                .font(.headline)
                            Text("Crossing speed: \(String(format: "%.2f", lap.speedAtCrossingMPS)) m/s")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text("Telemetry | Long: \(String(format: "%.2f", lap.telemetry.maxLongitudinalAccel))g | Lat: \(String(format: "%.2f", lap.telemetry.maxLateralAccel))g | Yaw: \(String(format: "%.2f", lap.telemetry.maxYawRate)) rad/s")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                Section("Gate Crossings") {
                    if viewModel.gateCrossings.isEmpty {
                        Text("No gate crossings yet")
                            .foregroundStyle(.secondary)
                    }

                    ForEach(viewModel.gateCrossings) { crossing in
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Crossing \(crossing.number): \(String(format: "%.2f", crossing.speedAtCrossingMPS)) m/s")
                                .font(.headline)
                            Text(crossing.crossedAt, style: .time)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                Section("Live") {

                    if let sample = viewModel.latestSample {
                        LabeledContent("Speed", value: String(format: "%.2f m/s", sample.speedMPS))
                        LabeledContent("Accuracy", value: String(format: "%.1f m", sample.horizontalAccuracyMeters))
                        if let course = sample.courseDegrees {
                            LabeledContent("Course", value: String(format: "%.1f°", course))
                        }
                    }

                    if viewModel.isRecording {
                        Button("Stop Session", role: .destructive) {
                            viewModel.stopSession()
                        }
                    } else {
                        Button("Start Session") {
                            viewModel.startSession()
                            cameraPosition = .region(mapRegion(for: viewModel.currentGate))
                        }
                    }

                    if !viewModel.isRecording {
                        if viewModel.isSensorCheckRunning {
                            Button("Stop Sensor Check") {
                                viewModel.stopSensorCheck()
                            }
                        } else {
                            Button("Start Sensor Check") {
                                viewModel.startSensorCheck()
                            }
                        }
                    }
                    
                    Button("Request Sensor Permissions") {
                        viewModel.requestPermissions()
                    }

                }
            }
            .navigationTitle("Live Timing")
            .onAppear {
                viewModel.requestPermissions()
                let region = mapRegion(for: viewModel.currentGate)
                cameraPosition = .region(region)
            }
            .onChange(of: viewModel.selectedTrack) { _, _ in
                cameraPosition = .region(mapRegion(for: viewModel.currentGate))
            }
        }
    }

    private func mapRegion(for gate: StartFinishGate) -> MKCoordinateRegion {
        MKCoordinateRegion(
            center: gate.center.clCoordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.003, longitudeDelta: 0.003)
        )
    }

}

#Preview {
    LiveTimingView()
}
