import Foundation

protocol DisplayNamed: RawRepresentable, CaseIterable, Identifiable, Codable where RawValue == String {
    var displayName: String { get }
}
extension DisplayNamed {
    var id: String { rawValue }
}

enum SkillLevel: String, DisplayNamed {
    case beginner, highHandicap, midHandicap, lowHandicap, scratch
    var displayName: String {
        switch self {
        case .beginner: return "Beginner / newer golfer"
        case .highHandicap: return "High handicap"
        case .midHandicap: return "Mid handicap"
        case .lowHandicap: return "Low handicap"
        case .scratch: return "Scratch / advanced"
        }
    }
}

/// Relative-to-par buckets rather than absolute strokes, so the same answer is meaningful
/// whether the round was played on a par-72 standard course or any other par total.
enum Average18ScoreRange: String, DisplayNamed {
    case evenOrBetter, plus1to10, plus11to20, plus21to30, plus31to40, plus40Plus
    var displayName: String {
        switch self {
        case .evenOrBetter: return "Even or better"
        case .plus1to10: return "+1 to +10"
        case .plus11to20: return "+11 to +20"
        case .plus21to30: return "+21 to +30"
        case .plus31to40: return "+31 to +40"
        case .plus40Plus: return "+40 or more"
        }
    }
}

/// Relative-to-par buckets — works the same for a par-36 standard nine or a par-27 par-3 nine.
enum Average9ScoreRange: String, DisplayNamed {
    case evenOrBetter, plus1to5, plus6to10, plus11to15, plus16to20, plus20Plus
    var displayName: String {
        switch self {
        case .evenOrBetter: return "Even or better"
        case .plus1to5: return "+1 to +5"
        case .plus6to10: return "+6 to +10"
        case .plus11to15: return "+11 to +15"
        case .plus16to20: return "+16 to +20"
        case .plus20Plus: return "+20 or more"
        }
    }
}

enum GolfGoal: String, DisplayNamed {
    case betterContact, learnClubDistances, reducePenalties, improvePutting
    case break50On9, break45On9, break40On9, break36On9
    case break100On18, break90On18, break80On18
    case other
    var displayName: String {
        switch self {
        case .betterContact: return "Make better contact"
        case .learnClubDistances: return "Learn club distances"
        case .reducePenalties: return "Reduce penalties"
        case .improvePutting: return "Improve putting"
        case .break50On9: return "Break 50 on 9 holes"
        case .break45On9: return "Break 45 on 9 holes"
        case .break40On9: return "Break 40 on 9 holes"
        case .break36On9: return "Break 36 on 9 holes"
        case .break100On18: return "Break 100 on 18 holes"
        case .break90On18: return "Break 90 on 18 holes"
        case .break80On18: return "Break 80 on 18 holes"
        case .other: return "Other custom goal"
        }
    }
}

enum CourseType: String, DisplayNamed {
    case standard, par3, executive, other
    var displayName: String {
        switch self {
        case .standard: return "Standard"
        case .par3: return "Par-3"
        case .executive: return "Executive"
        case .other: return "Other"
        }
    }
}

enum ShotResult: String, DisplayNamed {
    case good, left, right, short, long, thin, fat, topped, chunked, shanked, safeMiss, pulled, pushed, sliced, hooked
    var displayName: String {
        switch self {
        case .good: return "Good"
        case .left: return "Left"
        case .right: return "Right"
        case .short: return "Short"
        case .long: return "Long"
        case .thin: return "Thin"
        case .fat: return "Fat"
        case .topped: return "Topped"
        case .chunked: return "Chunked"
        case .shanked: return "Shanked"
        case .safeMiss: return "Safe miss"
        case .pulled: return "Pulled"
        case .pushed: return "Pushed"
        case .sliced: return "Sliced"
        case .hooked: return "Hooked"
        }
    }
    /// Common options shown for a quick tee-shot-result picker during fast hole entry.
    static let teeShotQuickOptions: [ShotResult] = [.good, .left, .right, .short, .long]
}

enum YesNoNA: String, DisplayNamed {
    case yes, no, na
    var displayName: String {
        switch self {
        case .yes: return "Yes"
        case .no: return "No"
        case .na: return "N/A"
        }
    }
}

