import Foundation
import SwiftData

enum StorageService {
    static var schema: Schema {
        LiveActivityRoundStore.schema
    }

    static func makeModelContainer() -> ModelContainer {
        LiveActivityRoundStore.makeModelContainer()
    }

    /// Seeds a couple of example courses on first launch so Start Round and Course Search
    /// are never empty, even before the user adds their own course or a search API key is set.
    static func seedIfNeeded(context: ModelContext) {
        let existing = try? context.fetch(FetchDescriptor<GolfCourse>())
        guard (existing ?? []).isEmpty else { return }

        let par3 = GolfCourse(name: "Wendell Coffee Golf & Event Center", location: "Local", courseType: .par3, numberOfHoles: 9)
        par3.isCustom = false
        for i in 1...9 {
            context.insert(GolfHole(holeNumber: i, par: 3, yardage: nil) .with { $0.course = par3 })
        }

        let standard = GolfCourse(name: "Sample Standard Course", location: "Local", courseType: .standard, numberOfHoles: 18)
        standard.isCustom = false
        let pars18 = [4,4,3,5,4,4,3,5,4, 4,3,5,4,4,3,5,4,4]
        for (i, par) in pars18.enumerated() {
            context.insert(GolfHole(holeNumber: i + 1, par: par, yardage: nil).with { $0.course = standard })
        }

        context.insert(par3)
        context.insert(standard)
        try? context.save()
    }
}

