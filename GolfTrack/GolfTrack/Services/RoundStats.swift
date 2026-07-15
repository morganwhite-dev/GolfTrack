import Foundation

/// Computed, non-persisted aggregate stats for a single round. Shared by Round Summary,
/// History/Round Detail, and the Advice/Practice Plan generators so the numbers are
/// calculated exactly once and stay consistent across screens.
struct RoundStats {
    let round: GolfRound
    /// Sorted once at init — avoids re-sorting on every property access.
    let holes: [HoleScore]

    init(round: GolfRound) {
        self.round = round
        self.holes = (round.holeScores ?? []).sorted { $0.holeNumber < $1.holeNumber }
    }

    var courseName: String { round.course?.name ?? "Round" }
    var date: Date { round.date }
    var holesPlayed: Int { round.holesPlayed }
    var totalStrokes: Int { holes.reduce(0) { $0 + $1.strokes } }
    var totalPar: Int { holes.reduce(0) { $0 + $1.par } }
    var scoreToPar: Int { totalStrokes - totalPar }
    var totalPutts: Int { holes.reduce(0) { $0 + $1.putts } }
    var totalPenalties: Int { holes.reduce(0) { $0 + $1.penalties } }

    var averageStrokesPerHole: Double {
        holes.isEmpty ? 0 : Double(totalStrokes) / Double(holes.count)
    }
    var averagePuttsPerHole: Double {
        holes.isEmpty ? 0 : Double(totalPutts) / Double(holes.count)
    }

    var fairwayHitPercentage: Double? {
        let applicable = holes.filter { $0.fairwayHit != .na }
        guard !applicable.isEmpty else { return nil }
        return Double(applicable.filter { $0.fairwayHit == .yes }.count) / Double(applicable.count) * 100
    }

    var girPercentage: Double? {
        let applicable = holes.filter { $0.greenInRegulation != .na }
        guard !applicable.isEmpty else { return nil }
        return Double(applicable.filter { $0.greenInRegulation == .yes }.count) / Double(applicable.count) * 100
    }

    var birdiesOrBetter: Int { holes.filter { $0.scoreToPar < 0 }.count }
    var pars: Int { holes.filter { $0.scoreToPar == 0 }.count }
    var bogeys: Int { holes.filter { $0.scoreToPar == 1 }.count }
    var doubleBogeys: Int { holes.filter { $0.scoreToPar == 2 }.count }
    var triplesOrWorse: Int { holes.filter { $0.scoreToPar >= 3 }.count }

    var bestHole: HoleScore? { holes.filter { $0.strokes > 0 }.min { $0.scoreToPar < $1.scoreToPar } }
    var worstHole: HoleScore? { holes.filter { $0.strokes > 0 }.max { $0.scoreToPar < $1.scoreToPar } }

    var holesWithPenalties: Int { holes.filter { $0.penalties > 0 }.count }
    var threePutts: Int { holes.filter { $0.isThreePutt }.count }
    var blowUpHoles: Int { holes.filter { $0.isBlowUp }.count }

    var mainMissDirection: MissDirection? {
        let misses = holes.map(\.missDirection).filter { $0 != .good && $0 != .na }
        guard !misses.isEmpty else { return nil }
        let counts = Dictionary(grouping: misses, by: { $0 }).mapValues(\.count)
        return counts.max(by: { $0.value < $1.value })?.key
    }

    var allClubShots: [ClubShot] { holes.flatMap { $0.clubShots ?? [] } }

    struct ClubTally { var uses = 0; var good = 0; var bad = 0 }

    var clubTallies: [ClubType: ClubTally] {
        var tallies: [ClubType: ClubTally] = [:]
        for shot in allClubShots {
            var tally = tallies[shot.club] ?? ClubTally()
            tally.uses += 1
            if shot.result == .good || shot.result == .safeMiss {
                tally.good += 1
            } else {
                tally.bad += 1
            }
            tallies[shot.club] = tally
        }
        return tallies
    }

    var mostUsedClub: ClubType? {
        clubTallies.max(by: { $0.value.uses < $1.value.uses })?.key
    }

    var bestPerformingClub: ClubType? {
        clubTallies.filter { $0.value.uses > 0 }
            .max(by: { Double($0.value.good) / Double($0.value.uses) < Double($1.value.good) / Double($1.value.uses) })?.key
    }

    var mostProblematicClub: ClubType? {
        clubTallies.filter { $0.value.uses > 0 }
            .min(by: { Double($0.value.good) / Double($0.value.uses) < Double($1.value.good) / Double($1.value.uses) })?.key
    }

    var targetComparison: Int? {
        guard let target = round.targetScore else { return nil }
        return totalStrokes - target  // totalStrokes uses cached holes
    }
}
