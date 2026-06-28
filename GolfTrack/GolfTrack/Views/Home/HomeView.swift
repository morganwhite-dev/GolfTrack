import SwiftUI
import SwiftData

struct HomeView: View {
    @Bindable var profile: UserProfile
    @Binding var selection: MainTabView.Tab

    @Query(filter: #Predicate<GolfRound> { !$0.isComplete }, sort: \GolfRound.date, order: .reverse)
    private var inProgressRounds: [GolfRound]

    @Query(filter: #Predicate<GolfRound> { $0.isComplete }, sort: \GolfRound.date, order: .reverse)
    private var completedRounds: [GolfRound]

    @State private var resumeRound: GolfRound?

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Hi, \(profile.name.isEmpty ? "Golfer" : profile.name)")
                        .font(.largeTitle.bold())
                    Text(profile.skillLevel.displayName)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                if let round = inProgressRounds.first {
                    VStack(alignment: .leading, spacing: 10) {
                        SectionHeader(title: "Round in progress", subtitle: round.course?.name ?? "Course")
                        Text("Resume where you left off.")
                            .font(.subheadline).foregroundStyle(.secondary)
                        Button("Resume Round") { resumeRound = round }
                            .buttonStyle(.primaryGolf)
                    }
                    .cardStyle()
                }

                VStack(spacing: 10) {
                    SectionHeader(title: "Ready to play?")
                    Button("Start a New Round") { selection = .startRound }
                        .buttonStyle(.primaryGolf)
                }
                .cardStyle()

                if !completedRounds.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        SectionHeader(title: "Recent Rounds")
                        ForEach(completedRounds.prefix(3)) { round in
                            NavigationLink(value: round) {
                                RoundSummaryRow(round: round)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .cardStyle()

                    quickStatsCard
                } else {
                    VStack(spacing: 8) {
                        Image(systemName: "flag.fill").font(.largeTitle).foregroundStyle(.secondary)
                        Text("No rounds yet — play your first round to start building stats.")
                            .font(.subheadline).foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .cardStyle()
                }
            }
            .padding()
        }
        .navigationTitle("GolfTrack")
        .navigationDestination(for: GolfRound.self) { round in
            RoundDetailView(round: round)
        }
        .fullScreenCover(item: $resumeRound) { round in
            RoundFlowView(round: round)
        }
    }

    private var quickStatsCard: some View {
        let avg = Double(completedRounds.reduce(0) { $0 + $1.totalStrokes }) / Double(max(completedRounds.count, 1))
        let best = completedRounds.map(\.totalStrokes).min() ?? 0
        return HStack(spacing: 12) {
            StatTile(title: "Avg Score", value: String(format: "%.1f", avg))
            StatTile(title: "Best Score", value: "\(best)")
            StatTile(title: "Rounds", value: "\(completedRounds.count)")
        }
    }
}

struct StatTile: View {
    let title: String
    let value: String
    var body: some View {
        VStack(spacing: 4) {
            Text(value).font(.title2.bold())
            Text(title).font(.caption).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .cardStyle(padding: 8)
    }
}

struct RoundSummaryRow: View {
    let round: GolfRound
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(round.course?.name ?? "Round").font(.subheadline.weight(.semibold))
                Text(round.date.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(round.totalStrokes)").font(.subheadline.weight(.semibold))
                Text(scoreToParText(round.scoreToPar)).font(.caption).foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
    }
}

func scoreToParText(_ value: Int) -> String {
    if value == 0 { return "E" }
    return value > 0 ? "+\(value)" : "\(value)"
}
