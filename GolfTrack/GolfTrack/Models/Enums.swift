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

    /// The break-X goals are named after what they'd mean on a standard course (par 36 for 9,
    /// par 72 for 18), but the actual number checked against a round always adjusts to that
    /// round's course par (see project-goal-scaling-design memory).
    /// This surfaces that adjustment in the UI so the label doesn't look disconnected from the
    /// number actually being tracked.
    var parOffsetSubtitle: String? {
        switch self {
        case .break50On9: return "Par +14 on whatever course you play"
        case .break45On9: return "Par +9 on whatever course you play"
        case .break40On9: return "Par +4 on whatever course you play"
        case .break36On9: return "Even par on whatever course you play"
        case .break100On18: return "Par +28 on whatever course you play"
        case .break90On18: return "Par +18 on whatever course you play"
        case .break80On18: return "Par +8 on whatever course you play"
        default: return nil
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
