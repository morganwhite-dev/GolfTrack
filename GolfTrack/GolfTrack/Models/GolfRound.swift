import Foundation
import SwiftData

@Model
final class GolfRound: Hashable {
    var id: UUID = UUID()
    var course: GolfCourse?
    var date: Date = Date()
    var holesPlayed: Int = 18
    var teeBoxName: String?
    var targetScore: Int?
    var weatherNotes: String?
    var walkOrCartRaw: String?
    var isComplete: Bool = false

    @Relationship(deleteRule: .cascade, inverse: \HoleScore.round)
    var holeScores: [HoleScore]? = []

    @Relationship(deleteRule: .cascade)
    var reflection: RoundReflection?

    @Relationship(deleteRule: .cascade)
    var advice: RoundAdvice?

    @Relationship(deleteRule: .cascade)
    var practicePlan: PracticePlan?

    init(course: GolfCourse?, date: Date = Date(), holesPlayed: Int = 18) {
        self.id = UUID()
        self.course = course
        self.date = date
        self.holesPlayed = holesPlayed
    }

    var walkOrCart: WalkOrCart? {
        get { walkOrCartRaw.flatMap { WalkOrCart(rawValue: $0) } }
        set { walkOrCartRaw = newValue?.rawValue }
    }

    var sortedHoleScores: [HoleScore] {
        (holeScores ?? []).sorted { $0.holeNumber < $1.holeNumber }
    }

    var totalStrokes: Int { sortedHoleScores.reduce(0) { $0 + $1.strokes } }
    var totalPar: Int { sortedHoleScores.reduce(0) { $0 + $1.par } }
    var scoreToPar: Int { totalStrokes - totalPar }
    var totalPutts: Int { sortedHoleScores.reduce(0) { $0 + $1.putts } }
    var totalPenalties: Int { sortedHoleScores.reduce(0) { $0 + $1.penalties } }

    static func == (lhs: GolfRound, rhs: GolfRound) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}

@Model
final class HoleScore {
    var id: UUID = UUID()
    var holeNumber: Int = 1
    var par: Int = 4
    var strokes: Int = 0
    var putts: Int = 0
    var penalties: Int = 0
    var teeClubRaw: String?
    var teeShotResultRaw: String?
    var approachClubRaw: String?
    var shortGameClubRaw: String?
    var fairwayHitRaw: String = YesNoNA.na.rawValue
    var girRaw: String = YesNoNA.na.rawValue
    var missDirectionRaw: String = MissDirection.na.rawValue
    var contactQualityRaw: String?
    var shotIssueRaw: String = ShotIssue.none.rawValue
    var confidenceRaw: String?
    var notes: String = ""
    var round: GolfRound?

    @Relationship(deleteRule: .cascade, inverse: \ClubShot.holeScore)
    var clubShots: [ClubShot]? = []

    init(holeNumber: Int, par: Int) {
        self.id = UUID()
        self.holeNumber = holeNumber
        self.par = par
    }

    var teeClub: ClubType? {
        get { teeClubRaw.flatMap { ClubType(rawValue: $0) } }
        set { teeClubRaw = newValue?.rawValue }
    }
    var teeShotResult: ShotResult? {
        get { teeShotResultRaw.flatMap { ShotResult(rawValue: $0) } }
        set { teeShotResultRaw = newValue?.rawValue }
    }
    var approachClub: ClubType? {
        get { approachClubRaw.flatMap { ClubType(rawValue: $0) } }
        set { approachClubRaw = newValue?.rawValue }
    }
    var shortGameClub: ClubType? {
        get { shortGameClubRaw.flatMap { ClubType(rawValue: $0) } }
        set { shortGameClubRaw = newValue?.rawValue }
    }
    var fairwayHit: YesNoNA {
        get { YesNoNA(rawValue: fairwayHitRaw) ?? .na }
        set { fairwayHitRaw = newValue.rawValue }
    }
    var greenInRegulation: YesNoNA {
        get { YesNoNA(rawValue: girRaw) ?? .na }
        set { girRaw = newValue.rawValue }
    }
    var missDirection: MissDirection {
        get { MissDirection(rawValue: missDirectionRaw) ?? .na }
        set { missDirectionRaw = newValue.rawValue }
    }
    var contactQuality: ContactQuality? {
        get { contactQualityRaw.flatMap { ContactQuality(rawValue: $0) } }
        set { contactQualityRaw = newValue?.rawValue }
    }
    var shotIssue: ShotIssue {
        get { ShotIssue(rawValue: shotIssueRaw) ?? .none }
        set { shotIssueRaw = newValue.rawValue }
    }
    var confidence: Confidence? {
        get { confidenceRaw.flatMap { Confidence(rawValue: $0) } }
        set { confidenceRaw = newValue?.rawValue }
    }

    var scoreToPar: Int { strokes - par }
    var isThreePutt: Bool { putts >= 3 }
    var isBlowUp: Bool { scoreToPar >= 3 }
}

@Model
final class ClubShot {
    var id: UUID = UUID()
    var clubRaw: String = ClubType.driver.rawValue
    var shotTypeRaw: String = ShotType.teeShot.rawValue
    var resultRaw: String = ShotResult.good.rawValue
    var contactQualityRaw: String?
    var confidenceRaw: String?
    var note: String = ""
    var holeScore: HoleScore?

    init(club: ClubType, shotType: ShotType, result: ShotResult) {
        self.id = UUID()
        self.clubRaw = club.rawValue
        self.shotTypeRaw = shotType.rawValue
        self.resultRaw = result.rawValue
    }

    var club: ClubType {
        get { ClubType(rawValue: clubRaw) ?? .other }
        set { clubRaw = newValue.rawValue }
    }
    var shotType: ShotType {
        get { ShotType(rawValue: shotTypeRaw) ?? .teeShot }
        set { shotTypeRaw = newValue.rawValue }
    }
    var result: ShotResult {
        get { ShotResult(rawValue: resultRaw) ?? .good }
        set { resultRaw = newValue.rawValue }
    }
    var contactQuality: ContactQuality? {
        get { contactQualityRaw.flatMap { ContactQuality(rawValue: $0) } }
        set { contactQualityRaw = newValue?.rawValue }
    }
    var confidence: Confidence? {
        get { confidenceRaw.flatMap { Confidence(rawValue: $0) } }
        set { confidenceRaw = newValue?.rawValue }
    }
}
