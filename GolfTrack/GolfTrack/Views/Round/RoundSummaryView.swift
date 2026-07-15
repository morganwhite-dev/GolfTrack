import SwiftUI
import SwiftData

struct RoundSummaryView: View {
    let round: GolfRound
    var onContinue: (() -> Void)? = nil
    var continueTitle = "Continue to Reflection"

    @Query(filter: #Predicate<GolfRound> { $0.isComplete }, sort: \GolfRound.date)
    private var allRounds: [GolfRound]

    private var stats: RoundStats { RoundStats(round: round) }

    var body: some View {
        VStack(spacing: 20) {
            header
            scoreCard
            whatMatteredCard
            strokesToSaveSection
            courseMemorySection
            achievementBanner
            quickStatsGrid
            scoringBreakdown
            notableHoles
            patterns
            clubPerformance

            if let onContinue {
                Button(continueTitle) { onContinue() }
                    .buttonStyle(.primaryGolf)
            }
        }
    }

    private var whatMatteredCard: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: topTakeaway.icon)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(topTakeaway.color)
                .frame(width: 30, height: 30)
                .background(topTakeaway.color.opacity(0.14), in: Circle())
            VStack(alignment: .leading, spacing: 3) {
                Text("What Mattered")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(topTakeaway.color)
                    .tracking(0.4)
                Text(topTakeaway.message)
                    .font(.subheadline)
                    .foregroundStyle(.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle(raised: true)
    }

    private var topTakeaway: (icon: String, color: Color, message: String) {
        let signals = RoundAnalysisService.extractTextSignals(from: round)
        if stats.totalPenalties >= 2 {
            return ("exclamationmark.triangle.fill", .warningAmber, "Penalties cost you \(stats.totalPenalties) stroke\(stats.totalPenalties == 1 ? "" : "s"). Course management is the fastest place to save shots next time.")
        }
        if stats.threePutts >= 2 {
            return ("circle.dotted", .warningAmber, "\(stats.threePutts) three-putts shaped the round. Speed control should be the first practice priority.")
        }
        if !signals.holeNoteContactHoles.isEmpty {
            return ("figure.golf", .warningAmber, "Your notes mention contact on \(holeList(signals.holeNoteContactHoles)). That is a useful pattern to bring into practice.")
        }
        if !signals.holeNoteMentalHoles.isEmpty {
            return ("brain.head.profile", .warningAmber, "Your notes mention focus or routine on \(holeList(signals.holeNoteMentalHoles)). That is worth treating like a scoring skill.")
        }
        if let miss = stats.mainMissDirection {
            return ("arrow.up.right", .emerald, "Your main miss leaned \(miss.displayName.lowercased()). Keep tracking it so the app can separate one bad round from a real trend.")
        }
        if stats.totalPenalties == 0 {
            return ("checkmark.seal.fill", .emerald, "No penalties today. That kind of clean round management gives every other part of your game room to improve.")
        }
        return ("sparkles", .emerald, "You logged enough to build a useful baseline. Add details while the round is fresh for sharper advice.")
    }

    private func holeList(_ holes: [Int]) -> String {
        let unique = Array(Set(holes)).sorted()
        let labels = unique.prefix(3).map { "hole \($0)" }
        if unique.count > 3 {
            return labels.joined(separator: ", ") + ", and others"
        }
        return labels.joined(separator: ", ")
    }

    @ViewBuilder
    private var strokesToSaveSection: some View {
        let rows = scoringOpportunityRows
        if !rows.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                SectionHeader(
                    title: "Strokes to Save",
                    icon: "target",
                    info: "The fastest scoring opportunities from this round, based on logged penalties, putting, and blow-up holes."
                )
                ForEach(rows) { row in
                    HStack(alignment: .center, spacing: 10) {
                        Image(systemName: row.icon)
                            .font(.caption.weight(.bold))
                            .foregroundStyle(row.color)
                            .frame(width: 28, height: 28)
                            .background(row.color.opacity(0.14), in: Circle())
                        VStack(alignment: .leading, spacing: 2) {
                            Text(row.title)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.textPrimary)
                            Text(row.detail)
                                .font(.caption)
                                .foregroundStyle(.textSecondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        Spacer(minLength: 8)
                        Text(row.badge)
                            .font(.caption.weight(.bold))
                            .foregroundStyle(row.color)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 5)
                            .background(row.color.opacity(0.12), in: Capsule())
                    }
                    .padding(.vertical, 2)
                }
            }
            .cardStyle()
        }
    }

    @ViewBuilder
    private var courseMemorySection: some View {
        let rows = courseMemoryRows
        if !rows.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                SectionHeader(
                    title: "Course Memory",
                    icon: "flag.checkered",
                    info: "Compares this round against your previous rounds at the same course."
                )
                ForEach(rows) { row in
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: row.icon)
                            .font(.caption.weight(.bold))
                            .foregroundStyle(row.color)
                            .frame(width: 28, height: 28)
                            .background(row.color.opacity(0.14), in: Circle())
                        VStack(alignment: .leading, spacing: 2) {
                            Text(row.title)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.textPrimary)
                            Text(row.detail)
                                .font(.caption)
                                .foregroundStyle(.textSecondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        Spacer()
                    }
                    .padding(.vertical, 2)
                }
            }
            .cardStyle()
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Text("Round Summary").font(.title2.weight(.bold)).foregroundStyle(.textPrimary)
                InfoTip(text: "Scores are relative to par — \"E\" means even, \"+3\" is three over, \"-2\" is two under.")
            }
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
            HStack(spacing: 4) {
                CountUpNumber(value: stats.totalStrokes, font: .title3.weight(.semibold), color: .textPrimary)
                Text("strokes").font(.title3.weight(.semibold)).foregroundStyle(.textPrimary)
            }
            Text("Par \(stats.totalPar)").font(.subheadline).foregroundStyle(.textSecondary)
            if let comparison = stats.targetComparison {
                Text(
                    comparison < 0  ? "You beat your target by \(abs(comparison)) stroke\(abs(comparison) == 1 ? "" : "s")" :
                    comparison == 0 ? "You hit your target score!" :
                                      "\(comparison) over your target score"
                )
                .font(.subheadline.weight(.medium))
                .foregroundStyle(comparison <= 0 ? .emerald : .textSecondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .cardStyle(raised: true)
    }

    // Surfaces any goal achievement or personal-best milestone immediately after the score card
    // so it's impossible to miss.
    @ViewBuilder
    private var achievementBanner: some View {
        if let goalText = topAchievedGoalText() {
            achievementCard(
                icon: "trophy.fill",
                color: .warningAmber,
                title: "Goal Achieved!",
                subtitle: goalText
            )
        } else if isPersonalBest {
            achievementCard(
                icon: "star.fill",
                color: .emerald,
                title: "New Personal Best!",
                subtitle: "Lowest score ever for a \(round.holesPlayed)-hole round."
            )
        }
    }

    private func achievementCard(icon: String, color: Color, title: String, subtitle: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon).font(.title3).foregroundStyle(color)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.subheadline.weight(.bold)).foregroundStyle(.textPrimary)
                Text(subtitle).font(.caption).foregroundStyle(.textSecondary)
            }
            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle(raised: true)
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(color.opacity(0.4), lineWidth: 1.5)
        )
    }

    // Returns a description of the highest-tier goal beaten this round,
    // or nil if no profile goal was achieved.
    private func topAchievedGoalText() -> String? {
        guard let profile = round.profile else { return nil }
        let totalPar = round.totalPar
        let totalStrokes = round.totalStrokes
        let isNine = round.holesPlayed <= 9
        let nineHoleGoals: Set<GolfGoal> = [.break50On9, .break45On9, .break40On9, .break36On9]

        // Walk goals in descending ambition so we surface the hardest one beaten.
        let orderedGoals: [GolfGoal] = [
            .break36On9, .break40On9, .break45On9, .break50On9,
            .break80On18, .break90On18, .break100On18
        ]
        for goal in orderedGoals where profile.goals.contains(goal) {
            guard let offset = goalOffset(goal) else { continue }
            guard nineHoleGoals.contains(goal) == isNine else { continue }
            let target = totalPar + offset
            if totalStrokes <= target {
                return "You broke your \(goal.displayName) goal this round."
            }
        }
        return nil
    }

    private func goalOffset(_ goal: GolfGoal) -> Int? {
        switch goal {
        case .break50On9:  return 14
        case .break45On9:  return 9
        case .break40On9:  return 4
        case .break36On9:  return 0
        case .break100On18: return 28
        case .break90On18: return 18
        case .break80On18: return 8
        default: return nil
        }
    }

    private var isPersonalBest: Bool {
        let prior = allRounds.filter {
            $0.profile?.id == round.profile?.id &&
            $0.id != round.id &&
            $0.holesPlayed == round.holesPlayed
        }
        guard !prior.isEmpty else { return false }
        return round.totalStrokes < (prior.map(\.totalStrokes).min() ?? Int.max)
    }

    private var priorRoundsAtThisCourse: [GolfRound] {
        guard let courseID = round.course?.id else { return [] }
        return allRounds.filter {
            $0.id != round.id &&
            $0.course?.id == courseID &&
            $0.profile?.id == round.profile?.id
        }
    }

    private var scoringOpportunityRows: [ScoringOpportunityRow] {
        var rows: [ScoringOpportunityRow] = []

        if stats.totalPenalties > 0 {
            rows.append(ScoringOpportunityRow(
                id: "penalties",
                icon: "exclamationmark.triangle.fill",
                color: .warningAmber,
                title: "Avoid Penalties",
                detail: "\(stats.holesWithPenalties) hole\(stats.holesWithPenalties == 1 ? "" : "s") included penalty strokes. Safer targets can save score fast.",
                badge: "\(stats.totalPenalties)"
            ))
        }

        let excessPutts = stats.holes.reduce(0) { $0 + max(0, $1.putts - 2) }
        if excessPutts > 0 {
            rows.append(ScoringOpportunityRow(
                id: "putting",
                icon: "smallcircle.filled.circle",
                color: .emerald,
                title: "Clean Up Lag Putting",
                detail: "\(stats.threePutts) three-putt hole\(stats.threePutts == 1 ? "" : "s") created extra work. Speed control is the easiest practice target.",
                badge: "\(excessPutts)"
            ))
        }

        let blowUpStrokes = stats.holes.reduce(0) { $0 + max(0, $1.scoreToPar - 1) }
        if blowUpStrokes > 0 {
            rows.append(ScoringOpportunityRow(
                id: "blowups",
                icon: "flame.fill",
                color: .alertCoral,
                title: "Limit Big Numbers",
                detail: "\(stats.blowUpHoles) blow-up hole\(stats.blowUpHoles == 1 ? "" : "s") drove the score up. Play the next shot to remove disaster first.",
                badge: "\(blowUpStrokes)"
            ))
        }

        if let mainMiss = stats.mainMissDirection {
            let missCount = stats.holes.filter { $0.missDirection == mainMiss }.count
            rows.append(ScoringOpportunityRow(
                id: "miss-\(mainMiss.rawValue)",
                icon: "arrow.up.right",
                color: .emerald,
                title: "Manage The \(mainMiss.displayName) Miss",
                detail: "\(missCount) logged miss\(missCount == 1 ? "" : "es") leaned \(mainMiss.displayName.lowercased()). Aim and club decisions should account for that pattern.",
                badge: "\(missCount)"
            ))
        }

        return Array(rows.prefix(3))
    }

    private var courseMemoryRows: [CourseMemoryRow] {
        guard !priorRoundsAtThisCourse.isEmpty else { return [] }

        let pastHolesByNumber = Dictionary(
            grouping: priorRoundsAtThisCourse.flatMap { $0.sortedHoleScores }.filter { $0.strokes > 0 },
            by: \.holeNumber
        )

        let comparisons = stats.holes.compactMap { current -> HoleMemoryComparison? in
            guard current.strokes > 0, let past = pastHolesByNumber[current.holeNumber], !past.isEmpty else {
                return nil
            }
            let average = Double(past.reduce(0) { $0 + $1.scoreToPar }) / Double(past.count)
            let misses = past.map(\.missDirection).filter { $0 != .good && $0 != .na }
            let commonMiss = Dictionary(grouping: misses, by: { $0 }).mapValues(\.count)
                .max(by: { $0.value < $1.value })?.key
            return HoleMemoryComparison(
                holeNumber: current.holeNumber,
                currentScoreToPar: current.scoreToPar,
                averageScoreToPar: average,
                playCount: past.count,
                commonMiss: commonMiss
            )
        }

        guard !comparisons.isEmpty else { return [] }

        var rows: [CourseMemoryRow] = []

        if let improvement = comparisons.min(by: { $0.deltaFromAverage < $1.deltaFromAverage }),
           improvement.deltaFromAverage <= -1 {
            let averageText = scoreToParText(Int(improvement.averageScoreToPar.rounded()))
            rows.append(CourseMemoryRow(
                id: "improvement-\(improvement.holeNumber)",
                holeNumber: improvement.holeNumber,
                icon: "arrow.down.circle.fill",
                color: .emerald,
                title: "Beat Your Usual Hole \(improvement.holeNumber)",
                detail: "Today was \(scoreToParText(improvement.currentScoreToPar)); your course average there is \(averageText).",
                priority: 0
            ))
        }

        if let costly = comparisons.max(by: { $0.deltaFromAverage < $1.deltaFromAverage }),
           costly.deltaFromAverage >= 1 {
            let extraStrokes = Int(costly.deltaFromAverage.rounded())
            rows.append(CourseMemoryRow(
                id: "costly-\(costly.holeNumber)",
                holeNumber: costly.holeNumber,
                icon: "exclamationmark.triangle.fill",
                color: .warningAmber,
                title: "Hole \(costly.holeNumber) Cost Extra Today",
                detail: "You were \(extraStrokes) stroke\(extraStrokes == 1 ? "" : "s") worse than your usual result there.",
                priority: 1
            ))
        }

        if let toughest = comparisons.max(by: { $0.averageScoreToPar < $1.averageScoreToPar }) {
            var detail = "Across \(toughest.playCount) previous round\(toughest.playCount == 1 ? "" : "s"), you average \(scoreToParText(Int(toughest.averageScoreToPar.rounded()))) on this hole."
            if let miss = toughest.commonMiss {
                detail += " Common miss: \(miss.displayName)."
            }
            rows.append(CourseMemoryRow(
                id: "toughest-\(toughest.holeNumber)",
                holeNumber: toughest.holeNumber,
                icon: "map.fill",
                color: .emerald,
                title: "Remember Hole \(toughest.holeNumber)",
                detail: detail,
                priority: 2
            ))
        }

        return Array(uniqueRows(rows).sorted { $0.priority < $1.priority }.prefix(3))
    }

    private func uniqueRows(_ rows: [CourseMemoryRow]) -> [CourseMemoryRow] {
        var seenHoles: Set<Int> = []
        return rows.filter { row in
            guard !seenHoles.contains(row.holeNumber) else { return false }
            seenHoles.insert(row.holeNumber)
            return true
        }
    }

    private var quickStatsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            MetricTile(title: "Putts", value: "\(stats.totalPutts)", icon: "circle.dotted")
            MetricTile(title: "Penalties", value: "\(stats.totalPenalties)", icon: "exclamationmark.triangle.fill", tint: .warningAmber)
            MetricTile(title: "Avg / Hole", value: String(format: "%.1f", stats.averageStrokesPerHole), icon: "chart.bar.fill")
            if let fairway = stats.fairwayHitPercentage {
                MetricTile(title: "Fairways Hit", value: "\(Int(fairway))%", icon: "arrow.up", info: "Percent of tee shots on par 4s/5s that landed in the fairway this round.")
            }
            if let gir = stats.girPercentage {
                MetricTile(title: "Greens in Reg.", value: "\(Int(gir))%", icon: "target", info: "Greens in Regulation — reaching the green in par minus 2 strokes (e.g. your 1st shot on a par 3, 2nd on a par 4, 3rd on a par 5).")
            }
            MetricTile(title: "Avg Putts", value: String(format: "%.1f", stats.averagePuttsPerHole), icon: "circle.dotted")
        }
    }

    private var scoringBreakdown: some View {
        ScoringDistributionBar(
            birdiesOrBetter: stats.birdiesOrBetter,
            pars: stats.pars,
            bogeys: stats.bogeys,
            doublesOrWorse: stats.doubleBogeys + stats.triplesOrWorse
        )
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
            SectionHeader(title: "Patterns", icon: "waveform.path.ecg", info: "The holes and shots from this round that show a recurring issue, like three-putting or a consistent miss direction.")
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
                SectionHeader(
                    title: "Club Performance",
                    icon: "figure.golf",
                    info: "Best/Most Problematic are ranked by percentage of good shots with that club this round, not raw totals."
                )
                StatRow(label: "Most Used Club", value: stats.mostUsedClub?.displayName ?? "—")
                StatRow(label: "Best Performing Club", value: stats.bestPerformingClub?.displayName ?? "—", valueColor: .emerald)
                StatRow(label: "Most Problematic Club", value: stats.mostProblematicClub?.displayName ?? "—")
            }
            .cardStyle()
        }
    }
}

private struct HoleMemoryComparison {
    let holeNumber: Int
    let currentScoreToPar: Int
    let averageScoreToPar: Double
    let playCount: Int
    let commonMiss: MissDirection?

    var deltaFromAverage: Double {
        Double(currentScoreToPar) - averageScoreToPar
    }
}

private struct CourseMemoryRow: Identifiable {
    let id: String
    let holeNumber: Int
    let icon: String
    let color: Color
    let title: String
    let detail: String
    let priority: Int
}

private struct ScoringOpportunityRow: Identifiable {
    let id: String
    let icon: String
    let color: Color
    let title: String
    let detail: String
    let badge: String
}
