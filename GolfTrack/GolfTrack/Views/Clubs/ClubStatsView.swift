import SwiftUI
import SwiftData

struct ClubStatsView: View {
    let profile: UserProfile

    @Query private var allStats: [ClubStats]

    private var usedStats: [ClubStats] {
        allStats.filter { $0.profile?.id == profile.id && $0.timesUsed > 0 }.sorted { $0.timesUsed > $1.timesUsed }
    }

    private var bestPerforming: ClubStats? {
        usedStats.filter { $0.timesUsed >= 2 }.max(by: { $0.goodShotRate < $1.goodShotRate })
    }
    private var mostProblematic: ClubStats? {
        usedStats.filter { $0.timesUsed >= 2 }.min(by: { $0.goodShotRate < $1.goodShotRate })
    }
    private var clubsToPractice: [ClubStats] {
        usedStats.filter { $0.timesUsed >= 2 && $0.goodShotRate < 0.5 }.sorted { $0.goodShotRate < $1.goodShotRate }
    }

    var body: some View {
        VStack(spacing: 0) {
            PushedScreenHeader("Clubs")
                .padding(.horizontal)

            ScrollView {
                if usedStats.isEmpty {
                    emptyState
                } else {
                    VStack(spacing: 20) {
                        overviewSection
                        if !clubsToPractice.isEmpty {
                            practiceSection
                        }
                        allClubsSection
                    }
                    .padding()
                }
            }
        }
        .appBackground()
        .toolbar(.hidden, for: .navigationBar)
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "figure.golf").font(.system(size: 40)).foregroundStyle(.emerald)
            Text("Play a round to start building club stats.").font(.subheadline).foregroundStyle(.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 80)
    }

    private var overviewSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(
                title: "Overview",
                icon: "figure.golf",
                info: "Best/Most Problematic are ranked by percentage of good shots with that club (minimum 2 logged shots), not raw totals."
            )
            StatRow(label: "Most Used Club", value: usedStats.first?.club.displayName ?? "—")
            StatRow(label: "Best Performing Club", value: bestPerforming?.club.displayName ?? "—", valueColor: .emerald)
            StatRow(label: "Most Problematic Club", value: mostProblematic?.club.displayName ?? "—")
        }
        .cardStyle()
    }

    private var practiceSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Clubs to Practice", icon: "wrench.and.screwdriver.fill")
            VStack(spacing: 8) {
                ForEach(clubsToPractice) { stat in
                    NavigationLink(destination: ClubDetailView(stats: stat)) {
                        ClubStatsRow(stats: stat)
                    }
                    .buttonStyle(.bouncy)
                }
            }
        }
        .cardStyle()
    }

    private var allClubsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "All Clubs", icon: "list.bullet")
            VStack(spacing: 8) {
                ForEach(usedStats) { stat in
                    NavigationLink(destination: ClubDetailView(stats: stat)) {
                        ClubStatsRow(stats: stat)
                    }
                    .buttonStyle(.bouncy)
                }
            }
        }
        .cardStyle()
    }
}

private struct ClubStatsRow: View {
    let stats: ClubStats
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(stats.club.displayName).font(.subheadline.weight(.semibold)).foregroundStyle(.textPrimary)
                Text("\(stats.timesUsed) shots • \(Int(stats.goodShotRate * 100))% good" + (stats.dominantMiss.map { " • mostly \($0)" } ?? ""))
                    .font(.caption).foregroundStyle(.textSecondary)
            }
            Spacer()
            Image(systemName: "chevron.right").font(.caption).foregroundStyle(.textTertiary)
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
    }
}
