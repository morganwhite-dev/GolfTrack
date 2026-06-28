import Foundation
import SwiftData

@Model
final class RoundReflection {
    var id: UUID = UUID()
    var teeShotFeelRaw: String?
    var ironPlayFeelRaw: String?
    var wedgePlayFeelRaw: String?
    var shortGameFeelRaw: String?
    var puttingFeelRaw: String?
    var biggestMissRaw: String?
    var hadMentalMistakes: Bool = false
    var mentalMistakesNote: String = ""
    var feltBestText: String = ""
    var frustratedText: String = ""
    var improveNextText: String = ""

    init() { self.id = UUID() }

    var teeShotFeel: FeelRating? {
        get { teeShotFeelRaw.flatMap { FeelRating(rawValue: $0) } }
        set { teeShotFeelRaw = newValue?.rawValue }
    }
    var ironPlayFeel: FeelRating? {
        get { ironPlayFeelRaw.flatMap { FeelRating(rawValue: $0) } }
        set { ironPlayFeelRaw = newValue?.rawValue }
    }
    var wedgePlayFeel: FeelRating? {
        get { wedgePlayFeelRaw.flatMap { FeelRating(rawValue: $0) } }
        set { wedgePlayFeelRaw = newValue?.rawValue }
    }
    var shortGameFeel: FeelRating? {
        get { shortGameFeelRaw.flatMap { FeelRating(rawValue: $0) } }
        set { shortGameFeelRaw = newValue?.rawValue }
    }
    var puttingFeel: FeelRating? {
        get { puttingFeelRaw.flatMap { FeelRating(rawValue: $0) } }
        set { puttingFeelRaw = newValue?.rawValue }
    }
    var biggestMiss: BiggestMiss? {
        get { biggestMissRaw.flatMap { BiggestMiss(rawValue: $0) } }
        set { biggestMissRaw = newValue?.rawValue }
    }
}
