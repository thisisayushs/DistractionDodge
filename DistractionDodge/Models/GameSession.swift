//
//  GameSession.swift
//  DistractionDodge
//
//  Created by Ayush Kumar Singh on 5/3/25.
//
import SwiftUI
import SwiftData

/// A model representing a single focus training session.
/// - Persisted using SwiftData
/// - Tracks score, streaks, and focus metrics
/// - Records session date and distraction resistance
@Model
final class GameSession {
    /// Total score achieved in the session
    var score: Int
    
    /// Current focus streak duration in seconds
    var focusStreak: TimeInterval
    
    /// Longest focus streak achieved in seconds
    var bestStreak: TimeInterval
    
    /// Total time spent focused in seconds
    var totalFocusTime: TimeInterval
    
    /// Session completion timestamp
    var date: Date
    
    /// Number of distractions successfully ignored
    var distractionResistCount: Int
    
    /// Creates a new game session with optional initial values.
    /// - Parameters:
    ///   - score: Initial score, defaults to 0
    ///   - focusStreak: Current streak duration, defaults to 0
    ///   - bestStreak: Best streak achieved, defaults to 0
    ///   - totalFocusTime: Total focus duration, defaults to 0
    ///   - distractionResistCount: Distractions resisted, defaults to 0
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
