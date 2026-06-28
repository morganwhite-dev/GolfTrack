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

    private var greeting: String {
        switch Calendar.current.component(.hour, from: Date()) {
        case 0..<12: return "Good morning"
        case 12..<17: return "Good afternoon"
        default: return "Good evening"
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                header

                if let round = inProgressRounds.first {
                    inProgressCard(round)
                }

                startRoundHero

                if completedRounds.isEmpty {
                    emptyStateCard
                } else {
                    quickStatsRow
                    recentRoundsCard
                }
            }
            .padding(.horizontal)
            .padding(.top, 8)
            .padding(.bottom, 28)
        }
        .background(Color(.systemGroupedBackground))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Label("GolfTrack", systemImage: "flag.fill")
                    .font(.headline)
                    .foregroundStyle(.golfGreen)
            }
        }
        .navigationDestination(for: GolfRound.self) { round in
            RoundDetailView(round: round)
        }
        .fullScreenCover(item: $resumeRound) { round in
            RoundFlowView(round: round)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("\(greeting), \(profile.name.isEmpty ? "Golfer" : profile.name)")
                .font(.system(.largeTitle, design: .rounded, weight: .bold))
                .fixedSize(horizontal: false, vertical: true)
            HStack(spacing: 8) {
                Pill(text: profile.skillLevel.displayName)
                if let goal = profile.goals.first {
                    Pill(text: goal.displayName, color: .fairwayGreen)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func inProgressCard(_ round: GolfRound) -> some View {
        let holesEntered = round.sortedHoleScores.filter { $0.strokes > 0 }.count
        return Button { resumeRound = round } label: {
            HStack(spacing: 14) {
                ZStack {
                    Circle().fill(Color.warningAmber.opacity(0.15)).frame(width: 50, height: 50)
                    Image(systemName: "arrow.clockwise").foregroundStyle(.warningAmber).font(.title3)
                }
                VStack(alignment: .leading, spacing: 5) {
                    Text("Round in Progress").font(.subheadline.weight(.semibold))
                    Text(round.course?.name ?? "Course")
                        .font(.caption).foregroundStyle(.secondary)
                    ProgressView(value: Double(holesEntered), total: Double(max(round.holesPlayed, 1)))
                        .tint(.warningAmber)
                }
                Spacer()
                Image(systemName: "chevron.right").font(.caption.weight(.semibold)).foregroundStyle(.secondary)
            }
            .padding(16)
            .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .strokeBorder(Color.warningAmber.opacity(0.4), lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
    }

    private var startRoundHero: some View {
        Button { selection = .startRound } label: {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Ready to play?").font(.title3.weight(.bold)).foregroundStyle(.white)
                    Text("Start a new round").font(.subheadline).foregroundStyle(.white.opacity(0.85))
                }
                Spacer()
                ZStack {
                    Circle().fill(.white.opacity(0.18)).frame(width: 52, height: 52)
                    Image(systemName: "plus").font(.title2.weight(.bold)).foregroundStyle(.white)
                }
            }
            .padding(20)
            .background(
                LinearGradient(colors: [.golfGreen, .fairwayGreen], startPoint: .topLeading, endPoint: .bottomTrailing),
                in: RoundedRectangle(cornerRadius: 22, style: .continuous)
            )
            .shadow(color: Color.golfGreen.opacity(0.35), radius: 14, x: 0, y: 8)
        }
        .buttonStyle(.plain)
    }

    private var quickStatsRow: some View {
        let avg = Double(completedRounds.reduce(0) { $0 + $1.totalStrokes }) / Double(max(completedRounds.count, 1))
        let best = completedRounds.map(\.totalStrokes).min() ?? 0
        return HStack(spacing: 12) {
            StatTile(icon: "target", title: "Avg Score", value: String(format: "%.1f", avg), tint: .blue)
            StatTile(icon: "trophy.fill", title: "Best Score", value: "\(best)", tint: .warningAmber)
            StatTile(icon: "calendar", title: "Rounds", value: "\(completedRounds.count)", tint: .fairwayGreen)
        }
    }

    private var recentRoundsCard: some View {
        let recent = Array(completedRounds.prefix(3))
        return VStack(alignment: .leading, spacing: 14) {
            HStack {
                SectionHeader(title: "Recent Rounds")
                Spacer()
                Button("See All") { selection = .history }
                    .font(.subheadline.weight(.medium))
            }
            VStack(spacing: 4) {
                ForEach(Array(recent.enumerated()), id: \.element.id) { index, round in
                    NavigationLink(value: round) {
                        RoundSummaryRow(round: round)
                    }
                    .buttonStyle(.plain)
                    if index < recent.count - 1 {
                        Divider()
                    }
                }
            }
        }
        .cardStyle()
    }

    private var emptyStateCard: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle().fill(Color.golfGreen.opacity(0.12)).frame(width: 64, height: 64)
                Image(systemName: "flag.fill").font(.title2).foregroundStyle(.golfGreen)
            }
            Text("No rounds yet").font(.headline)
            Text("Play your first round to start building stats and getting personalized advice.")
                .font(.subheadline).foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 28)
        .cardStyle()
    }
}

private struct StatTile: View {
    let icon: String
    let title: String
    let value: String
    var tint: Color = .golfGreen
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon).font(.title3).foregroundStyle(tint)
            Text(value).font(.title2.weight(.bold))
            Text(title).font(.caption).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .cardStyle(padding: 8, cornerRadius: 16)
    }
}

struct RoundSummaryRow: View {
    let round: GolfRound
    var body: some View {
        HStack(spacing: 14) {
            ScoreBadge(scoreToPar: round.scoreToPar, size: 46)
            VStack(alignment: .leading, spacing: 3) {
                Text(round.course?.name ?? "Round").font(.subheadline.weight(.semibold))
                HStack(spacing: 6) {
                    Text(round.date.formatted(date: .abbreviated, time: .omitted))
                    Text("•")
                    Text("\(round.holesPlayed) holes")
                }
                .font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(round.totalStrokes)").font(.title3.weight(.bold))
                Text("strokes").font(.caption2).foregroundStyle(.secondary)
            }
            Image(systemName: "chevron.right").font(.caption.weight(.semibold)).foregroundStyle(Color(.tertiaryLabel))
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
    }
}
