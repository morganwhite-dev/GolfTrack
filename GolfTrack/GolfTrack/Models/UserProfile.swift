import Foundation
import SwiftData

@Model
final class UserProfile {
    var id: UUID = UUID()
    var name: String = ""
    var skillLevelRaw: String = SkillLevel.beginner.rawValue
    var estimatedHandicap: Double?
    /// Self-reported average score relative to par (score minus par), not absolute strokes —
    /// works the same whether the holes played are a standard par-36 nine or a par-3 nine.
    var average18RelativeToPar: Int?
    var average9RelativeToPar: Int?
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

    var goals: [GolfGoal] {
        get { goalRawValues.compactMap { GolfGoal(rawValue: $0) } }
        set { goalRawValues = newValue.map(\.rawValue) }
    }
}
