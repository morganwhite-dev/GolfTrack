import Foundation
import SwiftData

@Model
final class PracticePlan {
    var id: UUID = UUID()
    var roundId: UUID = UUID()
    var createdDate: Date = Date()
    var mainFocus: String = ""
    var secondaryFocus: String = ""
    var strengths: [String] = []
    var weaknesses: [String] = []
    var estimatedPracticeTime: Int = 30
    var nextRoundGoal: String = ""

    @Relationship(deleteRule: .cascade, inverse: \PracticeDrill.practicePlan)
    var recommendedDrills: [PracticeDrill]? = []

    init(roundId: UUID) {
        self.id = UUID()
        self.roundId = roundId
        self.createdDate = Date()
    }
}

@Model
final class PracticeDrill {
    var id: UUID = UUID()
    var title: String = ""
    var categoryRaw: String = DrillCategory.contact.rawValue
    var details: String = ""
    var timeMinutes: Int = 10
    var relatedSkill: String = ""
    var relatedClubRaw: String?
    var isComplete: Bool = false
    var completedDate: Date?
    var practicePlan: PracticePlan?

    init(title: String, category: DrillCategory, details: String, timeMinutes: Int, relatedSkill: String, relatedClub: ClubType? = nil) {
        self.id = UUID()
        self.title = title
        self.categoryRaw = category.rawValue
        self.details = details
        self.timeMinutes = timeMinutes
        self.relatedSkill = relatedSkill
        self.relatedClubRaw = relatedClub?.rawValue
        self.isComplete = false
        self.completedDate = nil
    }

    var category: DrillCategory {
        get { DrillCategory(rawValue: categoryRaw) ?? .contact }
        set { categoryRaw = newValue.rawValue }
    }
    var relatedClub: ClubType? {
        get { relatedClubRaw.flatMap { ClubType(rawValue: $0) } }
        set { relatedClubRaw = newValue?.rawValue }
    }
}
