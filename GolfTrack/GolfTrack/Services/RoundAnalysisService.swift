import Foundation

enum RoundAnalysisService {
    /// Break-X goals are named after what they'd mean on a standard course (par 36 for 9,
    /// par 72 for 18); this offset is added to the round's real course par to get the
    /// actual target for that round. See project-goal-scaling-design memory.
    private static func goalOffset(_ goal: GolfGoal) -> Int? {
        switch goal {
        case .break50On9: return 14
        case .break45On9: return 9
        case .break40On9: return 4
        case .break36On9: return 0
        case .break100On18: return 28
        case .break90On18: return 18
        case .break80On18: return 8
        default: return nil
        }
    }

    private static let nineHoleGoals: Set<GolfGoal> = [.break50On9, .break45On9, .break40On9, .break36On9]

    /// Picks the most relevant reference score to grade the round against: an explicit
    /// per-round target if set, else whichever selected goal the round actually lands
    /// closest to, else just the course par.
    private static func referenceTarget(round: GolfRound, profile: UserProfile?) -> Int {
        if let target = round.targetScore { return target }
        guard let profile else { return round.totalPar }
        let isNine = round.holesPlayed <= 9
        let offsets = profile.goals.compactMap { goal -> Int? in
            guard let offset = goalOffset(goal) else { return nil }
            return nineHoleGoals.contains(goal) == isNine ? offset : nil
        }
        guard !offsets.isEmpty else { return round.totalPar }
        let best = offsets.min(by: { abs(round.totalStrokes - (round.totalPar + $0)) < abs(round.totalStrokes - (round.totalPar + $1)) })!
        return round.totalPar + best
    }

    private static func toleranceBand(for skillLevel: SkillLevel) -> (close: Int, tough: Int) {
        switch skillLevel {
        case .beginner, .highHandicap: return (10, 20)
        case .midHandicap: return (7, 15)
        case .lowHandicap: return (5, 12)
        case .scratch: return (3, 8)
        }
    }

    static func generateAdvice(round: GolfRound, stats: RoundStats, profile: UserProfile?) -> RoundAdvice {
        let target = referenceTarget(round: round, profile: profile)
        let skillLevel = profile?.skillLevel ?? .beginner
        let isBeginner = skillLevel == .beginner || skillLevel == .highHandicap
        return generateAdvice(round: round, stats: stats, target: target, skillLevel: skillLevel, isBeginner: isBeginner)
    }

    private static func generateAdvice(round: GolfRound, stats: RoundStats, target: Int, skillLevel: SkillLevel, isBeginner: Bool) -> RoundAdvice {
        let diff = stats.totalStrokes - target
        let tolerance = toleranceBand(for: skillLevel)

        let rating: RoundRating
        switch diff {
        case ..<(-2): rating = .great
        case -2...2: rating = .solid
        case 3...tolerance.close: rating = .closeToGoal
        case (tolerance.close + 1)...(tolerance.close * 2): rating = .average
        case (tolerance.close * 2 + 1)...tolerance.tough: rating = .needsWork
        default: rating = .tough
        }

        let issues = issueCandidates(stats: stats, reflection: round.reflection, isBeginner: isBeginner)
        let strengths = strengthCandidates(stats: stats)

        let advice = RoundAdvice(roundId: round.id, rating: rating)
        advice.strengths = Array(padded(strengths, to: 3, with: "Keep logging rounds — more data means sharper advice over time."))
        advice.improvementAreas = Array(padded(issues, to: 3, with: "No major recurring issue — focus on consistency."))
        advice.mainIssue = issues.first ?? "Nothing stands out as a major issue — that's a solid, consistent round."
        advice.secondaryIssue = issues.count > 1 ? issues[1] : "No clear secondary issue today."
        advice.bestPart = strengths.first ?? "You completed the round — that's useful data either way."
        advice.nextRoundGoal = nextRoundGoal(stats: stats, diff: diff, target: target)
        return advice
    }

    private static func padded(_ items: [String], to count: Int, with filler: String) -> [String] {
        var result = Array(items.prefix(count))
        while result.count < count { result.append(filler) }
        return result
    }

    private static func issueCandidates(stats: RoundStats, reflection: RoundReflection?, isBeginner: Bool) -> [String] {
        var issues: [String] = []

        if stats.threePutts >= 2 || reflection?.puttingFeel == .poor {
            issues.append("Three-putts were the biggest drag on your score today.")
        }
        if stats.totalPenalties >= 3 || stats.holesWithPenalties >= 2 {
            issues.append("Penalty strokes added up and cost you several shots.")
        }
        let poorContactHoles = stats.holes.filter { $0.contactQuality == .poor || $0.contactQuality == .okay || $0.shotIssue != .none }.count
        if stats.holes.count > 0 && Double(poorContactHoles) / Double(stats.holes.count) >= 0.4 {
            issues.append("Contact was inconsistent — a lot of thin, fat, or mis-hit shots.")
        }
        if stats.blowUpHoles >= 2 || reflection?.hadMentalMistakes == true {
            issues.append(isBeginner
                ? "A couple of big-number holes inflated your score — the rest of your round was better than the total suggests."
                : "Blow-up holes cost you more than your bad shots alone would have.")
        }
        if let direction = stats.mainMissDirection {
            issues.append("Misses leaned mostly \(direction.displayName.lowercased()) today, which is worth tracking.")
        }
        if let club = stats.mostProblematicClub, let tally = stats.clubTallies[club], tally.bad >= 2 {
            issues.append("Your \(club.displayName) caused the most missed shots today.")
        }
        return issues
    }

    private static func strengthCandidates(stats: RoundStats) -> [String] {
        var strengths: [String] = []
        if let fairway = stats.fairwayHitPercentage, fairway >= 60 {
            strengths.append("Good fairway accuracy off the tee.")
        }
        if let gir = stats.girPercentage, gir >= 40 {
            strengths.append("Solid greens in regulation.")
        }
        if stats.averagePuttsPerHole <= 1.8 && stats.threePutts == 0 {
            strengths.append("Strong, consistent putting today.")
        }
        if stats.totalPenalties == 0 {
            strengths.append("No penalty strokes — good course management.")
        }
        if let club = stats.bestPerformingClub, let tally = stats.clubTallies[club], tally.uses >= 2, tally.good == tally.uses {
            strengths.append("Your \(club.displayName) was reliable today — that may be a scoring club for you.")
        }
        if stats.scoreToPar <= 0 {
            strengths.append("You shot par or better — that's a great round.")
        }
        return strengths
    }

    private static func nextRoundGoal(stats: RoundStats, diff: Int, target: Int) -> String {
        if stats.threePutts >= 2 {
            return "No more than one three-putt next round."
        }
        let shortMisses = stats.holes.filter { $0.missDirection == .short }.count
        if shortMisses >= 3 {
            return "Choose enough club to avoid leaving shots short."
        }
        let rightMisses = stats.holes.filter { $0.missDirection == .right }.count
        if rightMisses >= 3 {
            return "Pick a clear target and track your start line on full swings."
        }
        let poorContactHoles = stats.holes.filter { $0.contactQuality == .poor || $0.contactQuality == .okay }.count
        if stats.holes.count > 0 && Double(poorContactHoles) / Double(stats.holes.count) >= 0.4 {
            return "Make solid contact on at least half of your full swings."
        }
        if stats.totalPenalties >= 2 {
            return "Avoid penalty strokes — play away from trouble off the tee."
        }
        if diff > 0 {
            return "Get within \(diff - 1 >= 0 ? diff - 1 : 0) strokes of your target next time."
        }
        return "Keep building on this round — track your stats and stay consistent."
    }
}
