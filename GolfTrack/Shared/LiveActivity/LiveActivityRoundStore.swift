import ActivityKit
import Foundation
import SwiftData

enum LiveActivityRoundStore {
    static let appGroupIdentifier = "group.com.golftrack.app"

    private static let activeRoundIDKey = "liveActivity.activeRoundID"
    private static let activeHoleNumberKey = "liveActivity.activeHoleNumber"
    private static let revisionKey = "liveActivity.revision"

    struct RoundSnapshot {
        struct Hole {
            let id: UUID
            let holeNumber: Int
            let strokes: Int
            let putts: Int
            let penalties: Int
        }

        let isComplete: Bool
        let activeHoleNumber: Int?
        let holes: [Hole]
    }

    static var schema: Schema {
        Schema([
            UserProfile.self, GolfCourse.self, GolfHole.self,
            GolfRound.self, HoleScore.self, ClubShot.self,
            RoundReflection.self, RoundAdvice.self,
            PracticePlan.self, PracticeDrill.self, ClubStats.self
        ])
    }

    private static let cachedContainer: ModelContainer = {
        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            groupContainer: .identifier(appGroupIdentifier)
        )
        do {
            return try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            let memoryConfig = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
            return try! ModelContainer(for: schema, configurations: [memoryConfig])
        }
    }()

    static func makeModelContainer() -> ModelContainer {
        cachedContainer
    }

    static var activeRoundID: UUID? {
        get {
            guard let rawValue = defaults?.string(forKey: activeRoundIDKey) else { return nil }
            return UUID(uuidString: rawValue)
        }
        set {
            if let newValue {
                defaults?.set(newValue.uuidString, forKey: activeRoundIDKey)
            } else {
                defaults?.removeObject(forKey: activeRoundIDKey)
            }
        }
    }

    static var activeHoleNumber: Int? {
        get {
            let value = defaults?.integer(forKey: activeHoleNumberKey) ?? 0
            return value > 0 ? value : nil
        }
        set {
            if let newValue {
                defaults?.set(newValue, forKey: activeHoleNumberKey)
            } else {
                defaults?.removeObject(forKey: activeHoleNumberKey)
            }
        }
    }

    static var revision: Int {
        defaults?.integer(forKey: revisionKey) ?? 0
    }

    @MainActor
    static func addStroke() async throws {
        try await mutateCurrentHole { hole in
            hole.strokes = min(15, hole.strokes + 1)
        }
    }

    @MainActor
    static func removeStroke() async throws {
        try await mutateCurrentHole { hole in
            hole.strokes = max(0, hole.strokes - 1)
            hole.putts = min(hole.putts, hole.strokes)
        }
    }

    @MainActor
    static func addPutt() async throws {
        try await mutateCurrentHole { hole in
            hole.putts = min(10, hole.putts + 1)
        }
    }

    @MainActor
    static func removePutt() async throws {
        try await mutateCurrentHole { hole in
            guard hole.putts > 0 else { return }
            hole.putts = max(0, hole.putts - 1)
        }
    }

    @MainActor
    static func advanceToNextHole() async throws {
        let container = makeModelContainer()
        let context = ModelContext(container)
        guard let round = activeRound(in: context) else { return }
        let currentHoleNumber = resolvedActiveHoleNumber(for: round)
        let holes = round.sortedHoleScores
        let currentIndex = holes.firstIndex { $0.holeNumber == currentHoleNumber } ?? 0
        let nextIndex = min(holes.count - 1, currentIndex + 1)
        let nextHoleNumber = holes.indices.contains(nextIndex) ? holes[nextIndex].holeNumber : currentHoleNumber
        activeHoleNumber = nextHoleNumber
        round.activeHoleNumber = nextHoleNumber
        try context.save()
        markChanged()
        await updateActivity(for: round, holeNumber: nextHoleNumber)
    }

    @MainActor
    static func finishRound() async throws {
        let container = makeModelContainer()
        let context = ModelContext(container)
        guard let round = activeRound(in: context) else { return }
        round.activeHoleNumber = nil
        round.isComplete = true
        try context.save()
        markChanged()

        let state = contentState(for: round, holeNumber: resolvedActiveHoleNumber(for: round))
        let content = ActivityContent(state: state, staleDate: nil)
        for activity in Activity<RoundActivityAttributes>.activities {
            await activity.end(content, dismissalPolicy: .immediate)
        }
        activeRoundID = nil
        activeHoleNumber = nil
    }

    @MainActor
    static func snapshot(for roundID: UUID) -> RoundSnapshot? {
        let context = ModelContext(makeModelContainer())
        var descriptor = FetchDescriptor<GolfRound>(
            predicate: #Predicate { $0.id == roundID }
        )
        descriptor.fetchLimit = 1
        guard let round = try? context.fetch(descriptor).first else {
            return nil
        }

        let holes = round.sortedHoleScores.map {
            RoundSnapshot.Hole(
                id: $0.id,
                holeNumber: $0.holeNumber,
                strokes: $0.strokes,
                putts: $0.putts,
                penalties: $0.penalties
            )
        }

        return RoundSnapshot(
            isComplete: round.isComplete,
            activeHoleNumber: activeHoleNumber ?? round.activeHoleNumber,
            holes: holes
        )
    }

    static func contentState(for round: GolfRound, holeNumber: Int? = nil) -> RoundActivityAttributes.ContentState {
        let holes = round.sortedHoleScores
        let resolvedHoleNumber = holeNumber ?? resolvedActiveHoleNumber(for: round)
        let currentHole = holes.first { $0.holeNumber == resolvedHoleNumber } ?? holes.first
        let completedHoles = holes.filter { $0.strokes > 0 }.count
        let finalHoleNumber = holes.last?.holeNumber ?? round.holesPlayed

        return RoundActivityAttributes.ContentState(
            holeNumber: currentHole?.holeNumber ?? 1,
            strokesThisHole: currentHole?.strokes ?? 0,
            puttsThisHole: currentHole?.putts ?? 0,
            totalStrokes: round.totalStrokes,
            totalPar: round.totalPar,
            holesPlayed: completedHoles,
            isFinalHole: (currentHole?.holeNumber ?? resolvedHoleNumber) == finalHoleNumber,
            paceText: paceText(for: round, completedHoles: completedHoles)
        )
    }

    @MainActor
    private static func mutateCurrentHole(_ mutate: (HoleScore) -> Void) async throws {
        let container = makeModelContainer()
        let context = ModelContext(container)
        guard let round = activeRound(in: context) else { return }
        let holeNumber = resolvedActiveHoleNumber(for: round)
        guard let hole = round.sortedHoleScores.first(where: { $0.holeNumber == holeNumber }) else { return }

        round.activeHoleNumber = holeNumber
        mutate(hole)
        try context.save()
        markChanged()
        await updateActivity(for: round, holeNumber: holeNumber)
    }

    private static func activeRound(in context: ModelContext) -> GolfRound? {
        guard let activeRoundID else { return nil }
        var descriptor = FetchDescriptor<GolfRound>(
            predicate: #Predicate { $0.id == activeRoundID && !$0.isComplete }
        )
        descriptor.fetchLimit = 1
        return try? context.fetch(descriptor).first
    }

    private static func resolvedActiveHoleNumber(for round: GolfRound) -> Int {
        let holes = round.sortedHoleScores
        let fallback = holes.first(where: { $0.strokes == 0 })?.holeNumber ?? holes.last?.holeNumber ?? 1
        let holeNumber = activeHoleNumber ?? round.activeHoleNumber ?? fallback
        guard !holes.isEmpty else { return max(1, holeNumber) }
        if holes.contains(where: { $0.holeNumber == holeNumber }) {
            return holeNumber
        }
        return fallback
    }

    private static func updateActivity(for round: GolfRound, holeNumber: Int) async {
        let state = contentState(for: round, holeNumber: holeNumber)
        let content = ActivityContent(state: state, staleDate: nil)
        for activity in Activity<RoundActivityAttributes>.activities {
            await activity.update(content)
        }
    }

    private static func markChanged() {
        defaults?.set(revision + 1, forKey: revisionKey)
        defaults?.synchronize()
    }

    private static func paceText(for round: GolfRound, completedHoles: Int) -> String? {
        guard let target = round.targetScore, completedHoles > 0 else { return nil }
        let holes = round.sortedHoleScores
        let played = holes.filter { $0.strokes > 0 }
        guard !played.isEmpty else { return nil }
        let scoreToParSoFar = played.reduce(0) { $0 + $1.scoreToPar }
        let projectedToPar = Int((Double(scoreToParSoFar) / Double(played.count) * Double(max(holes.count, 1))).rounded())
        let targetToPar = target - round.totalPar
        if projectedToPar <= targetToPar {
            return "On pace"
        }
        return "Off by \(projectedToPar - targetToPar)"
    }

    private static var defaults: UserDefaults? {
        UserDefaults(suiteName: appGroupIdentifier)
    }
}
