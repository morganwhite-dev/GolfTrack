import SwiftUI
import SwiftData

struct HistoryView: View {
    @Query(filter: #Predicate<GolfRound> { $0.isComplete }, sort: \GolfRound.date, order: .reverse)
    private var rounds: [GolfRound]

    @Environment(\.modelContext) private var context
    @State private var roundPendingDelete: GolfRound?
    @State private var selectedRound: GolfRound?

    var body: some View {
        Group {
            if rounds.isEmpty {
                ScrollView { emptyState }
            } else {
                List {
                    ForEach(rounds) { round in
                        HistoryRoundCard(round: round)
                            .contentShape(Rectangle())
                            .onTapGesture { selectedRound = round }
                            .listRowSeparator(.hidden)
                            .listRowBackground(Color.clear)
                            .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    roundPendingDelete = round
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("History")
        .navigationDestination(item: $selectedRound) { round in
            RoundDetailView(round: round)
        }
        .confirmationDialog("Delete This Round?", isPresented: Binding(
            get: { roundPendingDelete != nil },
            set: { if !$0 { roundPendingDelete = nil } }
        ), titleVisibility: .visible) {
            Button("Delete Round", role: .destructive) {
                if let round = roundPendingDelete { deleteRound(round) }
                roundPendingDelete = nil
            }
            Button("Cancel", role: .cancel) { roundPendingDelete = nil }
        } message: {
            Text("This permanently deletes this round and its stats. This can't be undone.")
        }
    }

    private func deleteRound(_ round: GolfRound) {
        context.delete(round)
        try? context.save()
        ClubStatsService.recompute(in: context)
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
