import SwiftUI
import SwiftData
import Charts

struct StatsView: View {
    let profile: UserProfile

    @Query(filter: #Predicate<GolfRound> { $0.isComplete }, sort: \GolfRound.date, order: .reverse)
    private var allRounds: [GolfRound]

    private var rounds: [GolfRound] { allRounds.filter { $0.profile?.id == profile.id } }
    private var statsList: [RoundStats] { rounds.map { RoundStats(round: $0) } }
    private var nineHole: [RoundStats] { statsList.filter { $0.holesPlayed <= 9 } }
    private var eighteenHole: [RoundStats] { statsList.filter { $0.holesPlayed > 9 } }

    private func average(_ values: [Int]) -> Double? {
        guard !values.isEmpty else { return nil }
        return Double(values.reduce(0, +)) / Double(values.count)
    }

    private func averagePct(_ values: [Double]) -> Double? {
        guard !values.isEmpty else { return nil }
        return values.reduce(0, +) / Double(values.count)
    }

    private var allClubTallies: [ClubType: RoundStats.ClubTally] {
        var combined: [ClubType: RoundStats.ClubTally] = [:]
        for stats in statsList {
            for (club, tally) in stats.clubTallies {
                var existing = combined[club] ?? RoundStats.ClubTally()
                existing.uses += tally.uses
                existing.good += tally.good
                existing.bad += tally.bad
                combined[club] = existing
            }
        }
        return combined
    }

    private var scoringDistributionSection: some View {
        ScoringDistributionBar(
            birdiesOrBetter: statsList.reduce(0) { $0 + $1.birdiesOrBetter },
            pars:            statsList.reduce(0) { $0 + $1.pars },
            bogeys:          statsList.reduce(0) { $0 + $1.bogeys },
            doublesOrWorse:  statsList.reduce(0) { $0 + $1.doubleBogeys + $1.triplesOrWorse }
        )
    }

    private var commonMissDirection: MissDirection? {
        let misses = statsList.compactMap(\.mainMissDirection)
        guard !misses.isEmpty else { return nil }
        return Dictionary(grouping: misses, by: { $0 }).mapValues(\.count).max(by: { $0.value < $1.value })?.key
    }

    private var commonContactIssue: ShotIssue? {
        let issues = rounds.flatMap { $0.sortedHoleScores.map(\.shotIssue) }.filter { $0 != .none }
        guard !issues.isEmpty else { return nil }
        return Dictionary(grouping: issues, by: { $0 }).mapValues(\.count).max(by: { $0.value < $1.value })?.key
    }

    var body: some View {
        VStack(spacing: 0) {
            ScreenTitleBar("Stats")
                .padding(.horizontal)

            ScrollView {
                if statsList.isEmpty {
                    emptyState
                } else {
                    VStack(spacing: 20) {
                        SectionHeader(
                            title: "Overview",
                            subtitle: "Based on \(statsList.count) round\(statsList.count == 1 ? "" : "s")",
                            icon: "chart.bar.fill"
                        )
                        headlineGrid
                        scoringDistributionSection
                        progressSection
                        trendsSection
                        patternsSection
                        clubSection
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
            Image(systemName: "chart.bar.fill").font(.system(size: 40)).foregroundStyle(.emerald)
            Text("Play a few rounds to see your stats here.").font(.subheadline).foregroundStyle(.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 80)
    }

    private var headlineGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            if let avg = average(statsList.map(\.totalStrokes)) {
                MetricTile(title: "Average Score", value: String(format: "%.1f", avg), icon: "number")
            }
            if let best = statsList.map(\.totalStrokes).min() {
                MetricTile(title: "Best Score", value: "\(best)", icon: "trophy.fill", tint: .warningAmber)
            }
            if let avg9 = average(nineHole.map(\.totalStrokes)) {
                MetricTile(title: "Avg (9 holes)", value: String(format: "%.1f", avg9), icon: "9.circle.fill")
            }
            if let avg18 = average(eighteenHole.map(\.totalStrokes)) {
                MetricTile(title: "Avg (18 holes)", value: String(format: "%.1f", avg18), icon: "18.circle.fill")
            }
            if let recent = statsList.first?.totalStrokes {
                MetricTile(title: "Most Recent", value: "\(recent)", icon: "clock.fill")
            }
            if let putts = average(statsList.map(\.totalPutts)) {
                MetricTile(title: "Avg Putts", value: String(format: "%.1f", putts), icon: "circle.dotted")
            }
            if let penalties = average(statsList.map(\.totalPenalties)) {
                MetricTile(title: "Avg Penalties", value: String(format: "%.1f", penalties), icon: "exclamationmark.triangle.fill", tint: .warningAmber)
            }
            if let fairway = averagePct(statsList.compactMap(\.fairwayHitPercentage)) {
                MetricTile(title: "Fairways Hit", value: "\(Int(fairway))%", icon: "arrow.up", info: "Percent of tee shots on par 4s/5s that landed in the fairway, averaged across all your rounds.")
            }
            if let gir = averagePct(statsList.compactMap(\.girPercentage)) {
                MetricTile(title: "Greens in Reg.", value: "\(Int(gir))%", icon: "target", info: "Greens in Regulation — reaching the green in par minus 2 strokes (e.g. your 1st shot on a par 3, 2nd on a par 4, 3rd on a par 5).")
            }
        }
    }

    @ViewBuilder
    private var progressSection: some View {
        if let trends = ProgressTrendService.trends(from: statsList) {
            VStack(alignment: .leading, spacing: 10) {
                SectionHeader(
                    title: "Your Progress",
                    icon: "chart.line.uptrend.xyaxis",
                    info: "Your last \(ProgressTrendService.windowSize) rounds compared to the \(ProgressTrendService.windowSize) before that — proof of whether what you've been working on is actually working."
                )
                VStack(spacing: 4) {
                    ForEach(Array(trends.enumerated()), id: \.element.id) { index, trend in
                        ProgressTrendRow(trend: trend)
                        if index < trends.count - 1 {
                            Divider().background(Color.white.opacity(0.08))
                        }
                    }
                }
            }
            .cardStyle(raised: true)
        } else {
            VStack(alignment: .leading, spacing: 10) {
                SectionHeader(title: "Your Progress", icon: "chart.line.uptrend.xyaxis")
                Text("Play \(ProgressTrendService.windowSize * 2) rounds total to start seeing whether you're improving.")
                    .font(.caption).foregroundStyle(.textSecondary)
            }
            .cardStyle()
        }
    }

    private var trendsSection: some View {
        VStack(spacing: 12) {
            TrendChart(title: "Score Trend", values: Array(statsList.prefix(10).map(\.scoreToPar).reversed()))
            TrendChart(title: "Putts Trend", values: Array(statsList.prefix(10).map(\.totalPutts).reversed()), color: .charcoal)
            TrendChart(title: "Penalty Trend", values: Array(statsList.prefix(10).map(\.totalPenalties).reversed()), color: .warningAmber)
        }
    }

    private var patternsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(
                title: "Patterns",
                icon: "waveform.path.ecg",
                info: "Your most frequent miss direction and contact issue across every hole you've logged — the recurring thing worth working on, not a one-off."
            )
            StatRow(label: "Common Miss Direction", value: commonMissDirection?.displayName ?? "—")
            StatRow(label: "Common Contact Issue", value: commonContactIssue?.displayName ?? "—")
        }
        .cardStyle()
    }

    private var clubSection: some View {
        NavigationLink(destination: ClubStatsView(profile: profile)) {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    SectionHeader(
                        title: "Club Performance",
                        icon: "figure.golf",
                        info: "Best/Worst are ranked by percentage of good shots logged with that club, not total uses — a club you've only swung once won't outrank one you've tracked for months."
                    )
                    Spacer()
                    Image(systemName: "chevron.right").font(.caption.weight(.semibold)).foregroundStyle(.textTertiary)
                }
                StatRow(label: "Most Used Club", value: allClubTallies.max(by: { $0.value.uses < $1.value.uses })?.key.displayName ?? "—")
                StatRow(label: "Best Performing Club", value: bestClub?.displayName ?? "—", valueColor: .emerald)
                StatRow(label: "Worst Performing Club", value: worstClub?.displayName ?? "—")
                Text("View all clubs →").font(.caption.weight(.semibold)).foregroundStyle(.emerald)
            }
            .cardStyle()
        }
        .buttonStyle(.bouncy)
    }

    private var bestClub: ClubType? {
        allClubTallies.filter { $0.value.uses > 0 }
            .max(by: { Double($0.value.good) / Double($0.value.uses) < Double($1.value.good) / Double($1.value.uses) })?.key
    }
    private var worstClub: ClubType? {
        allClubTallies.filter { $0.value.uses > 0 }
            .min(by: { Double($0.value.good) / Double($0.value.uses) < Double($1.value.good) / Double($1.value.uses) })?.key
    }
}