#if DEBUG
/// TEMPORARY, debug-only sample data so the new UI can be visually tested without playing
/// real rounds first. Stripped from any non-debug build automatically; delete this whole
/// extension once real round data makes it unnecessary.
extension StorageService {
    static func seedSampleRoundsIfNeeded(context: ModelContext) {
        let existingRounds = try? context.fetch(FetchDescriptor<GolfRound>(predicate: #Predicate<GolfRound> { $0.isComplete }))
        guard (existingRounds ?? []).isEmpty else { return }
        guard let course = (try? context.fetch(FetchDescriptor<GolfCourse>()))?.first(where: { $0.numberOfHoles == 9 }) else { return }
        guard let profile = try? context.fetch(FetchDescriptor<UserProfile>()).first else { return }

        struct HoleSeed {
            let strokes: Int, putts: Int, penalties: Int
            let club: ClubType, miss: MissDirection, contact: ContactQuality, confidence: Confidence
        }
        struct ReflectionSeed {
            let teeShot: FeelRating, iron: FeelRating, wedge: FeelRating, shortGame: FeelRating, putting: FeelRating
            let biggestMiss: BiggestMiss, mentalMistake: Bool, mentalNote: String
            let best: String, frustrated: String, improve: String
        }

        func teeResult(for miss: MissDirection) -> ShotResult {
            switch miss {
            case .good: return .good
            case .left: return .left
            case .right: return .right
            case .short: return .short
            case .long: return .long
            case .na: return .good
            }
        }

        func makeRound(daysAgo: Int, holes: [HoleSeed], reflection: ReflectionSeed) {
            let date = Calendar.current.date(byAdding: .day, value: -daysAgo, to: Date()) ?? Date()
            let round = GolfRound(course: course, date: date, holesPlayed: holes.count)
            round.isComplete = true
            round.profile = profile

            var scores: [HoleScore] = []
            for (index, seed) in holes.enumerated() {
                let score = HoleScore(holeNumber: index + 1, par: 3)
                score.strokes = seed.strokes
                score.putts = seed.putts
                score.penalties = seed.penalties
                score.teeClub = seed.club
                score.missDirection = seed.miss
                score.contactQuality = seed.contact
                score.confidence = seed.confidence
                score.fairwayHit = .na
                score.greenInRegulation = (seed.miss == .good && seed.contact != .poor) ? .yes : .no
                score.teeShotResult = teeResult(for: seed.miss)
                score.round = round
                context.insert(score)

                let shot = ClubShot(club: seed.club, shotType: .teeShot, result: teeResult(for: seed.miss))
                shot.contactQuality = seed.contact
                shot.confidence = seed.confidence
                shot.holeScore = score
                context.insert(shot)
                score.clubShots = [shot]

                scores.append(score)
            }
            round.holeScores = scores

            let refl = RoundReflection()
            refl.teeShotFeel = reflection.teeShot
            refl.ironPlayFeel = reflection.iron
            refl.wedgePlayFeel = reflection.wedge
            refl.shortGameFeel = reflection.shortGame
            refl.puttingFeel = reflection.putting
            refl.biggestMiss = reflection.biggestMiss
            refl.hadMentalMistakes = reflection.mentalMistake
            refl.mentalMistakesNote = reflection.mentalNote
            refl.feltBestText = reflection.best
            refl.frustratedText = reflection.frustrated
            refl.improveNextText = reflection.improve
            context.insert(refl)
            round.reflection = refl

            context.insert(round)
            try? context.save()

            let stats = RoundStats(round: round)
            let advice = RoundAnalysisService.generateAdvice(round: round, stats: stats, profile: profile)
            round.advice = advice
            context.insert(advice)
            let plan = PracticePlanService.generatePlan(round: round, stats: stats, advice: advice)
            round.practicePlan = plan
            context.insert(plan)
            for drill in plan.recommendedDrills ?? [] { context.insert(drill) }
            try? context.save()
        }

        makeRound(daysAgo: 24, holes: [
            HoleSeed(strokes: 5, putts: 3, penalties: 0, club: .iron7, miss: .short, contact: .poor, confidence: .low),
            HoleSeed(strokes: 4, putts: 2, penalties: 0, club: .iron8, miss: .left, contact: .okay, confidence: .medium),
            HoleSeed(strokes: 5, putts: 2, penalties: 1, club: .iron6, miss: .right, contact: .poor, confidence: .low),
            HoleSeed(strokes: 4, putts: 2, penalties: 0, club: .pitchingWedge, miss: .short, contact: .okay, confidence: .medium),
            HoleSeed(strokes: 5, putts: 3, penalties: 0, club: .iron9, miss: .long, contact: .okay, confidence: .medium),
            HoleSeed(strokes: 4, putts: 2, penalties: 0, club: .iron7, miss: .left, contact: .poor, confidence: .low),
            HoleSeed(strokes: 5, putts: 2, penalties: 1, club: .iron8, miss: .right, contact: .okay, confidence: .medium),
            HoleSeed(strokes: 4, putts: 2, penalties: 0, club: .gapWedge, miss: .short, contact: .poor, confidence: .low),
            HoleSeed(strokes: 5, putts: 3, penalties: 1, club: .iron6, miss: .long, contact: .okay, confidence: .medium)
        ], reflection: ReflectionSeed(
            teeShot: .poor, iron: .poor, wedge: .okay, shortGame: .okay, putting: .poor,
            biggestMiss: .distanceControl, mentalMistake: true,
            mentalNote: "Got frustrated after the front three holes and rushed a few shots.",
            best: "Hung in there even though it wasn't my best stuff.",
            frustrated: "Three-putted way too many greens.",
            improve: "Slow down on the greens and commit to a speed before putting."
        ))

        makeRound(daysAgo: 15, holes: [
            HoleSeed(strokes: 4, putts: 2, penalties: 0, club: .iron7, miss: .good, contact: .good, confidence: .high),
            HoleSeed(strokes: 5, putts: 3, penalties: 0, club: .iron8, miss: .left, contact: .okay, confidence: .medium),
            HoleSeed(strokes: 4, putts: 2, penalties: 0, club: .iron6, miss: .short, contact: .okay, confidence: .medium),
            HoleSeed(strokes: 4, putts: 2, penalties: 1, club: .pitchingWedge, miss: .right, contact: .poor, confidence: .low),
            HoleSeed(strokes: 5, putts: 2, penalties: 0, club: .iron9, miss: .long, contact: .okay, confidence: .medium),
            HoleSeed(strokes: 4, putts: 2, penalties: 0, club: .iron7, miss: .good, contact: .good, confidence: .high),
            HoleSeed(strokes: 4, putts: 2, penalties: 0, club: .iron8, miss: .short, contact: .okay, confidence: .medium),
            HoleSeed(strokes: 4, putts: 2, penalties: 1, club: .gapWedge, miss: .left, contact: .poor, confidence: .low),
            HoleSeed(strokes: 4, putts: 2, penalties: 0, club: .iron6, miss: .good, contact: .okay, confidence: .medium)
        ], reflection: ReflectionSeed(
            teeShot: .okay, iron: .okay, wedge: .poor, shortGame: .okay, putting: .okay,
            biggestMiss: .left, mentalMistake: false, mentalNote: "",
            best: "Tee shots felt more solid today.",
            frustrated: "A couple of wedge shots came up short.",
            improve: "Work on wedge distances this week."
        ))

        makeRound(daysAgo: 8, holes: [
            HoleSeed(strokes: 4, putts: 2, penalties: 0, club: .iron7, miss: .good, contact: .good, confidence: .high),
            HoleSeed(strokes: 4, putts: 2, penalties: 0, club: .iron8, miss: .good, contact: .okay, confidence: .medium),
            HoleSeed(strokes: 4, putts: 1, penalties: 0, club: .iron6, miss: .good, contact: .good, confidence: .high),
            HoleSeed(strokes: 4, putts: 2, penalties: 0, club: .pitchingWedge, miss: .short, contact: .okay, confidence: .medium),
            HoleSeed(strokes: 4, putts: 2, penalties: 0, club: .iron9, miss: .good, contact: .okay, confidence: .medium),
            HoleSeed(strokes: 3, putts: 1, penalties: 0, club: .iron7, miss: .good, contact: .good, confidence: .high),
            HoleSeed(strokes: 4, putts: 2, penalties: 0, club: .iron8, miss: .left, contact: .okay, confidence: .medium),
            HoleSeed(strokes: 4, putts: 2, penalties: 1, club: .gapWedge, miss: .right, contact: .poor, confidence: .low),
            HoleSeed(strokes: 5, putts: 3, penalties: 0, club: .iron6, miss: .long, contact: .okay, confidence: .medium)
        ], reflection: ReflectionSeed(
            teeShot: .good, iron: .good, wedge: .okay, shortGame: .good, putting: .good,
            biggestMiss: .right, mentalMistake: false, mentalNote: "",
            best: "Ball-striking felt really consistent.",
            frustrated: "One loose tee shot on the back nine cost me a penalty.",
            improve: "Stay aggressive with club selection off the tee."
        ))

        makeRound(daysAgo: 0, holes: [
            HoleSeed(strokes: 3, putts: 2, penalties: 0, club: .iron7, miss: .good, contact: .good, confidence: .high),
            HoleSeed(strokes: 4, putts: 2, penalties: 0, club: .iron8, miss: .short, contact: .okay, confidence: .medium),
            HoleSeed(strokes: 3, putts: 2, penalties: 0, club: .iron6, miss: .good, contact: .good, confidence: .high),
            HoleSeed(strokes: 4, putts: 2, penalties: 0, club: .pitchingWedge, miss: .good, contact: .okay, confidence: .medium),
            HoleSeed(strokes: 3, putts: 2, penalties: 0, club: .iron9, miss: .good, contact: .good, confidence: .high),
            HoleSeed(strokes: 4, putts: 2, penalties: 0, club: .iron7, miss: .left, contact: .okay, confidence: .medium),
            HoleSeed(strokes: 4, putts: 2, penalties: 0, club: .iron8, miss: .good, contact: .okay, confidence: .medium),
            HoleSeed(strokes: 4, putts: 2, penalties: 0, club: .gapWedge, miss: .right, contact: .okay, confidence: .medium),
            HoleSeed(strokes: 4, putts: 2, penalties: 0, club: .iron6, miss: .good, contact: .okay, confidence: .medium)
        ], reflection: ReflectionSeed(
            teeShot: .good, iron: .good, wedge: .good, shortGame: .good, putting: .good,
            biggestMiss: .right, mentalMistake: false, mentalNote: "",
            best: "Best ball-striking round in a while — very consistent across the board.",
            frustrated: "Nothing major today, maybe one short iron that drifted right.",
            improve: "Keep the same pre-shot routine going into the next round."
        ))

        ClubStatsService.recompute(for: profile, in: context)
    }
}
#endif

private extension GolfHole {
    func with(_ configure: (GolfHole) -> Void) -> GolfHole {
        configure(self)
        return self
    }
}
