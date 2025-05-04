import SwiftUI
import SwiftData

/// A model tracking overall user progress and achievements.
/// - Persisted using SwiftData
/// - Tracks onboarding status and high scores
/// - Maintains lifetime statistics
@Model
final class UserProgress {
    /// Whether user has completed initial onboarding
    var hasCompletedOnboarding: Bool
    
    /// Highest score achieved across all sessions
    var highScore: Int
    
    /// Longest focus streak achieved in seconds
    var longestStreak: TimeInterval
    
    /// Total number of completed sessions
    var totalSessions: Int
    
    /// Creates a new user progress tracker with optional initial values.
    /// - Parameters:
    ///   - hasCompletedOnboarding: Onboarding completion status, defaults to false
    ///   - highScore: Highest score achieved, defaults to 0
    ///   - longestStreak: Longest streak in seconds, defaults to 0
    ///   - totalSessions: Number of completed sessions, defaults to 0
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
