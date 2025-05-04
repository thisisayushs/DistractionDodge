import SwiftUI
import SwiftData

@main
struct DistractionDodge: App {
    var body: some Scene {
        WindowGroup {
            OnboardingView()
                .preferredColorScheme(.dark)
        }
        .modelContainer(for: [GameSession.self, UserProgress.self])
    }
    
    init() {
        // Initialize default UserProgress if needed
        let container = try? ModelContainer(for: [GameSession.self, UserProgress.self])
        if let context = container?.mainContext {
            let progressFetch = FetchDescriptor<UserProgress>()
            if (try? context.fetch(progressFetch))?.isEmpty ?? true {
                context.insert(UserProgress())
            }
        }
    }
}
