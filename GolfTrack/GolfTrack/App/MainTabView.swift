import SwiftUI
import SwiftData

struct MainTabView: View {
    @Bindable var profile: UserProfile
    @State private var selection: Tab = .home
    @State private var activeRound: GolfRound?
    @AppStorage("profileSwitchResumeRoundID") private var profileSwitchResumeRoundIDString: String = ""
    @Query(filter: #Predicate<GolfRound> { !$0.isComplete }, sort: \GolfRound.date, order: .reverse)
    private var allInProgressRounds: [GolfRound]

    enum Tab { case home, startRound, history, stats, profile }

    private var inProgressRounds: [GolfRound] {
        allInProgressRounds.filter { $0.profile?.id == profile.id }
    }

    var body: some View {
        TabView(selection: $selection) {
            NavigationStack { HomeView(profile: profile, selection: $selection, onOpenRound: openRound).enableSwipeBack() }
                .tabItem { Label("Home", systemImage: "house.fill") }
                .tag(Tab.home)

            NavigationStack { StartRoundTabView(profile: profile).enableSwipeBack() }
                .tabItem { Label("Start Round", systemImage: "flag.fill") }
                .tag(Tab.startRound)

            NavigationStack { HistoryView(profile: profile).enableSwipeBack() }
                .tabItem { Label("History", systemImage: "clock.fill") }
                .tag(Tab.history)

            NavigationStack { StatsView(profile: profile).enableSwipeBack() }
                .tabItem { Label("Stats", systemImage: "chart.bar.fill") }
                .tag(Tab.stats)

            NavigationStack { ProfileView(profile: profile).enableSwipeBack() }
                .tabItem { Label("Profile", systemImage: "person.fill") }
                .tag(Tab.profile)
        }
        .tint(.emerald)
        .buttonStyle(.bouncy)
        .fullScreenCover(item: $activeRound) { round in
            RoundFlowView(
                round: round,
                onSwitchRound: { nextRound in
                    profileSwitchResumeRoundIDString = nextRound.id.uuidString
                    activeRound = nil
                }
            )
        }
        .onAppear {
            scheduleProfileSwitchRoundOpen()
        }
        .onChange(of: profileSwitchResumeRoundIDString) { _, _ in
            scheduleProfileSwitchRoundOpen()
        }
        .onChange(of: inProgressRounds.first?.id) { _, _ in
            scheduleProfileSwitchRoundOpen()
        }
        .task(id: profile.id) {
            openProfileSwitchRoundIfNeeded()
        }
    }

    private func openRound(_ round: GolfRound) {
        activeRound = nil
        DispatchQueue.main.async {
            activeRound = round
        }
    }

    private func scheduleProfileSwitchRoundOpen() {
        DispatchQueue.main.async {
            openProfileSwitchRoundIfNeeded()
        }
    }

    private func openProfileSwitchRoundIfNeeded() {
        guard let pendingID = UUID(uuidString: profileSwitchResumeRoundIDString),
              let round = inProgressRounds.first(where: { $0.id == pendingID }) else {
            return
        }
        profileSwitchResumeRoundIDString = ""
        activeRound = round
    }
}
