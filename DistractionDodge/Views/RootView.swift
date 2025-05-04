import SwiftUI
import SwiftData

struct RootView: View {
    @Query private var userProgress: [UserProgress]
    
    var body: some View {
        if let progress = userProgress.first {
            if progress.hasCompletedOnboarding {
                Home()
            } else {
                OnboardingView()
            }
        } else {
            OnboardingView()
        }
    }
}
