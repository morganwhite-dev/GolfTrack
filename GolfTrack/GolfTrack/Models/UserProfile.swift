import Foundation
import SwiftData

@Model
final class UserProfile {
    var id: UUID = UUID()
    var name: String = ""
    var skillLevelRaw: String = SkillLevel.beginner.rawValue
    var estimatedHandicap: Double?
    var average18ScoreRangeRaw: String?
    var average9ScoreRangeRaw: String?
    var goalRawValues: [String] = []
    var customGoalText: String?
    var createdDate: Date = Date()

    init(name: String = "", skillLevel: SkillLevel = .beginner) {
        self.id = UUID()
        self.name = name
        self.skillLevelRaw = skillLevel.rawValue
        self.createdDate = Date()
    }

    var skillLevel: SkillLevel {
        get { SkillLevel(rawValue: skillLevelRaw) ?? .beginner }
        set { skillLevelRaw = newValue.rawValue }
    }

    var average18ScoreRange: Average18ScoreRange? {
        get { average18ScoreRangeRaw.flatMap { Average18ScoreRange(rawValue: $0) } }
        set { average18ScoreRangeRaw = newValue?.rawValue }
    }

    var average9ScoreRange: Average9ScoreRange? {
        get { average9ScoreRangeRaw.flatMap { Average9ScoreRange(rawValue: $0) } }
        set { average9ScoreRangeRaw = newValue?.rawValue }
    }

    var goals: [GolfGoal] {
        get { goalRawValues.compactMap { GolfGoal(rawValue: $0) } }
        set { goalRawValues = newValue.map(\.rawValue) }
    }
}
