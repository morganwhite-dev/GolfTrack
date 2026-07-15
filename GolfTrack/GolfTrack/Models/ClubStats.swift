import Foundation
import SwiftData

@Model
final class ClubStats: Hashable {
    var id: UUID = UUID()
    var clubRaw: String = ClubType.driver.rawValue
    var timesUsed: Int = 0
    var goodShots: Int = 0
    var badShots: Int = 0
    var missLeft: Int = 0
    var missRight: Int = 0
    var missShort: Int = 0
    var missLong: Int = 0
    var fatShots: Int = 0
    var thinShots: Int = 0
    var toppedShots: Int = 0
    var chunkedShots: Int = 0
    var averageConfidence: Double = 0
    var notes: String = ""
    var lastUpdated: Date = Date()
    var profile: UserProfile?

    init(club: ClubType) {
        self.id = UUID()
        self.clubRaw = club.rawValue
    }

    var club: ClubType {
        get { ClubType(rawValue: clubRaw) ?? .other }
        set { clubRaw = newValue.rawValue }
    }

    var goodShotRate: Double {
        timesUsed == 0 ? 0 : Double(goodShots) / Double(timesUsed)
    }

    var dominantMiss: String? {
        let misses: [(String, Int)] = [
            ("Left", missLeft), ("Right", missRight), ("Short", missShort), ("Long", missLong),
            ("Fat", fatShots), ("Thin", thinShots), ("Topped", toppedShots), ("Chunked", chunkedShots)
        ]
        guard let top = misses.max(by: { $0.1 < $1.1 }), top.1 > 0 else { return nil }
        return top.0
    }

    static func == (lhs: ClubStats, rhs: ClubStats) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}
