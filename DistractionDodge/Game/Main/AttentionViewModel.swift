//
//  AttentionViewModel.swift
//  DistractionDodge
//
//  Created by Ayush Kumar Singh on 28/12/24.
//

import SwiftUI
import AVFoundation
import SwiftData

/// The view model responsible for managing the focus training game's state and logic.
///
/// AttentionViewModel handles:
/// - Game state management (start, pause, resume, stop)
/// - Score tracking and calculations
/// - Focus streak monitoring
/// - Distraction generation and management
/// - Target movement patterns
/// - Eye gaze status updates
///
/// Usage:
/// ```swift
/// @StateObject private var viewModel = AttentionViewModel(modelContext: ModelContext())
/// ```
class AttentionViewModel: ObservableObject {
    // MARK: - Published Properties
    
    /// Current position of the focus target
    // CHANGE: Initialize to zero, will be set based on actual view size later
    @Published var position = CGPoint.zero
    
    /// Indicates if the user is currently gazing at the target
    @Published var isGazingAtObject = false
    
    /// Collection of active distractions
    @Published var distractions: [Distraction] = []
    
    /// Current game score
    @Published var score: Int = 0
    
    /// Duration of current focus streak
    @Published var focusStreak: TimeInterval = 0
    
    /// Longest focus streak achieved
    @Published var bestStreak: TimeInterval = 0
    
    /// Total time spent focused during the game
    @Published var totalFocusTime: TimeInterval = 0
    
    /// Remaining game time in seconds
    @Published var gameTime: TimeInterval = 60
    
    /// Indicates if the game is currently active
    @Published var gameActive = false
    
    /// Current background gradient colors
    @Published var backgroundGradient: [Color] = [.black.opacity(0.8), .cyan.opacity(0.2)]
    
    /// Reason for game ending (time up or distraction)
    @Published var endGameReason: EndGameReason = .timeUp
    
    /// Indicates if the game is paused
    @Published var isPaused = false
    
    @Published var sessionStartTime: Date = Date()
    
    enum EndGameReason {
        case timeUp
        case distractionTap
    }
    
    private var modelContext: ModelContext
    
    let notificationData: [(title: String, icon: String, colors: [Color], sound: SystemSoundID)] = [
        ("Messages", "message.fill",
         [Color(red: 32/255, green: 206/255, blue: 97/255), Color(red: 24/255, green: 190/255, blue: 80/255)],
         1007),
        ("Calendar", "calendar",
         [.red, .orange],
         1005),
        ("Mail", "envelope.fill",
         [.blue, .cyan],
         1000),
        ("Reminders", "list.bullet",
         [.orange, .yellow],
         1005),
        ("FaceTime", "video.fill",
         [Color(red: 32/255, green: 206/255, blue: 97/255), Color(red: 24/255, green: 190/255, blue: 80/255)],
         1002),
        ("Weather", "cloud.rain.fill",
         [.blue, .cyan],
         1307),
        ("Photos", "photo.fill",
         [.purple, .indigo],
         1118),
        ("Clock", "alarm.fill",
         [.orange, .red],
         1005)
    ]
    
    private var timer: Timer?
    private var distractionTimer: Timer?
    private var focusStreakTimer: Timer?
    private var gameTimer: Timer?
    private var wasActiveBeforeBackground = false
    private var isInBackground = false
    private var moveDirection = CGPoint(x: 1, y: 1)
    private var currentNotificationInterval: TimeInterval = 2.0
    private var distractionProbability: Double = 0.2
    private var scoreMultiplier: Int = 1
    private var lastFocusState: Bool = false
    private var gameDuration: TimeInterval = 60
    
    // ADD: Property to store the actual view size
    private var viewSize: CGSize = .zero
    
    var totalGameDuration: TimeInterval {
        gameDuration
    }
    
