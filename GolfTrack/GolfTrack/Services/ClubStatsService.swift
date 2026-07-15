import Foundation
import SwiftData

/// Recomputes the persisted ClubStats rows from scratch using every ClubShot across all of one
/// profile's completed rounds. Called after a round finishes so club stats always reflect full
/// history — scoped to a single profile so multiple local profiles never mix each other's stats.
enum ClubStatsService {
    static func recompute(for profile: UserProfile, in context: ModelContext) {
        guard let allRounds = try? context.fetch(FetchDescriptor<GolfRound>(predicate: #Predicate { $0.isComplete })) else { return }
        let rounds = allRounds.filter { $0.profile?.id == profile.id }
        let allShots = rounds.flatMap { round in (round.holeScores ?? []).flatMap { $0.clubShots ?? [] } }

        let allExisting = try? context.fetch(FetchDescriptor<ClubStats>())
        let existing = (allExisting ?? []).filter { $0.profile?.id == profile.id }
        var statsByClub: [ClubType: ClubStats] = [:]
        for stat in existing {
            stat.timesUsed = 0
            stat.goodShots = 0
            stat.badShots = 0
            stat.missLeft = 0
            stat.missRight = 0
            stat.missShort = 0
            stat.missLong = 0
            stat.fatShots = 0
            stat.thinShots = 0
            stat.toppedShots = 0
            stat.chunkedShots = 0
            stat.averageConfidence = 0
            statsByClub[stat.club] = stat
        }

        var confidenceSums: [ClubType: (sum: Double, count: Int)] = [:]

        for shot in allShots {
            let club = shot.club
            let stat: ClubStats
            if let found = statsByClub[club] {
                stat = found
            } else {
                let new = ClubStats(club: club)
                new.profile = profile
                context.insert(new)
                statsByClub[club] = new
                stat = new
            }

            stat.timesUsed += 1
            switch shot.result {
            case .good, .safeMiss: stat.goodShots += 1
            default: stat.badShots += 1
            }
            switch shot.result {
            case .left: stat.missLeft += 1
            case .right: stat.missRight += 1
            case .short: stat.missShort += 1
            case .long: stat.missLong += 1
            case .fat: stat.fatShots += 1
            case .thin: stat.thinShots += 1
            case .topped: stat.toppedShots += 1
            case .chunked: stat.chunkedShots += 1
            default: break
            }

            if let confidence = shot.confidence {
                let value: Double = confidence == .high ? 3 : (confidence == .medium ? 2 : 1)
                var entry = confidenceSums[club] ?? (sum: 0, count: 0)
                entry.sum += value
                entry.count += 1
                confidenceSums[club] = entry
            }
            stat.lastUpdated = Date()
        }

        for (club, entry) in confidenceSums where entry.count > 0 {
            statsByClub[club]?.averageConfidence = entry.sum / Double(entry.count)
        }

        try? context.save()
    }
}
