import SwiftUI
import SwiftData

@Model
final class UserProgress {
    var hasCompletedIntroduction: Bool
    var hasCompletedTutorial: Bool
    var highScore: Int
    var longestStreak: TimeInterval
    var totalSessions: Int
    
    init(
        hasCompletedIntroduction: Bool = false,
        hasCompletedTutorial: Bool = false,
        highScore: Int = 0,
        longestStreak: TimeInterval = 0,
        totalSessions: Int = 0
    ) {
        self.hasCompletedIntroduction = hasCompletedIntroduction
        self.hasCompletedTutorial = hasCompletedTutorial
        self.highScore = highScore
        self.longestStreak = longestStreak
        self.totalSessions = totalSessions
    }
}