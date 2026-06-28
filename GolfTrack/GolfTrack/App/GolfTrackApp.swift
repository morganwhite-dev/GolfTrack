import SwiftUI
import SwiftData

@main
struct GolfTrackApp: App {
    let container: ModelContainer = StorageService.makeModelContainer()

    init() {
        let context = ModelContext(container)
        StorageService.seedIfNeeded(context: context)
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .preferredColorScheme(.dark)
        }
        .modelContainer(container)
    }
}