enum MissDirection: String, DisplayNamed {
    case left, right, short, long, good, na
    var displayName: String {
        switch self {
        case .left: return "Left"
        case .right: return "Right"
        case .short: return "Short"
        case .long: return "Long"
        case .good: return "Good"
        case .na: return "N/A"
        }
    }
}

enum ContactQuality: String, DisplayNamed {
    case pure, good, okay, poor
    var displayName: String { rawValue.capitalized }
}

enum ShotIssue: String, DisplayNamed {
    case none, thin, fat, topped, chunked, shanked, pulled, pushed, sliced, hooked
    var displayName: String { self == .none ? "None" : rawValue.capitalized }
}

enum Confidence: String, DisplayNamed {
    case high, medium, low
    var displayName: String { rawValue.capitalized }
}

enum ClubType: String, DisplayNamed {
    case driver, wood3, wood5, wood7, hybrid
    case iron3, iron4, iron5, iron6, iron7, iron8, iron9
    case pitchingWedge, gapWedge, sandWedge, lobWedge, putter, other
    var displayName: String {
        switch self {
        case .driver: return "Driver"
        case .wood3: return "3 Wood"
        case .wood5: return "5 Wood"
        case .wood7: return "7 Wood"
        case .hybrid: return "Hybrid"
        case .iron3: return "3 Iron"
        case .iron4: return "4 Iron"
        case .iron5: return "5 Iron"
        case .iron6: return "6 Iron"
        case .iron7: return "7 Iron"
        case .iron8: return "8 Iron"
        case .iron9: return "9 Iron"
        case .pitchingWedge: return "Pitching Wedge"
        case .gapWedge: return "Gap Wedge"
        case .sandWedge: return "Sand Wedge"
        case .lobWedge: return "Lob Wedge"
        case .putter: return "Putter"
        case .other: return "Other"
        }
    }
    /// Fixed display order — consistent regardless of course type.
    static let orderedAll: [ClubType] = [
        .driver, .wood3, .wood5, .wood7, .hybrid,
        .iron3, .iron4, .iron5, .iron6, .iron7, .iron8, .iron9,
        .pitchingWedge, .gapWedge, .sandWedge, .lobWedge, .putter, .other
    ]
}

enum ShotType: String, DisplayNamed {
    case teeShot, approach, chip, pitch, recovery, putt
    var displayName: String {
        switch self {
        case .teeShot: return "Tee Shot"
        case .approach: return "Approach"
        case .chip: return "Chip"
        case .pitch: return "Pitch"
        case .recovery: return "Recovery"
        case .putt: return "Putt"
        }
    }
}

enum WalkOrCart: String, DisplayNamed {
    case walking, cart
    var displayName: String { rawValue.capitalized }
}

enum RoundRating: String, DisplayNamed {
    case great, solid, closeToGoal, average, needsWork, tough
    var displayName: String {
        switch self {
        case .great: return "Great round"
        case .solid: return "Solid round"
        case .closeToGoal: return "Close to your goal"
        case .average: return "Average round"
        case .needsWork: return "Needs work"
        case .tough: return "Tough round, but useful data"
        }
    }
}

enum BiggestMiss: String, DisplayNamed {
    case left, right, short, long, poorContact, distanceControl, decisionMaking
    var displayName: String {
        switch self {
        case .left: return "Left"
        case .right: return "Right"
        case .short: return "Short"
        case .long: return "Long"
        case .poorContact: return "Poor contact"
        case .distanceControl: return "Distance control"
        case .decisionMaking: return "Decision-making"
        }
    }
}

enum FeelRating: String, DisplayNamed {
    case good, okay, poor
    var displayName: String { rawValue.capitalized }
}

enum DrillCategory: String, DisplayNamed {
    case putting, chipping, wedges, irons, driver, teeShots, contact, alignment, distanceControl, mentalGame, courseManagement
    var displayName: String {
        switch self {
        case .putting: return "Putting"
        case .chipping: return "Chipping"
        case .wedges: return "Wedges"
        case .irons: return "Irons"
        case .driver: return "Driver"
        case .teeShots: return "Tee Shots"
        case .contact: return "Contact"
        case .alignment: return "Alignment"
        case .distanceControl: return "Distance Control"
        case .mentalGame: return "Mental Game"
        case .courseManagement: return "Course Management"
        }
    }
}
