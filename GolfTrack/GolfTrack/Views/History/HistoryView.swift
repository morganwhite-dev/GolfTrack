import SwiftUI
import SwiftData

struct HistoryView: View {
    @Query(filter: #Predicate<GolfRound> { $0.isComplete }, sort: \GolfRound.date, order: .reverse)
    private var rounds: [GolfRound]

    var body: some View {
        ScrollView {
            if rounds.isEmpty {
                emptyState
            } else {
                VStack(spacing: 12) {
                    ForEach(rounds) { round in
                        NavigationLink(value: round) {
                            HistoryRoundCard(round: round)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding()
            }
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("History")
        .navigationDestination(for: GolfRound.self) { round in
            RoundDetailView(round: round)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "clock.fill").font(.system(size: 40)).foregroundStyle(.brandRed)
            Text("No completed rounds yet.").font(.subheadline).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 80)
    }
}

private struct HistoryRoundCard: View {
    let round: GolfRound
    private var stats: RoundStats { RoundStats(round: round) }

    var body: some View {
        HStack(spacing: 14) {
            ScoreBadge(scoreToPar: stats.scoreToPar, size: 50)
            VStack(alignment: .leading, spacing: 4) {
                Text(stats.courseName).font(.subheadline.weight(.semibold))
                Text("\(stats.date.formatted(date: .abbreviated, time: .omitted)) • \(stats.holesPlayed) holes")
                    .font(.caption).foregroundStyle(.secondary)
                HStack(spacing: 10) {
                    Text("\(stats.totalPutts) putts").font(.caption2).foregroundStyle(.secondary)
                    Text("\(stats.totalPenalties) penalties").font(.caption2).foregroundStyle(.secondary)
                }
                if let rating = round.advice?.rating {
                    Pill(text: rating.displayName, color: .charcoal)
                }
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(stats.totalStrokes)").font(.title3.weight(.bold))
                if let target = stats.targetComparison {
                    Text(target <= 0 ? "Beat target" : "+\(target) vs target")
                        .font(.caption2).foregroundStyle(.secondary)
                }
            }
        }
        .cardStyle()
    }
}
