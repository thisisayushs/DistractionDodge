import SwiftUI
import SwiftData

@Model
final class UserProgress {
    var hasCompletedOnboarding: Bool
    var highScore: Int
    var longestStreak: TimeInterval
    var totalSessions: Int
    
    init(
        hasCompletedOnboarding: Bool = false,
        highScore: Int = 0,
        longestStreak: TimeInterval = 0,
        totalSessions: Int = 0
    ) {
        self.hasCompletedOnboarding = hasCompletedOnboarding
        self.highScore = highScore
        self.longestStreak = longestStreak
        self.totalSessions = totalSessions
    }
}
