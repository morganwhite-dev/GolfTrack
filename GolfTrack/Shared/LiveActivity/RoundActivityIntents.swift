import AppIntents
import Foundation

struct AddStrokeIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Add Stroke"
    static var description = IntentDescription("Adds one stroke to the current hole.")
    static var openAppWhenRun = false

    func perform() async throws -> some IntentResult {
        try await LiveActivityRoundStore.addStroke()
        return .result()
    }
}

struct RemoveStrokeIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Remove Stroke"
    static var description = IntentDescription("Removes one stroke from the current hole.")
    static var openAppWhenRun = false

    func perform() async throws -> some IntentResult {
        try await LiveActivityRoundStore.removeStroke()
        return .result()
    }
}

struct AddPuttIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Add Putt"
    static var description = IntentDescription("Adds one putt and one stroke to the current hole.")
    static var openAppWhenRun = false

    func perform() async throws -> some IntentResult {
        try await LiveActivityRoundStore.addPutt()
        return .result()
    }
}

struct RemovePuttIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Remove Putt"
    static var description = IntentDescription("Removes one putt and one stroke from the current hole.")
    static var openAppWhenRun = false

    func perform() async throws -> some IntentResult {
        try await LiveActivityRoundStore.removePutt()
        return .result()
    }
}

struct NextHoleIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Next Hole"
    static var description = IntentDescription("Moves the active round to the next hole.")
    static var openAppWhenRun = false

    func perform() async throws -> some IntentResult {
        try await LiveActivityRoundStore.advanceToNextHole()
        return .result()
    }
}

struct FinishRoundIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Finish Round"
    static var description = IntentDescription("Finishes the active round and closes Lock Screen scoring.")
    static var openAppWhenRun = false

    func perform() async throws -> some IntentResult {
        try await LiveActivityRoundStore.finishRound()
        return .result()
    }
}
