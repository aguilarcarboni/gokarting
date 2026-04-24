import SwiftUI

enum AppTab: Hashable {
    case dashboard
    case session
    case timeTrials
    case races
    case progression
}

struct ContentView: View {
    @State private var selectedTab: AppTab = .dashboard

    var body: some View {
        TabView(selection: $selectedTab) {
            DashboardView(selectedTab: $selectedTab)
                .tag(AppTab.dashboard)
                .tabItem {
                    Label("Dashboard", systemImage: "gauge.with.dots.needle.50percent")
                }

            LiveTimingView()
                .tag(AppTab.session)
                .tabItem {
                    Label("Session", systemImage: "point.topleft.down.curvedto.point.bottomright.up")
                }

            SessionsView()
                .tag(AppTab.timeTrials)
                .tabItem {
                    Label("Sessions", systemImage: "clock")
                }

            ProgressionView()
                .tag(AppTab.progression)
                .tabItem {
                    Label("Progression", systemImage: "chart.line.uptrend.xyaxis")
                }
        }
    }
}

#Preview {
    ContentView()
}
