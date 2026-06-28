import SwiftUI

struct MainTabView: View {
    @Bindable var profile: UserProfile
    @State private var selection: Tab = .home

    enum Tab { case home, startRound, history, stats, clubs, profile }

    var body: some View {
        TabView(selection: $selection) {
            NavigationStack { HomeView(profile: profile, selection: $selection) }
                .tabItem { Label("Home", systemImage: "house.fill") }
                .tag(Tab.home)

            NavigationStack { StartRoundTabView(profile: profile) }
                .tabItem { Label("Start Round", systemImage: "flag.fill") }
                .tag(Tab.startRound)

            NavigationStack { HistoryView() }
                .tabItem { Label("History", systemImage: "clock.fill") }
                .tag(Tab.history)

            NavigationStack { StatsView() }
                .tabItem { Label("Stats", systemImage: "chart.bar.fill") }
                .tag(Tab.stats)

            NavigationStack { ClubStatsView() }
                .tabItem { Label("Clubs", systemImage: "figure.golf") }
                .tag(Tab.clubs)

            NavigationStack { ProfileView(profile: profile) }
                .tabItem { Label("Profile", systemImage: "person.fill") }
                .tag(Tab.profile)
        }
        .tint(.brandRed)
    }
}