    private let baseDistractionProbability = 0.3
    private let baseDistractionInterval: TimeInterval = 2.5
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        setupNotificationObservers()
    }
    
    private func setupNotificationObservers() {
        NotificationCenter.default.addObserver(
            forName: UIApplication.willResignActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            guard let self = self else { return }
            self.wasActiveBeforeBackground = (self.timer != nil || self.distractionTimer != nil)
            self.pauseGame()
        }
        
        NotificationCenter.default.addObserver(
            forName: UIApplication.didBecomeActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            guard let self = self else { return }
            if self.wasActiveBeforeBackground {
                self.resumeGame()
            }
        }
    }
    
    func setGameDuration(_ duration: TimeInterval) {
        gameDuration = duration
    }
    
    // ADD: Method to receive and store the view size from the ContentView
    func updateViewSize(_ size: CGSize) {
        // Update only if the size is valid and different
        if size != .zero && self.viewSize != size {
            self.viewSize = size
            // Set initial position if it hasn't been set yet or needs centering
            if self.position == .zero {
                 self.position = CGPoint(x: size.width / 2, y: size.height / 2)
            }
        }
    }
    
    func startGame() {
        sessionStartTime = Date()
        endGameReason = .timeUp
        gameActive = true
        currentNotificationInterval = 2.0
        distractionProbability = 0.2
        
        stopGame() // Pauses timers, etc.
        gameTime = gameDuration
        score = 0
        focusStreak = 0
        bestStreak = 0
        totalFocusTime = 0
        scoreMultiplier = 1
        lastFocusState = false
        // CHANGE: Reset position based on stored viewSize, default to center if size known
        position = CGPoint(x: viewSize.width / 2, y: viewSize.height / 2)
        
        startRandomMovement()
        startDistractions()
        startFocusStreakTimer()
        startGameTimer()
    }
    
    private func startGameTimer() {
        gameTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] timer in
            guard let self = self else { return }
            if self.gameTime > 0 {
                self.gameTime -= 1
            } else {
                self.endGame()
            }
        }
    }
    
    private func endGame() {
        gameActive = false
        
        // Save the game session
        let session = GameSession(
            score: score,
            focusStreak: focusStreak,
            bestStreak: bestStreak,
            totalFocusTime: totalFocusTime,
            distractionResistCount: distractions.count
        )
        modelContext.insert(session)
        
        // Update user progress
        let progressFetch = FetchDescriptor<UserProgress>()
        if let progress = try? modelContext.fetch(progressFetch).first {
            if score > progress.highScore {
                progress.highScore = score
            }
            if bestStreak > progress.longestStreak {
                progress.longestStreak = bestStreak
            }
            progress.totalSessions += 1
        }
        
        stopGame()
    }
    
    func pauseGame() {
        isPaused = true
        timer?.invalidate()
        distractionTimer?.invalidate()
        focusStreakTimer?.invalidate()
        gameTimer?.invalidate()
        timer = nil
        distractionTimer = nil
        focusStreakTimer = nil
        gameTimer = nil
    }
    
    func resumeGame() {
        isPaused = false
        startRandomMovement()
        startDistractions()
        startFocusStreakTimer()
        startGameTimer()
    }
    
    func stopGame() {
        wasActiveBeforeBackground = false
        pauseGame()
        distractions.removeAll()
        timer?.invalidate()
        distractionTimer?.invalidate()
        focusStreakTimer?.invalidate()
        gameTimer?.invalidate()
        timer = nil
        distractionTimer = nil
        focusStreakTimer = nil
        gameTimer = nil
    }
    
    func updateGazeStatus(_ isGazing: Bool) {
        if lastFocusState && !isGazing {
            let streakPenalty = min(Int(focusStreak), 10)
            score = max(0, score - streakPenalty)
            scoreMultiplier = 1
        }
        
        isGazingAtObject = isGazing
        if !isGazing {
            if focusStreak > bestStreak {
                bestStreak = focusStreak
            }
            focusStreak = 0
        }
        
        lastFocusState = isGazing
    }
    
    private func startRandomMovement() {
        // ADD: Guard against zero view size
        guard viewSize != .zero else {
            print("Warning: Cannot start movement, viewSize is zero.")
            // Optionally, schedule retry or wait for size update
            return
        }

        let speed: CGFloat = 3.0
        timer?.invalidate() // Ensure previous timer is stopped before starting new one
        timer = Timer.scheduledTimer(withTimeInterval: 0.016, repeats: true) { [weak self] _ in
            guard let self = self, self.viewSize != .zero else { return } // Ensure size is still valid

            // CHANGE: Use stored viewSize
            let currentViewSize = self.viewSize
            let ballSize: CGFloat = 100 // Assuming the target visual size

            var newX = self.position.x + (self.moveDirection.x * speed)
            var newY = self.position.y + (self.moveDirection.y * speed)

            // Check boundaries using currentViewSize
            if newX <= ballSize / 2 || newX >= currentViewSize.width - ballSize / 2 {
                self.moveDirection.x *= -1
                // Recalculate newX after direction change to prevent immediate re-collision
                newX = self.position.x + (self.moveDirection.x * speed)
            }
            if newY <= ballSize / 2 || newY >= currentViewSize.height - ballSize / 2 {
                self.moveDirection.y *= -1
                 // Recalculate newY
                newY = self.position.y + (self.moveDirection.y * speed)
            }

            // Clamp values just in case to prevent going significantly out of bounds
            self.position = CGPoint(
                x: max(ballSize/2, min(newX, currentViewSize.width - ballSize/2)),
                y: max(ballSize/2, min(newY, currentViewSize.height - ballSize/2))
            )
        }
    }
    
    private func startDistractions() {
        // ADD: Guard against zero view size
        guard viewSize != .zero else {
             print("Warning: Cannot start distractions, viewSize is zero.")
             // Optionally, schedule retry or wait for size update
            return
        }
        let scaledInterval = baseDistractionInterval * sqrt(gameDuration / 60)

        distractionTimer?.invalidate() // Ensure previous timer stopped
        distractionTimer = Timer.scheduledTimer(withTimeInterval: scaledInterval, repeats: true) { [weak self] _ in
             guard let self = self, self.viewSize != .zero else { return } // Ensure size is still valid

            if Double.random(in: 0...1) < self.baseDistractionProbability {
                // CHANGE: Use stored viewSize
                let currentViewSize = self.viewSize
                let screenWidth = currentViewSize.width
                let screenHeight = currentViewSize.height

                // Define safe insets for distraction placement
                let insetX: CGFloat = 150
                let insetY: CGFloat = 100
                let minX = insetX
                let maxX = screenWidth - insetX
                let minY = insetY
                let maxY = screenHeight - insetY

                // Ensure valid random range
                guard maxX > minX, maxY > minY else {
                    print("Warning: View size too small for distraction placement.")
                    return // Skip adding distraction if view is too small
                }

                let notificationContent = self.notificationData.randomElement()!
                let newDistraction = Distraction(
                    position: CGPoint(
                        x: CGFloat.random(in: minX...maxX),
                        y: CGFloat.random(in: minY...maxY)
                    ),
                    title: notificationContent.title,
                    message: AppMessages.randomMessage(for: notificationContent.title),
                    appIcon: notificationContent.icon,
                    iconColors: notificationContent.colors,
                    soundID: notificationContent.sound
                )

                withAnimation {
                    self.distractions.append(newDistraction)
                    // Maintain max 3 distractions
                    if self.distractions.count > 3 {
                        // Remove the oldest one
                        self.distractions.removeFirst()
                    }
                }

                // Play sound only if the app is active (check might be needed if backgrounding is handled differently on visionOS)
                #if os(iOS) // Conditional compilation might be needed if UIApplication state differs
                if UIApplication.shared.applicationState == .active {
                    AudioServicesPlaySystemSound(notificationContent.sound)
                }
                #else
                // Assume visionOS is always 'active' for sound purposes when game is running, or find equivalent check
                 AudioServicesPlaySystemSound(notificationContent.sound)
                #endif
            }
        }
    }
    
    private func startFocusStreakTimer() {
        focusStreakTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self, self.isGazingAtObject else { return }
            self.focusStreak += 1
            self.totalFocusTime += 1
            if self.focusStreak > self.bestStreak {
                self.bestStreak = self.focusStreak
            }
            self.updateScore()
        }
    }
    
    private func updateScore() {
        score += 1 * scoreMultiplier
        
        if Int(focusStreak) % 5 == 0 {
            scoreMultiplier = min(scoreMultiplier + 1, 3)
        }
        
        if Int(focusStreak) % 10 == 0 {
            score += 5
        }
    }
    
    func handleDistractionTap() {
        
        endGameReason = .distractionTap
        gameActive = false
        stopGame()
    }
    
    var allTimeHighScore: Int {
        let progressFetch = FetchDescriptor<UserProgress>()
        return (try? modelContext.fetch(progressFetch).first)?.highScore ?? 0
    }
    
    var allTimeLongestStreak: TimeInterval {
        let progressFetch = FetchDescriptor<UserProgress>()
        return (try? modelContext.fetch(progressFetch).first)?.longestStreak ?? 0
    }
    
    var totalGameSessions: Int {
        let progressFetch = FetchDescriptor<UserProgress>()
        return (try? modelContext.fetch(progressFetch).first)?.totalSessions ?? 0
    }
    
    var recentSessions: [GameSession] {
        var sessionsFetch = FetchDescriptor<GameSession>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        sessionsFetch.fetchLimit = 10
        return (try? modelContext.fetch(sessionsFetch)) ?? []
    }
    
    func updateModelContext(_ newContext: ModelContext) {
        // Only update if this isn't the same context
        if !isEqual(newContext) {
            self.modelContext = newContext
        }
    }
    
    private func isEqual(_ other: ModelContext) -> Bool {
        // Compare the underlying store URLs to determine if contexts are the same
        guard let thisURL = modelContext.container.configurations.first?.url,
              let otherURL = other.container.configurations.first?.url else {
            return false
        }
        return thisURL == otherURL
    }
}
