import SwiftUI
import SwiftData

struct HistoryView: View {
    let profile: UserProfile

    @Query(filter: #Predicate<GolfRound> { $0.isComplete }, sort: \GolfRound.date, order: .reverse)
    private var allRounds: [GolfRound]

    @Environment(\.modelContext) private var context
    @State private var roundPendingDelete: GolfRound?
    @State private var selectedRound: GolfRound?
    @State private var searchText = ""

    private var rounds: [GolfRound] { allRounds.filter { $0.profile?.id == profile.id } }

    private var filteredRounds: [GolfRound] {
        let query = searchText.trimmingCharacters(in: .whitespaces).lowercased()
        guard !query.isEmpty else { return rounds }
        return rounds.filter { ($0.course?.name.lowercased().contains(query)) ?? false }
    }

    var body: some View {
        VStack(spacing: 0) {
            ScreenTitleBar("History")
                .padding(.horizontal)
                .padding(.bottom, 14)

            Group {
                if rounds.isEmpty {
                    ScrollView { emptyState }
                } else {
                    VStack(spacing: 12) {
                        InputField(placeholder: "Search rounds by course name", text: $searchText)
                            .padding(.horizontal)

                        if filteredRounds.isEmpty {
                            noResultsState
                        } else {
                            List {
                                ForEach(filteredRounds) { round in
                                    HistoryRoundCard(
                                        round: round,
                                        onOpen: { selectedRound = round },
                                        onDelete: { roundPendingDelete = round }
                                    )
                                        .listRowSeparator(.hidden)
                                        .listRowBackground(Color.clear)
                                        .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                                        .confirmationDialog("Delete This Round?", isPresented: Binding(
                                            get: { roundPendingDelete?.id == round.id },
                                            set: { if !$0 { roundPendingDelete = nil } }
                                        ), titleVisibility: .visible) {
                                            Button("Delete Round", role: .destructive) {
                                                deleteRound(round)
                                                roundPendingDelete = nil
                                            }
                                            Button("Cancel", role: .cancel) { roundPendingDelete = nil }
                                        } message: {
                                            Text("This permanently deletes this round and its stats. This can't be undone.")
                                        }
                                }
                            }
                            .listStyle(.plain)
                            .scrollContentBackground(.hidden)
                            .scrollDismissesKeyboard(.interactively)
                        }
                    }
                }
            }
            .frame(maxHeight: .infinity, alignment: .top)
        }
        .appBackground()
        .toolbar(.hidden, for: .navigationBar)
        .navigationDestination(item: $selectedRound) { round in
            RoundDetailView(round: round)
        }
    }

    private func deleteRound(_ round: GolfRound) {
        context.delete(round)
        try? context.save()
        ClubStatsService.recompute(for: profile, in: context)
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "clock.fill").font(.system(size: 40)).foregroundStyle(.emerald)
            Text("No completed rounds yet.").font(.subheadline).foregroundStyle(.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 80)
    }

    private var noResultsState: some View {
        VStack(spacing: 12) {
            Image(systemName: "magnifyingglass").font(.system(size: 32)).foregroundStyle(.textTertiary)
            Text("No rounds match \u{201C}\(searchText)\u{201D}.").font(.subheadline).foregroundStyle(.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 60)
    }
}

private struct HistoryRoundCard: View {
    let round: GolfRound
    var onOpen: () -> Void
    var onDelete: () -> Void
    private var stats: RoundStats { RoundStats(round: round) }

    var body: some View {
        HStack(spacing: 14) {
            HStack(spacing: 14) {
                ScoreBadge(scoreToPar: stats.scoreToPar, size: 50, animated: false)
                VStack(alignment: .leading, spacing: 4) {
                    Text(stats.courseName).font(.subheadline.weight(.semibold)).foregroundStyle(.textPrimary)
                    Text("\(stats.date.formatted(date: .abbreviated, time: .omitted)) • \(stats.holesPlayed) holes")
                        .font(.caption).foregroundStyle(.textSecondary)
                    HStack(spacing: 10) {
                        Text("\(stats.totalPutts) putts").font(.caption2).foregroundStyle(.textSecondary)
                        Text("\(stats.totalPenalties) penalties").font(.caption2).foregroundStyle(.textSecondary)
                    }
                    if let rating = round.advice?.rating {
                        Pill(text: rating.displayName, color: .charcoal)
                    }
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(stats.totalStrokes)").font(.title3.weight(.bold)).foregroundStyle(.textPrimary)
                    if let target = stats.targetComparison {
                        Text(target <= 0 ? "Beat target" : "+\(target) vs target")
                            .font(.caption2).foregroundStyle(.textSecondary)
                    }
                }
            }
            .contentShape(Rectangle())
            .onTapGesture {
                hapticTap()
                onOpen()
            }

            Button {
                hapticTap(.medium)
                onDelete()
            } label: {
                Image(systemName: "trash")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.alertCoral)
                    .frame(width: 34, height: 34)
                    .background(Color.alertCoral.opacity(0.12), in: Circle())
                    .contentShape(Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Delete round")
        }
        .cardStyle()
    }
}