private struct ProgressTrendRow: View {
    let trend: ProgressTrend

    private var statusColor: Color {
        trend.improved ? .emerald : (trend.declined ? .alertCoral : .charcoal)
    }
    private var statusLabel: String {
        trend.improved ? "Improving" : (trend.declined ? "Needs Work" : "Steady")
    }

    var body: some View {
        HStack(spacing: 12) {
            IconBadge(
                icon: trend.improved ? "checkmark.circle.fill" : (trend.declined ? "exclamationmark.circle.fill" : "minus.circle.fill"),
                color: statusColor,
                size: 34
            )
            VStack(alignment: .leading, spacing: 2) {
                Text(trend.label).font(.subheadline.weight(.semibold)).foregroundStyle(.textPrimary)
                Text("\(trend.priorText) → \(trend.recentText)").font(.caption).foregroundStyle(.textSecondary)
            }
            Spacer()
            Pill(text: statusLabel, color: statusColor, filled: trend.improved)
        }
        .padding(.vertical, 4)
    }
}

private struct TrendChart: View {
    let title: String
    let values: [Int]
    var color: Color = .emerald
    @State private var revealedCount = 0

    private var yDomain: ClosedRange<Int> {
        let minV = values.min() ?? 0
        let maxV = values.max() ?? 1
        let pad = max(1, (maxV - minV) / 4)
        return (minV - pad)...(maxV + pad)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(.subheadline.weight(.semibold)).foregroundStyle(.textPrimary)
            if values.count < 2 {
                Text("Play a few more rounds to see a trend.").font(.caption).foregroundStyle(.textSecondary)
            } else {
                Chart {
                    ForEach(Array(values.enumerated().prefix(revealedCount)), id: \.offset) { index, value in
                        LineMark(x: .value("Round", index), y: .value("Value", value))
                        PointMark(x: .value("Round", index), y: .value("Value", value))
                    }
                }
                .foregroundStyle(color)
                .chartXScale(domain: 0...max(values.count - 1, 1))
                .chartYScale(domain: yDomain)
                .chartXAxis {
                    AxisMarks { _ in
                        AxisGridLine().foregroundStyle(Color.white.opacity(0.1))
                        AxisValueLabel().foregroundStyle(Color.white.opacity(0.5))
                    }
                }
                .chartYAxis {
                    AxisMarks { _ in
                        AxisGridLine().foregroundStyle(Color.white.opacity(0.1))
                        AxisValueLabel().foregroundStyle(Color.white.opacity(0.5))
                    }
                }
                .frame(height: 120)
                .onAppear {
                    revealedCount = 0
                    withAnimation(.easeOut(duration: 1.0)) {
                        revealedCount = values.count
                    }
                }
            }
        }
        .cardStyle()
    }
}
