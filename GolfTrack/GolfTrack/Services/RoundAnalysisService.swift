import Foundation

// Simple keyword signals extracted from a round's written reflection and hole notes.
// Used by both RoundAnalysisService and PracticePlanService so advice actually
// reflects what the player wrote, not just what the stats caught.
struct TextSignals {
    var wantsToImprovePutting   = false
    var wantsToImproveContact   = false
    var wantsToImproveDistance  = false
    var wantsToImproveDriver    = false
    var wantsToImproveWedge     = false
    var wantsToImproveIrons     = false
    var wantsToImproveMental    = false
    var wantsToImproveShortGame = false
    var feltBestAboutPutting    = false
    var feltBestAboutDriver     = false
    var feltBestAboutIrons      = false
    var frustratedWithPutting   = false
    var holeNotePuttingHoles: [Int] = []
    var holeNoteContactHoles: [Int] = []
    var holeNoteDistanceHoles: [Int] = []
    var holeNoteDriverHoles: [Int] = []
    var holeNoteWedgeHoles: [Int] = []
    var holeNoteMentalHoles: [Int] = []
    var holeNoteShortGameHoles: [Int] = []
}

enum RoundAnalysisService {
    /// Scans the round's reflection, mental note, and per-hole notes for golf-specific
    /// keywords so generated advice reflects what the player actually wrote down.
    static func extractTextSignals(from round: GolfRound) -> TextSignals {
        extractTextSignals(from: round.reflection, holes: round.sortedHoleScores)
    }

    /// Scans the round's post-round reflection fields for golf-specific keywords
    /// and builds a signal map that the analysis services use to personalise advice.
    static func extractTextSignals(from reflection: RoundReflection?) -> TextSignals {
        extractTextSignals(from: reflection, holes: [])
    }

    private static func extractTextSignals(from reflection: RoundReflection?, holes: [HoleScore]) -> TextSignals {
        var s = TextSignals()

        let putting  = ["putt", "putting", "3-putt", "three putt", "three-putt", "lag putt", "speed control"]
        let driver   = ["driver", "off the tee", "tee shot", "tee shots", "driving", "off tee"]
        let irons    = ["iron", "irons", "ball striking", "ball-striking", "approach shot"]
        let wedge    = ["wedge", "wedges", "pitching", "short iron", "pitch shot"]
        let contact  = ["contact", "solid contact", "thin", "fat", "chunk", "chunked", "topped", "topping"]
        let mental   = ["mental", "focus", "routine", "composure", "confidence", "rush", "rushed", "anxiety", "calm"]
        let distance = ["distance", "yardage", "club selection", "underclub", "overclub", "too short", "too long", "know my distances"]
        let shortG   = ["chip", "chipping", "short game", "around the green", "pitch shot", "bump and run"]

        func has(_ text: String, _ keywords: [String]) -> Bool {
            keywords.contains { text.contains($0) }
        }

        let best = reflection?.feltBestText.lowercased() ?? ""
        let frust = reflection?.frustratedText.lowercased() ?? ""
        let improve = reflection?.improveNextText.lowercased() ?? ""
        let mentalNote = reflection?.mentalMistakesNote.lowercased() ?? ""
        let holeNotes = holes.map { ($0.holeNumber, $0.notes.lowercased()) }.filter { !$0.1.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        let concernText = [frust, improve, mentalNote, holeNotes.map { $0.1 }.joined(separator: " ")].joined(separator: " ")

        s.feltBestAboutPutting  = has(best, putting)
        s.feltBestAboutDriver   = has(best, driver)
        s.feltBestAboutIrons    = has(best, irons)
        s.frustratedWithPutting = has(concernText, putting)

        // "Wants to improve" fires from reflection text, mental notes, or per-hole notes.
        s.wantsToImprovePutting   = has(concernText, putting)
        s.wantsToImproveContact   = has(concernText, contact)
        s.wantsToImproveDistance  = has(concernText, distance)
        s.wantsToImproveDriver    = has(concernText, driver)
        s.wantsToImproveWedge     = has(concernText, wedge)
        s.wantsToImproveIrons     = has(concernText, irons)
        s.wantsToImproveMental    = has(concernText, mental)
        s.wantsToImproveShortGame = has(concernText, shortG)

        s.holeNotePuttingHoles = holeNotes.filter { has($0.1, putting) }.map { $0.0 }
        s.holeNoteContactHoles = holeNotes.filter { has($0.1, contact) }.map { $0.0 }
        s.holeNoteDistanceHoles = holeNotes.filter { has($0.1, distance) }.map { $0.0 }
        s.holeNoteDriverHoles = holeNotes.filter { has($0.1, driver) }.map { $0.0 }
        s.holeNoteWedgeHoles = holeNotes.filter { has($0.1, wedge) }.map { $0.0 }
        s.holeNoteMentalHoles = holeNotes.filter { has($0.1, mental) }.map { $0.0 }
        s.holeNoteShortGameHoles = holeNotes.filter { has($0.1, shortG) }.map { $0.0 }

        return s
    }

    // MARK: - Internal helpers

    /// Break-X goals are named after standard par (36/9 or 72/18);
    /// this offset is added to the round's real course par to get the actual target.
    private static func goalOffset(_ goal: GolfGoal) -> Int? {
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

    private static let nineHoleGoals: Set<GolfGoal> = [.break50On9, .break45On9, .break40On9, .break36On9]

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
        case .midHandicap:             return (7, 15)
        case .lowHandicap:             return (5, 12)
        case .scratch:                 return (3, 8)
        }
    }

