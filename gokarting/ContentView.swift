import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            DashboardView()
                .tabItem {
                    Label("Dashboard", systemImage: "gauge.with.dots.needle.50percent")
                }

            TimeTrialView()
                .tabItem {
                    Label("Time Trials", systemImage: "stopwatch")
                }

            RaceHistoryView(raceEvents: SampleData.races)
                .tabItem {
                    Label("Races", systemImage: "flag.checkered")
                }

            ProgressionView()
                .tabItem {
                    Label("Progression", systemImage: "chart.line.uptrend.xyaxis")
                }
        }
    }
}

#Preview {
    ContentView()
}
