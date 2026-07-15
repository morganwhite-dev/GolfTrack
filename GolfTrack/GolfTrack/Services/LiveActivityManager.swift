import ActivityKit
import Foundation

@MainActor
enum LiveActivityManager {
    static var areActivitiesEnabled: Bool {
        ActivityAuthorizationInfo().areActivitiesEnabled
    }

    static func start(for round: GolfRound, holeNumber: Int? = nil) async -> Bool {
        guard areActivitiesEnabled else { return false }

        let resolvedHoleNumber = holeNumber ?? LiveActivityRoundStore.activeHoleNumber ?? round.sortedHoleScores.first?.holeNumber ?? 1
        LiveActivityRoundStore.activeRoundID = round.id
        LiveActivityRoundStore.activeHoleNumber = resolvedHoleNumber

        let attributes = RoundActivityAttributes(
            courseName: round.course?.name ?? "GolfTrack Round",
            totalHoles: round.sortedHoleScores.last?.holeNumber ?? round.holesPlayed,
            targetScore: round.targetScore
        )
        let state = LiveActivityRoundStore.contentState(for: round, holeNumber: resolvedHoleNumber)
        let content = ActivityContent(state: state, staleDate: nil)

        if Activity<RoundActivityAttributes>.activities.isEmpty {
            do {
                _ = try Activity<RoundActivityAttributes>.request(attributes: attributes, content: content)
                return true
            } catch {
                return false
            }
        } else {
            await update(for: round, holeNumber: resolvedHoleNumber)
            return true
        }
    }

    static func update(for round: GolfRound, holeNumber: Int? = nil) async {
        let resolvedHoleNumber = holeNumber ?? LiveActivityRoundStore.activeHoleNumber ?? round.sortedHoleScores.first?.holeNumber ?? 1
        LiveActivityRoundStore.activeRoundID = round.id
        LiveActivityRoundStore.activeHoleNumber = resolvedHoleNumber

        let state = LiveActivityRoundStore.contentState(for: round, holeNumber: resolvedHoleNumber)
        let content = ActivityContent(state: state, staleDate: nil)
        for activity in Activity<RoundActivityAttributes>.activities {
            await activity.update(content)
        }
    }

    static func end(for round: GolfRound) async {
        let state = LiveActivityRoundStore.contentState(for: round)
        let content = ActivityContent(state: state, staleDate: nil)
        for activity in Activity<RoundActivityAttributes>.activities {
            await activity.end(content, dismissalPolicy: .immediate)
        }

        LiveActivityRoundStore.activeRoundID = nil
        LiveActivityRoundStore.activeHoleNumber = nil
    }
}