    // MARK: - Public entry point

    static func generateAdvice(round: GolfRound, stats: RoundStats, profile: UserProfile?) -> RoundAdvice {
        let target     = referenceTarget(round: round, profile: profile)
        let skillLevel = profile?.skillLevel ?? .beginner
        let isBeginner = skillLevel == .beginner || skillLevel == .highHandicap
        return generateAdvice(round: round, stats: stats, target: target, skillLevel: skillLevel, isBeginner: isBeginner)
    }

    private static func generateAdvice(round: GolfRound, stats: RoundStats, target: Int, skillLevel: SkillLevel, isBeginner: Bool) -> RoundAdvice {
        let diff       = stats.totalStrokes - target
        let tolerance  = toleranceBand(for: skillLevel)
        let signals    = extractTextSignals(from: round)

        let rating: RoundRating
        switch diff {
        case ..<(-2):                            rating = .great
        case -2...2:                             rating = .solid
        case 3...tolerance.close:               rating = .closeToGoal
        case (tolerance.close + 1)...(tolerance.close * 2): rating = .average
        case (tolerance.close * 2 + 1)...tolerance.tough:   rating = .needsWork
        default:                                 rating = .tough
        }

        let issues    = issueCandidates(stats: stats, reflection: round.reflection, signals: signals, isBeginner: isBeginner)
        let strengths = strengthCandidates(stats: stats, reflection: round.reflection, signals: signals)

        let advice = RoundAdvice(roundId: round.id, rating: rating)
        advice.strengths        = Array(padded(strengths, to: 3, with: "Keep logging rounds — more data means sharper advice over time."))
        advice.improvementAreas = Array(padded(issues,    to: 3, with: "No major recurring issue — focus on consistency."))
        advice.mainIssue        = issues.first   ?? "Nothing stands out as a major issue — that's a solid, consistent round."
        advice.secondaryIssue   = issues.count > 1 ? issues[1] : "No clear secondary issue today."
        advice.bestPart         = strengths.first ?? "You completed the round — that's useful data either way."
        advice.nextRoundGoal    = nextRoundGoal(stats: stats, diff: diff, target: target, signals: signals)
        return advice
    }

    private static func padded(_ items: [String], to count: Int, with filler: String) -> [String] {
        var result = Array(items.prefix(count))
        while result.count < count { result.append(filler) }
        return result
    }

    // MARK: - Issue candidates

    private static func issueCandidates(
        stats: RoundStats,
        reflection: RoundReflection?,
        signals: TextSignals,
        isBeginner: Bool
    ) -> [String] {
        var issues: [String] = []

        // Stats + feel combined
        if stats.threePutts >= 2 || reflection?.puttingFeel == .poor || signals.frustratedWithPutting {
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
            issues.append("Misses leaned mostly \(direction.displayName.lowercased()) today — worth tracking.")
        }
        if let club = stats.mostProblematicClub, let tally = stats.clubTallies[club], tally.bad >= 2 {
            issues.append("Your \(club.displayName) caused the most missed shots today.")
        }

        // Text-signal derived issues — only add if the player's own words flag something
        // the stats didn't catch and we still have room in the list.
        func alreadyMentions(_ keyword: String) -> Bool {
            issues.contains { $0.lowercased().contains(keyword) }
        }
        if signals.wantsToImprovePutting && !alreadyMentions("putt") {
            issues.append("You flagged your putting in your notes — that kind of self-awareness is exactly what to act on.")
        }
        if signals.wantsToImproveWedge && !alreadyMentions("wedge") {
            issues.append("Your notes mention the wedge game — distance control with short clubs is high-value practice time.")
        }
        if signals.wantsToImproveContact && !alreadyMentions("contact") {
            issues.append("You noted wanting better contact — a slower tempo and balanced finish usually fix this.")
        }
        if signals.wantsToImproveDistance && !alreadyMentions("distance") {
            issues.append("You flagged distance control — knowing your real carry distances per club is foundational.")
        }
        if signals.wantsToImproveMental && !alreadyMentions("mental") && !alreadyMentions("focus") {
            issues.append("You called out the mental side — a consistent pre-shot routine addresses this directly.")
        }
        if !signals.holeNoteContactHoles.isEmpty && !alreadyMentions("contact") {
            issues.append("Your hole notes mention contact issues on \(holeList(signals.holeNoteContactHoles)) — that pattern is worth targeted range work.")
        }
        if !signals.holeNoteDriverHoles.isEmpty && !alreadyMentions("tee") && !alreadyMentions("driver") {
            issues.append("Your hole notes point back to tee shots on \(holeList(signals.holeNoteDriverHoles)) — start line and target choice deserve attention.")
        }
        if !signals.holeNoteWedgeHoles.isEmpty && !alreadyMentions("wedge") {
            issues.append("Your hole notes mention wedges on \(holeList(signals.holeNoteWedgeHoles)) — distance control with scoring clubs can save quick strokes.")
        }
        if !signals.holeNoteMentalHoles.isEmpty && !alreadyMentions("mental") && !alreadyMentions("focus") {
            issues.append("Your hole notes mention focus or routine on \(holeList(signals.holeNoteMentalHoles)) — build a reset before each shot.")
        }

        return issues
    }

