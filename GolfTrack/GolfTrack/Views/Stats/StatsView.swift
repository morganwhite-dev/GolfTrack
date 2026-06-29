import SwiftUI
import SwiftData
import Charts

struct StatsView: View {
    @Query(filter: #Predicate<GolfRound> { $0.isComplete }, sort: \GolfRound.date, order: .reverse)
    private var rounds: [GolfRound]

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
        ScrollView {
            if statsList.isEmpty {
                emptyState
            } else {
                VStack(spacing: 20) {
                    SectionHeader(title: "Overview", icon: "chart.bar.fill")
                    headlineGrid
                    trendsSection
                    patternsSection
                    clubSection
                }
                .padding()
            }
        }
        .appBackground()
        .navigationTitle("Stats")
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
                MetricTile(title: "Fairways Hit", value: "\(Int(fairway))%", icon: "arrow.up")
            }
            if let gir = averagePct(statsList.compactMap(\.girPercentage)) {
                MetricTile(title: "Greens in Reg.", value: "\(Int(gir))%", icon: "target")
            }
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
            SectionHeader(title: "Patterns", icon: "waveform.path.ecg")
            StatRow(label: "Common Miss Direction", value: commonMissDirection?.displayName ?? "—")
            StatRow(label: "Common Contact Issue", value: commonContactIssue?.displayName ?? "—")
        }
        .cardStyle()
    }

    private var clubSection: some View {
        NavigationLink(destination: ClubStatsView()) {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    SectionHeader(title: "Club Performance", icon: "figure.golf")
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
        allClubTallies.filter { $0.value.bad > 0 }.max(by: { $0.value.bad < $1.value.bad })?.key
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
