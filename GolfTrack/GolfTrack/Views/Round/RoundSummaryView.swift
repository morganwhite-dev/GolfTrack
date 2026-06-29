import SwiftUI

struct RoundSummaryView: View {
    let round: GolfRound
    var onContinue: (() -> Void)? = nil

    private var stats: RoundStats { RoundStats(round: round) }

    var body: some View {
        VStack(spacing: 20) {
            header
            scoreCard
            quickStatsGrid
            scoringBreakdown
            notableHoles
            patterns
            clubPerformance

            if let onContinue {
                Button("Continue to Reflection") { onContinue() }
                    .buttonStyle(.primaryGolf)
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Round Summary").font(.title2.weight(.bold)).foregroundStyle(.textPrimary)
            HStack(spacing: 8) {
                Pill(text: stats.courseName)
                Pill(text: "\(stats.holesPlayed) holes", color: .charcoal)
                Pill(text: stats.date.formatted(date: .abbreviated, time: .omitted), color: .charcoal)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var scoreCard: some View {
        VStack(spacing: 10) {
            ScoreBadge(scoreToPar: stats.scoreToPar, size: 76)
            Text("\(stats.totalStrokes) strokes").font(.title3.weight(.semibold)).foregroundStyle(.textPrimary)
            Text("Par \(stats.totalPar)").font(.subheadline).foregroundStyle(.textSecondary)
            if let comparison = stats.targetComparison {
                Text(comparison <= 0
                     ? "You beat your target by \(abs(comparison))"
                     : "\(comparison) over your target score")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(comparison <= 0 ? .emerald : .textSecondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .cardStyle(raised: true)
    }

    private var quickStatsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            MetricTile(title: "Putts", value: "\(stats.totalPutts)", icon: "circle.dotted")
            MetricTile(title: "Penalties", value: "\(stats.totalPenalties)", icon: "exclamationmark.triangle.fill", tint: .warningAmber)
            MetricTile(title: "Avg / Hole", value: String(format: "%.1f", stats.averageStrokesPerHole), icon: "chart.bar.fill")
            if let fairway = stats.fairwayHitPercentage {
                MetricTile(title: "Fairways Hit", value: "\(Int(fairway))%", icon: "arrow.up")
            }
            if let gir = stats.girPercentage {
                MetricTile(title: "Greens in Reg.", value: "\(Int(gir))%", icon: "target")
            }
            MetricTile(title: "Avg Putts", value: String(format: "%.1f", stats.averagePuttsPerHole), icon: "circle.dotted")
        }
    }

    private var scoringBreakdown: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "Scoring Breakdown", icon: "chart.pie.fill")
            StatRow(label: "Pars", value: "\(stats.pars)")
            StatRow(label: "Bogeys", value: "\(stats.bogeys)")
            StatRow(label: "Double Bogeys", value: "\(stats.doubleBogeys)")
            StatRow(label: "Triple Bogeys or Worse", value: "\(stats.triplesOrWorse)")
        }
        .cardStyle()
    }

    @ViewBuilder
    private var notableHoles: some View {
        if let best = stats.bestHole, let worst = stats.worstHole {
            VStack(alignment: .leading, spacing: 10) {
                SectionHeader(title: "Notable Holes", icon: "star.fill")
                StatRow(label: "Best Hole", value: "Hole \(best.holeNumber) — \(scoreToParText(best.scoreToPar))", valueColor: .emerald)
                StatRow(label: "Worst Hole", value: "Hole \(worst.holeNumber) — \(scoreToParText(worst.scoreToPar))")
            }
            .cardStyle()
        }
    }

    private var patterns: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "Patterns", icon: "waveform.path.ecg")
            StatRow(label: "Holes with Penalties", value: "\(stats.holesWithPenalties)")
            StatRow(label: "Three-Putts", value: "\(stats.threePutts)")
            StatRow(label: "Main Miss Direction", value: stats.mainMissDirection?.displayName ?? "None")
        }
        .cardStyle()
    }

    @ViewBuilder
    private var clubPerformance: some View {
        if !stats.clubTallies.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                SectionHeader(title: "Club Performance", icon: "figure.golf")
                StatRow(label: "Most Used Club", value: stats.mostUsedClub?.displayName ?? "—")
                StatRow(label: "Best Performing Club", value: stats.bestPerformingClub?.displayName ?? "—", valueColor: .emerald)
                StatRow(label: "Most Problematic Club", value: stats.mostProblematicClub?.displayName ?? "—")
            }
            .cardStyle()
        }
    }
}
