import SwiftUI
import SwiftData

@Model
final class GameSession {
    var score: Int
    var focusStreak: TimeInterval
    var bestStreak: TimeInterval
    var totalFocusTime: TimeInterval
    var date: Date
    var distractionResistCount: Int
    
    init(
        score: Int = 0,
        focusStreak: TimeInterval = 0,
        bestStreak: TimeInterval = 0,
        totalFocusTime: TimeInterval = 0,
        distractionResistCount: Int = 0
    ) {
        self.score = score
        self.focusStreak = focusStreak
        self.bestStreak = bestStreak
        self.totalFocusTime = totalFocusTime
        self.date = Date()
        self.distractionResistCount = distractionResistCount
    }
}