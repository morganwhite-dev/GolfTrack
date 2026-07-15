import ActivityKit
import Foundation

struct RoundActivityAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        var holeNumber: Int
        var strokesThisHole: Int
        var puttsThisHole: Int
        var totalStrokes: Int
        var totalPar: Int
        var holesPlayed: Int
        var isFinalHole: Bool
        var paceText: String?
    }

    var courseName: String
    var totalHoles: Int
    var targetScore: Int?
}
