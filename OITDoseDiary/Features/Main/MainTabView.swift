import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            TodayView()
                .tabItem { Label("Today", systemImage: "sun.max") }
            HistoryView()
                .tabItem { Label("History", systemImage: "calendar") }
            ReportView()
                .tabItem { Label("Report", systemImage: "doc.text") }
        }
    }
}
