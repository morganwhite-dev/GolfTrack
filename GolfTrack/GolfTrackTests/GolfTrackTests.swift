import XCTest
@testable import GolfTrack

final class GolfTrackTests: XCTestCase {
    func testDefaultParsSupportCustomHoleCounts() {
        XCTAssertEqual(ManualCourseCreateView.defaultPars(courseType: .par3, holeCount: 5), [3, 3, 3, 3, 3])
        XCTAssertEqual(ManualCourseCreateView.defaultPars(courseType: .standard, holeCount: 3), [4, 4, 3])
        XCTAssertEqual(ManualCourseCreateView.defaultPars(courseType: .executive, holeCount: 12), [3, 3, 4, 3, 3, 4, 3, 3, 4, 3, 3, 4])
    }

    func testRoundStatsUsesOnlyPlayedHoleScores() {
        let round = GolfRound(course: nil, holesPlayed: 3)

        let first = HoleScore(holeNumber: 1, par: 4)
        first.strokes = 5
        first.putts = 2
        first.penalties = 1
        first.round = round

        let second = HoleScore(holeNumber: 2, par: 3)
        second.strokes = 3
        second.putts = 1
        second.round = round

        round.holeScores = [second, first]

        let stats = RoundStats(round: round)
        XCTAssertEqual(stats.holes.map(\.holeNumber), [1, 2])
        XCTAssertEqual(stats.totalStrokes, 8)
        XCTAssertEqual(stats.totalPar, 7)
        XCTAssertEqual(stats.totalPutts, 3)
        XCTAssertEqual(stats.totalPenalties, 1)
    }
}
