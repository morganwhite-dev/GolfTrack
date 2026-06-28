import Foundation
import SwiftData

enum StorageService {
    static var schema: Schema {
        Schema([
            UserProfile.self, GolfCourse.self, GolfHole.self,
            GolfRound.self, HoleScore.self, ClubShot.self,
            RoundReflection.self, RoundAdvice.self,
            PracticePlan.self, PracticeDrill.self, ClubStats.self
        ])
    }

    static func makeModelContainer() -> ModelContainer {
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            // Fall back to an in-memory store rather than crashing if the on-disk store can't open.
            let memoryConfig = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
            return try! ModelContainer(for: schema, configurations: [memoryConfig])
        }
    }

    /// Seeds a couple of example courses on first launch so Start Round and Course Search
    /// are never empty, even before the user adds their own course or a search API key is set.
    static func seedIfNeeded(context: ModelContext) {
        let existing = try? context.fetch(FetchDescriptor<GolfCourse>())
        guard (existing ?? []).isEmpty else { return }

        let par3 = GolfCourse(name: "Wendell Coffee Golf & Event Center", location: "Local", courseType: .par3, numberOfHoles: 9)
        par3.isCustom = false
        for i in 1...9 {
            context.insert(GolfHole(holeNumber: i, par: 3, yardage: nil) .with { $0.course = par3 })
        }

        let standard = GolfCourse(name: "Sample Standard Course", location: "Local", courseType: .standard, numberOfHoles: 18)
        standard.isCustom = false
        let pars18 = [4,4,3,5,4,4,3,5,4, 4,3,5,4,4,3,5,4,4]
        for (i, par) in pars18.enumerated() {
            context.insert(GolfHole(holeNumber: i + 1, par: par, yardage: nil).with { $0.course = standard })
        }

        context.insert(par3)
        context.insert(standard)
        try? context.save()
    }
}

private extension GolfHole {
    func with(_ configure: (GolfHole) -> Void) -> GolfHole {
        configure(self)
        return self
    }
}
