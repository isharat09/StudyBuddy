import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            TodayView()
                .tabItem {
                    Label("Today", systemImage: "rectangle.grid.2x2")
                }
                .tag(0)

            TaskListView()
                .tabItem {
                    Label("Tasks", systemImage: "checklist")
                }
                .tag(1)

            TimerView()
                .tabItem {
                    Label("Timer", systemImage: "timer")
                }
                .tag(2)

            StatsView()
                .tabItem {
                    Label("Stats", systemImage: "chart.line.uptrend.xyaxis")
                }
                .tag(3)

            SubjectsView()
                .tabItem {
                    Label("Subjects", systemImage: "book.closed")
                }
                .tag(4)
        }
        .accentColor(AppColors.primary)
        .onAppear {
            NotificationManager.shared.requestPermission()
        }
    }
}
