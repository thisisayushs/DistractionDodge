import SwiftUI
import SwiftData

@main
struct DistractionDodge: App {
    let container: ModelContainer
    
    init() {
        do {
            container = try ModelContainer(
                for: GameSession.self, UserProgress.self,
                configurations: ModelConfiguration(isStoredInMemoryOnly: false)
            )
            
            // Initialize UserProgress if needed
            let context = container.mainContext
            let progressFetch = try context.fetch(FetchDescriptor<UserProgress>())
            if progressFetch.isEmpty {
                context.insert(UserProgress())
            }
        } catch {
            fatalError("Could not initialize ModelContainer: \(error.localizedDescription)")
        }
    }
    
    var body: some Scene {
        WindowGroup {
            OnboardingView()
                .preferredColorScheme(.dark)
        }
        .modelContainer(container)
    }
}