import Foundation

enum PracticePlanService {
    private struct FocusArea {
        let label: String
        let drills: [PracticeDrill]
    }

    private static func categoryForClub(_ club: ClubType) -> DrillCategory {
        switch club {
        case .driver: return .driver
        case .wood3, .wood5, .wood7, .hybrid: return .teeShots
        case .iron3, .iron4, .iron5, .iron6, .iron7, .iron8, .iron9: return .irons
        case .pitchingWedge, .gapWedge, .sandWedge, .lobWedge: return .wedges
        case .putter: return .putting
        case .other: return .contact
        }
    }

    private static func drill(_ title: String, _ category: DrillCategory, _ details: String, _ minutes: Int, skill: String, club: ClubType? = nil) -> PracticeDrill {
        PracticeDrill(title: title, category: category, details: details, timeMinutes: minutes, relatedSkill: skill, relatedClub: club)
    }

    private static func focusAreas(stats: RoundStats, reflection: RoundReflection?) -> [FocusArea] {
        var areas: [FocusArea] = []

        if stats.threePutts >= 2 || reflection?.puttingFeel == .poor {
            areas.append(FocusArea(label: "Putting", drills: [
                drill("3-6 Foot Putts", .putting, "Putt 20 balls from 3-6 feet, focusing on speed and a confident stroke.", 10, skill: "Short putt confidence"),
                drill("Lag Putting Ladder", .putting, "Putt to three different distances (20/40/60 ft) — focus on distance control, not making it.", 10, skill: "Distance control on long putts")
            ]))
        }

        let shortMisses = stats.holes.filter { $0.missDirection == .short }.count
        if shortMisses >= 3 {
            areas.append(FocusArea(label: "Distance Control", drills: [
                drill("Carry Distance Check", .distanceControl, "Hit 5 balls with each of your most-used clubs and note your real carry distance for each.", 15, skill: "Club distance awareness")
            ]))
        }

        let rightMisses = stats.holes.filter { $0.missDirection == .right }.count
        let leftMisses = stats.holes.filter { $0.missDirection == .left }.count
        if rightMisses >= 3 || leftMisses >= 3 {
            areas.append(FocusArea(label: "Alignment & Face Control", drills: [
                drill("Alignment Stick Drill", .alignment, "Lay an alignment stick at your target line and hit 10 shots, checking your start line each time.", 10, skill: "Start line / face control")
            ]))
        }

        let poorContactHoles = stats.holes.filter { $0.contactQuality == .poor || $0.contactQuality == .okay }.count
        if stats.holes.count > 0 && Double(poorContactHoles) / Double(stats.holes.count) >= 0.4 {
            areas.append(FocusArea(label: "Contact", drills: [
                drill("Low Point Control", .contact, "Hit 10 short irons focusing on a divot just after the ball, not before it.", 10, skill: "Center-face / low point control"),
                drill("Half-Swing Contact", .contact, "Tee the ball low and make half-swings, focusing on solid contact before adding power.", 10, skill: "Solid contact basics")
            ]))
        }

        if stats.totalPenalties >= 2 {
            areas.append(FocusArea(label: "Course Management", drills: [
                drill("Safer Target Selection", .courseManagement, "On your next range session, pick the widest part of an imaginary fairway as your target instead of a flag.", 10, skill: "Course management / target selection")
            ]))
        }

        if let club = stats.mostProblematicClub, let tally = stats.clubTallies[club], tally.bad >= 2 {
            areas.append(FocusArea(label: "\(club.displayName) Consistency", drills: [
                drill("\(club.displayName) Focus Reps", categoryForClub(club), "Hit 15-20 controlled, balanced swings with your \(club.displayName), focusing on tempo over power.", 15, skill: "\(club.displayName) consistency", club: club)
            ]))
        }

        if reflection?.hadMentalMistakes == true || stats.blowUpHoles >= 2 {
            areas.append(FocusArea(label: "Mental Game", drills: [
                drill("Pre-Shot Routine Reset", .mentalGame, "Before each shot, take one breath and pick a specific target before you address the ball.", 10, skill: "Mental reset / routine")
            ]))
        }

        return areas
    }

    static func generatePlan(round: GolfRound, stats: RoundStats, advice: RoundAdvice) -> PracticePlan {
        let areas = focusAreas(stats: stats, reflection: round.reflection)
        let plan = PracticePlan(roundId: round.id)

        plan.mainFocus = areas.first?.label ?? "General Improvement"
        plan.secondaryFocus = areas.count > 1 ? areas[1].label : "Overall Consistency"
        plan.strengths = advice.strengths
        plan.weaknesses = advice.improvementAreas
        plan.nextRoundGoal = advice.nextRoundGoal

        var drills = areas.prefix(3).flatMap(\.drills)
        if drills.count < 3 {
            drills.append(drill("Wedge Distance Ladder", .wedges, "Hit 10 wedge shots to three different yardages and track how close you get to each.", 15, skill: "Wedge distance control"))
        }
        if drills.count < 3 {
            drills.append(drill("Putting Tempo", .putting, "Putt 10 balls focusing on an equal backswing and follow-through length.", 10, skill: "Putting tempo"))
        }
        drills = Array(drills.prefix(5))

        plan.recommendedDrills = drills
        plan.estimatedPracticeTime = drills.reduce(0) { $0 + $1.timeMinutes }
        return plan
    }
}