    // MARK: - Strength candidates

    private static func strengthCandidates(
        stats: RoundStats,
        reflection: RoundReflection?,
        signals: TextSignals
    ) -> [String] {
        var strengths: [String] = []

        // Avoid praising an area the player themselves felt was poor.
        if let fairway = stats.fairwayHitPercentage, fairway >= 60,
           reflection?.teeShotFeel != .poor {
            strengths.append("Good fairway accuracy off the tee.")
        }
        if let gir = stats.girPercentage, gir >= 40,
           reflection?.ironPlayFeel != .poor {
            strengths.append("Solid greens in regulation.")
        }
        // Don't call putting a strength if the player felt it was poor or if they
        // were frustrated with it — their first-hand read beats the averages.
        if stats.averagePuttsPerHole <= 1.8 && stats.threePutts == 0
            && reflection?.puttingFeel != .poor
            && !signals.frustratedWithPutting {
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

        // Text-signal derived strengths — honour what the player wrote.
        func alreadyMentions(_ keyword: String) -> Bool {
            strengths.contains { $0.lowercased().contains(keyword) }
        }
        if signals.feltBestAboutDriver && !alreadyMentions("tee") && !alreadyMentions("fairway") {
            strengths.append("Your notes say tee shots felt good — a clean ball-flight sets up the whole hole.")
        }
        if signals.feltBestAboutIrons && !alreadyMentions("iron") && !alreadyMentions("approach") && !alreadyMentions("green") {
            strengths.append("Your notes say iron play felt solid — that's the foundation of consistent scoring.")
        }
        if signals.feltBestAboutPutting && !alreadyMentions("putt") && reflection?.puttingFeel != .poor {
            strengths.append("Your notes say putting felt good — trust that tempo going into the next round.")
        }

        return strengths
    }

    // MARK: - Next round goal

    private static func nextRoundGoal(stats: RoundStats, diff: Int, target: Int, signals: TextSignals) -> String {
        // Honour the player's stated improvement area first — it's the most specific signal.
        if signals.wantsToImprovePutting  { return "No more than one three-putt next round — commit to your speed before each putt." }
        if signals.wantsToImproveDistance { return "Know your carry distances — commit to a full swing with each club at the range." }
        if signals.wantsToImproveWedge    { return "Dial in your wedge distances before you play — 50/75/100 yard targets at the range." }
        if signals.wantsToImproveContact  { return "Focus on a balanced finish — if you're in balance at the end, contact cleans up." }
        if signals.wantsToImproveDriver   { return "Pick a specific landing zone off the tee, not just 'hit it far' — commit to it." }
        if signals.wantsToImproveIrons    { return "Spend extra time on iron shots from 100–150 yards — your most common approach range." }
        if signals.wantsToImproveMental   { return "Set a pre-shot routine and stick to it on every shot next round — one shot at a time." }
        if signals.wantsToImproveShortGame { return "Chip to a specific landing spot, not just 'near the hole' — be precise with short game." }

        // Fall back to stats-based goal
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
            return "Get within \(max(0, diff - 1)) strokes of your target next time."
        }
        return "Keep building on this round — track your stats and stay consistent."
    }

    private static func holeList(_ holes: [Int]) -> String {
        let unique = Array(Set(holes)).sorted()
        guard !unique.isEmpty else { return "your notes" }
        let labels = unique.prefix(3).map { "hole \($0)" }
        if unique.count > 3 {
            return labels.joined(separator: ", ") + ", and others"
        }
        return labels.joined(separator: ", ")
    }
}
