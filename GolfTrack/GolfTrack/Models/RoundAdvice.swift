import Foundation
import SwiftData

@Model
final class RoundAdvice {
    var id: UUID = UUID()
    var roundId: UUID = UUID()
    var createdDate: Date = Date()
    var ratingRaw: String = RoundRating.average.rawValue
    var strengths: [String] = []
    var improvementAreas: [String] = []
    var mainIssue: String = ""
    var secondaryIssue: String = ""
    var bestPart: String = ""
    var nextRoundGoal: String = ""

    init(roundId: UUID, rating: RoundRating) {
        self.id = UUID()
        self.roundId = roundId
        self.createdDate = Date()
        self.ratingRaw = rating.rawValue
    }

    var rating: RoundRating {
        get { RoundRating(rawValue: ratingRaw) ?? .average }
        set { ratingRaw = newValue.rawValue }
    }
}
