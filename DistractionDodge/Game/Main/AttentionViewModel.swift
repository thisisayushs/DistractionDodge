//
//  AttentionViewModel.swift
//  DistractionDodge
//
//  Created by Ayush Kumar Singh on 12/28/24.
//

import SwiftUI
import AVFoundation
import SwiftData

/// The view model responsible for managing the focus training game's state and logic.
///
/// `AttentionViewModel` orchestrates the game flow for both iOS (eye-tracking based) and visionOS (tap-based interaction).
/// It handles:
/// - Game lifecycle: starting, pausing, resuming, and ending games.
/// - Scoring: tracking scores, multipliers, and streaks.
/// - Distraction Management: generating and displaying distractions appropriate for the platform.
/// - Target Movement: controlling the movement of the focus target in iOS mode.
/// - Eye Gaze Updates: processing gaze status from `EyeTrackingViewController` for iOS.
/// - Game Timers: managing game duration, focus streaks, and distraction spawning.
/// - Persistent Storage: saving game session data and user progress using SwiftData.
/// - Platform Adaptation: provides distinct logic for iOS and visionOS game modes.
///
/// It uses `NotificationCenter` to observe application lifecycle events like entering background or becoming active
/// to appropriately pause or resume the game.
///
/// - Important: This class manages game state for two distinct modes: a traditional iOS eye-tracking game
///   and a visionOS tap-based game. Many properties and methods are specific to one mode, often indicated by
///   `isVisionOSMode` checks or "visionOS" in their names.
///
/// Usage:
/// ```swift
/// @StateObject private var viewModel = AttentionViewModel(modelContext: modelContext)
/// // Ensure viewSize is updated, e.g., in a GeometryReader
/// viewModel.updateViewSize(geometry.size)
/// viewModel.startGame(isVisionOSGame: false) // or true for visionOS
/// ```
class AttentionViewModel: ObservableObject {
    // MARK: - Published Properties
    
    /// Current position of the focus target (primarily for iOS mode).
    /// In visionOS, `visionOSCirclePosition` is used for the main target.
    @Published var position = CGPoint.zero
    
    /// Indicates if the user is currently gazing at the target (iOS-specific).
    @Published var isGazingAtObject = false
    
    /// Collection of active distractions displayed on screen.
    /// These can be notifications or other distracting elements.
    @Published var distractions: [Distraction] = []
    
    /// Current game score. Updated based on game events and platform-specific scoring rules.
    @Published var score: Int = 0
    
    /// Duration of current focus streak in seconds (iOS-specific).
    /// Resets when focus is lost.
    @Published var focusStreak: TimeInterval = 0
    
    /// Longest focus streak achieved during the current iOS game session.
    @Published var bestStreak: TimeInterval = 0
    
    /// Total time spent focused on the target during the current iOS game session.
    @Published var totalFocusTime: TimeInterval = 0
    
    /// Remaining game time in seconds. Counts down from `gameDuration`.
    @Published var gameTime: TimeInterval = 60
    
    /// Indicates if the game is currently active (i.e., started and not ended).
    @Published var gameActive = false
    
    /// Current background gradient colors for the game view.
    @Published var backgroundGradient: [Color] = [.black.opacity(0.8), .cyan.opacity(0.2)]
    
    /// Reason for the game ending (e.g., time up, distraction tap, hearts depleted).
    @Published var endGameReason: EndGameReason = .timeUp
    
    /// Indicates if the game is currently paused.
    @Published var isPaused = false
    
    /// Timestamp for when the current game session started.
    @Published var sessionStartTime: Date = Date()
    
    /// Timestamp for when the current game session ended. `nil` if the session is ongoing.
    @Published var sessionEndTime: Date? = nil
    
    /// A unique identifier for the current game session.
    @Published var gameID: UUID = UUID()

    /// Enum defining the possible reasons a game can end.
    enum EndGameReason {
        /// Game ended because the timer reached zero.
        case timeUp
        /// Game ended because the user tapped on a distraction (iOS-specific).
        case distractionTap
        /// Game ended because the user ran out of hearts (visionOS-specific).
        case heartsDepleted
    }
    
    // MARK: - Dependencies
    private var modelContext: ModelContext
    
    // MARK: - Configuration Data
    /// Data for generating notification-style distractions.
    /// Contains tuples of (title, icon SF Symbol name, gradient colors, system sound ID).
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
    
    // MARK: - Private Game State & Timers
    private var timer: Timer? // Timer for iOS target movement
    private var distractionTimer: Timer? // Timer for iOS distraction spawning
    private var focusStreakTimer: Timer? // Timer for iOS focus streak and scoring
    private var gameTimer: Timer? // Timer for game duration countdown
    
    private var wasActiveBeforeBackground = false // Flag to manage game state during backgrounding
    private var isInBackground = false // (Currently unused, consider removal if not planned for use)
    
    private var moveDirection = CGPoint(x: 1, y: 1) // Direction for iOS target movement
    private var currentNotificationInterval: TimeInterval = 2.0 // (Potentially obsolete, consider review)
    private var distractionProbability: Double = 0.2 // (Potentially obsolete, consider review)
    @Published internal var scoreMultiplier: Int = 1 // Score multiplier for iOS game mode
    private var lastFocusState: Bool = false // Previous gaze state for iOS, to detect changes
    private var gameDuration: TimeInterval = 60 // Total duration for a game session
    
    /// The size of the view hosting the game, used for positioning elements.
    /// Must be updated via `updateViewSize(_:)`.
    private var viewSize: CGSize = .zero
    
    /// Flag indicating if the game is running in visionOS mode.
    /// This dictates which game logic, UI elements, and scoring rules are applied.
    internal var isVisionOSMode: Bool = false
    
    /// The total configured duration for the current game type.
    var totalGameDuration: TimeInterval {
        gameDuration
    }
    
    private let baseDistractionProbability = 0.3 // Base probability for spawning distractions in iOS mode
    private let baseDistractionInterval: TimeInterval = 2.5 // Base interval for attempting distraction spawns in iOS mode
    
    // MARK: - visionOS Specific Published Properties
    /// Current catch streak in visionOS mode. Increases with successful hologram catches.
    @Published var visionOSCatchStreak: Int = 0
    /// Current score multiplier in visionOS mode. Increases as the game progresses.
    @Published var visionOSScoreMultiplier: Double = 1.0
    /// Remaining hearts in visionOS mode. Decreases when a hologram expires. Game ends if it reaches 0.
    @Published var visionOSRemainingHearts: Int = 3
    
    /// Current position of the main draggable circle in visionOS mode.
    @Published var visionOSCirclePosition: CGPoint = .zero
    /// Positions of the target holograms in visionOS mode.
    @Published var visionOSHologramPositions: [CGPoint] = []
    
    // MARK: - visionOS Specific Private Properties
    private var visionOSDistractionTimer: Timer? // Timer for visionOS distraction spawning
    private let visionOSDistractionSize: CGFloat = 160 // Size of distraction elements in visionOS
    private let visionOSDistractionPadding: CGFloat = 20 // Padding around distraction elements in visionOS
    
    // MARK: - Initialization
    
    /// Initializes the AttentionViewModel with a SwiftData model context.
    /// - Parameter modelContext: The `ModelContext` for saving game data.
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        setupNotificationObservers()
    }
    
    /// Sets up observers for application lifecycle notifications (e.g., will resign active, did become active).
    /// This allows the game to pause when backgrounded and resume when foregrounded.
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
    
    /// Sets the total duration for the game.
    /// This should be called before starting a new game if a non-default duration is desired.
    /// If the game is not active, `gameTime` (remaining time) is also updated to this duration.
    /// - Parameter duration: The desired game duration in seconds.
    func setGameDuration(_ duration: TimeInterval) {
        gameDuration = duration
        if !gameActive {
            gameTime = duration
        }
    }
    
    /// Updates the view model with the actual size of the game view.
    /// This is crucial for correct positioning and movement of game elements.
    /// Call this when the view's geometry is available, e.g., from a `GeometryReader`.
    /// - Parameter size: The `CGSize` of the game view.
    func updateViewSize(_ size: CGSize) {
        if size != .zero && self.viewSize != size {
            self.viewSize = size
            if self.position == .zero {
                self.position = CGPoint(x: size.width / 2, y: size.height / 2)
            }
        }
    }
    
    /// Starts a new game session.
    /// Resets game state (score, time, streaks, distractions) and starts relevant timers.
    /// - Parameter isVisionOSGame: A boolean indicating whether to start the game in visionOS mode (`true`) or iOS mode (`false`). Defaults to `false`.
    func startGame(isVisionOSGame: Bool = false) {
        self.gameID = UUID()

        self.isVisionOSMode = isVisionOSGame
        sessionStartTime = Date()
        sessionEndTime = nil
        // endGameReason = .timeUp // Set default, will be overridden if game ends differently
        
        gameActive = true
        isPaused = false
        
        // Common reset logic
        currentNotificationInterval = 2.0
        distractionProbability = 0.2
        
        stopGame(isVisionOSGame: self.isVisionOSMode)

        gameTime = gameDuration
        score = 0
        
        if isVisionOSMode {
            focusStreak = 0 // This property is primarily for iOS, but resetting is fine.
            bestStreak = 0  // This property is primarily for iOS.
            totalFocusTime = 0 // This property is primarily for iOS.
            scoreMultiplier = 1 // iOS score multiplier.
            lastFocusState = false // iOS gaze tracking.
            position = .zero // iOS target position.
            
            visionOSCatchStreak = 0
            visionOSScoreMultiplier = 1.0
            visionOSCirclePosition = .zero
            visionOSHologramPositions = []
            visionOSRemainingHearts = 3
            endGameReason = .timeUp
            startVisionOSDistractions()
        } else {
            focusStreak = 0
            bestStreak = 0
            totalFocusTime = 0
            scoreMultiplier = 1
            lastFocusState = false
            position = CGPoint(x: viewSize.width / 2, y: viewSize.height / 2)
            endGameReason = .timeUp
            
            startRandomMovement()
            startDistractions()
            startFocusStreakTimer()
        }
        
        startGameTimer()
    }
    
    /// Initializes and starts the main game timer.
    /// This timer counts down `gameTime` every second. If `gameTime` reaches zero, it ends the game.
    /// For visionOS, it also triggers updates to the `visionOSScoreMultiplier`.
    private func startGameTimer() {
        gameTimer?.invalidate()
        gameTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] timer in
            guard let self = self else { return }
            
            if self.gameTime > 0 {
                self.gameTime -= 1
                
                if self.isVisionOSMode {
                    self.updateVisionOSMultiplier()
                }
            } else {
                if self.gameActive {
                    self.endGameReason = .timeUp
                }
                self.endGame(isVisionOSGame: self.isVisionOSMode)
            }
        }
        if self.isVisionOSMode {
            self.updateVisionOSMultiplier()
        }
    }

    /// Updates the score multiplier for visionOS mode based on game progress.
    /// The multiplier increases as more of the total game duration elapses.
    private func updateVisionOSMultiplier() {
        guard isVisionOSMode, totalGameDuration > 0 else { return }
        let progress = (totalGameDuration - gameTime) / totalGameDuration
        
        let firstThreshold = 1.0 / 3.0
        let secondThreshold = 2.0 / 3.0

        if progress >= secondThreshold {
            self.visionOSScoreMultiplier = 2.0
        } else if progress >= firstThreshold {
            self.visionOSScoreMultiplier = 1.5
        } else {
            self.visionOSScoreMultiplier = 1.0
        }
    }
    
    /// Ends the current game session.
    /// Sets `gameActive` to `false`, records the session end time, saves the game session data to SwiftData,
    /// updates user progress (high score, longest streak), and stops all game timers.
    /// - Parameter isVisionOSGame: A boolean indicating if the game ending is for visionOS mode. This ensures correct data saving.
    private func endGame(isVisionOSGame: Bool = false) {
        guard gameActive else { return }

        self.isVisionOSMode = isVisionOSGame
        gameActive = false
        sessionEndTime = Date()
        
        if isVisionOSGame && (self.endGameReason != .heartsDepleted && self.endGameReason != .timeUp) {
            self.endGameReason = .timeUp
        } else if !isVisionOSGame && (self.endGameReason != .distractionTap && self.endGameReason != .timeUp) {
            self.endGameReason = .timeUp
        }

        let session: GameSession
        if isVisionOSGame {
            session = GameSession(
                score: self.score,
                focusStreak: 0, // iOS-specific, set to 0 for visionOS sessions
                bestStreak: 0, // iOS-specific, set to 0 for visionOS sessions
                totalFocusTime: self.actualPlayedDuration,
                distractionResistCount: self.score, // Placeholder, review if this is the correct metric for "distraction resist" in visionOS
                visionOSBestCatchStreak: self.visionOSCatchStreak // Store the visionOS catch streak for this session
            )
        } else {
            session = GameSession(
                score: score,
                focusStreak: focusStreak,
                bestStreak: bestStreak,
                totalFocusTime: totalFocusTime,
                distractionResistCount: distractions.count, // This makes more sense for iOS
                visionOSBestCatchStreak: 0 // Set to 0 for iOS sessions
            )
        }
        modelContext.insert(session)
        
        let progressFetch = FetchDescriptor<UserProgress>()
        if let progress = try? modelContext.fetch(progressFetch).first {
            if score > progress.highScore {
                progress.highScore = score
            }
            if isVisionOSGame {
                // This correctly updates the all-time longest visionOS streak in UserProgress
                if Double(self.visionOSCatchStreak) > progress.longestVisionOSStreak {
                    progress.longestVisionOSStreak = Double(self.visionOSCatchStreak)
                }
            } else {
                if bestStreak > progress.longestStreak {
                    progress.longestStreak = bestStreak
                }
            }
            progress.totalSessions += 1
        }
        
        stopGame(isVisionOSGame: self.isVisionOSMode)
    }
    
    /// Pauses the game.
    /// Sets `isPaused` to `true` and invalidates all active game timers (movement, distractions, focus streak, game time).
    func pauseGame() {
        isPaused = true
        timer?.invalidate()
        distractionTimer?.invalidate()
        focusStreakTimer?.invalidate()
        gameTimer?.invalidate()
        visionOSDistractionTimer?.invalidate()
        timer = nil
        distractionTimer = nil
        focusStreakTimer = nil
        gameTimer = nil
        visionOSDistractionTimer = nil
    }
    
    /// Resumes a paused game.
    /// Sets `isPaused` to `false` and restarts the appropriate timers based on the current game mode (iOS or visionOS).
    /// Also restarts the main game timer.
    func resumeGame() {
        isPaused = false
        if isVisionOSMode {
            startVisionOSDistractions()
        } else {
            startRandomMovement()
            startDistractions()
            startFocusStreakTimer()
        }
        startGameTimer()
    }
    
    /// Stops all game activities and cleans up resources.
    /// Invalidates all timers and clears active distractions.
    /// Sets `wasActiveBeforeBackground` to `false`.
    /// - Parameter isVisionOSGame: A boolean indicating if the game stopping is for visionOS mode.
    func stopGame(isVisionOSGame: Bool = false) {
        self.isVisionOSMode = isVisionOSGame
        wasActiveBeforeBackground = false

        gameTimer?.invalidate()
        gameTimer = nil
        
        if !isVisionOSMode {
            timer?.invalidate()
            distractionTimer?.invalidate()
            focusStreakTimer?.invalidate()
            timer = nil
            distractionTimer = nil
            focusStreakTimer = nil
            distractions.removeAll()
        } else {
            visionOSDistractionTimer?.invalidate()
            visionOSDistractionTimer = nil
            distractions.removeAll()
        }
    }
    
    /// Updates the game state based on the user's gaze (iOS-specific).
    /// If focus is broken (`isGazing` is `false` after being `true`), applies a penalty and resets the score multiplier.
    /// Updates `isGazingAtObject`, `focusStreak`, and `bestStreak`.
    /// - Parameter isGazing: A boolean indicating whether the user is currently gazing at the target.
    func updateGazeStatus(_ isGazing: Bool) {
        guard !isVisionOSMode else { return }
        
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
    
    /// Starts the timer responsible for moving the target randomly on the screen (iOS-specific).
    /// The target bounces off the edges of the `viewSize`.
    /// Requires `viewSize` to be set and non-zero.
    private func startRandomMovement() {
        guard !isVisionOSMode else { return }
        
        guard viewSize != .zero else {
            print("Warning: Cannot start movement, viewSize is zero.")
            return
        }

        let speed: CGFloat = 3.0
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.016, repeats: true) { [weak self] _ in
            guard let self = self, self.viewSize != .zero else { return }

            let currentViewSize = self.viewSize
            let ballSize: CGFloat = 100

            var newX = self.position.x + (self.moveDirection.x * speed)
            var newY = self.position.y + (self.moveDirection.y * speed)

            if newX <= ballSize / 2 || newX >= currentViewSize.width - ballSize / 2 {
                self.moveDirection.x *= -1
                newX = self.position.x + (self.moveDirection.x * speed)
            }
            if newY <= ballSize / 2 || newY >= currentViewSize.height - ballSize / 2 {
                self.moveDirection.y *= -1
                newY = self.position.y + (self.moveDirection.y * speed)
            }

            self.position = CGPoint(
                x: max(ballSize/2, min(newX, currentViewSize.width - ballSize/2)),
                y: max(ballSize/2, min(newY, currentViewSize.height - ballSize/2))
            )
        }
    }
    
    /// Starts the timer responsible for periodically spawning distractions (iOS-specific).
    /// Distractions (e.g., mock notifications) appear at random positions.
    /// The frequency and probability are influenced by `baseDistractionInterval` and `baseDistractionProbability`.
    /// Requires `viewSize` to be set and non-zero.
    private func startDistractions() {
        guard !isVisionOSMode else { return }
        
        guard viewSize != .zero else {
            print("Warning: Cannot start distractions, viewSize is zero.")
            return
        }
        let scaledInterval = baseDistractionInterval * sqrt(gameDuration / 60)

        distractionTimer?.invalidate()
        distractionTimer = Timer.scheduledTimer(withTimeInterval: scaledInterval, repeats: true) { [weak self] _ in
            guard let self = self, self.viewSize != .zero else { return }

            if Double.random(in: 0...1) < self.baseDistractionProbability {
                let currentViewSize = self.viewSize
                let screenWidth = currentViewSize.width
                let screenHeight = currentViewSize.height

                let insetX: CGFloat = 150
                let insetY: CGFloat = 100
                let minX = insetX
                let maxX = screenWidth - insetX
                let minY = insetY
                let maxY = screenHeight - insetY

                guard maxX > minX, maxY > minY else {
                    print("Warning: View size too small for distraction placement.")
                    return
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

                withAnimation(.spring()) {
                    self.distractions.append(newDistraction)
                    if self.distractions.count > 3 {
                        self.distractions.removeFirst()
                    }
                }

                #if os(iOS)
                if UIApplication.shared.applicationState == .active {
                    AudioServicesPlaySystemSound(notificationContent.sound)
                }
                #else
                AudioServicesPlaySystemSound(notificationContent.sound)
                #endif
            }
        }
    }
    
    /// Starts the timer that tracks focus streaks and updates the score accordingly (iOS-specific).
    /// This timer fires every second. If `isGazingAtObject` is `true`, it increments `focusStreak`,
    /// `totalFocusTime`, updates `bestStreak`, and calls `updateScore()`.
    private func startFocusStreakTimer() {
        guard !isVisionOSMode else { return }
        
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
    
    /// Updates the score based on focus duration and streaks (iOS-specific).
    /// Adds points based on the current `scoreMultiplier`.
    /// Increases `scoreMultiplier` every 5 seconds of continuous focus (max 3x).
    /// Adds a bonus of 5 points every 10 seconds of continuous focus.
    private func updateScore() {
        guard !isVisionOSMode else { return }
        score += 1 * scoreMultiplier
        
        if Int(focusStreak) % 5 == 0 {
            scoreMultiplier = min(scoreMultiplier + 1, 3)
        }
        
        if Int(focusStreak) % 10 == 0 {
            score += 5
        }
    }

    /// Handles a successful "catch" event in visionOS mode (e.g., user drags circle to hologram).
    /// Awards points based on a base value, current streak, and `visionOSScoreMultiplier`.
    /// Increments `visionOSCatchStreak`.
    func handleVisionOSCatch() {
        guard isVisionOSMode && gameActive else { return }

        let basePoints = 3
        var pointsEarned = Double(basePoints)

        visionOSCatchStreak += 1

        if visionOSCatchStreak > 0 && visionOSCatchStreak % 5 == 0 {
            let streakBonus = 5
            pointsEarned += Double(streakBonus)
        }
        
        pointsEarned *= visionOSScoreMultiplier
        
        score += Int(round(pointsEarned))
        score = max(0, score)
    }

    /// Handles the expiration of a hologram in visionOS mode (i.e., user failed to "catch" it in time).
    /// Applies a small score penalty, resets `visionOSCatchStreak`, and decrements `visionOSRemainingHearts`.
    /// If `visionOSRemainingHearts` reaches zero, the game ends.
    func handleVisionOSHologramExpired() {
        guard isVisionOSMode && gameActive else { return }

        let penalty = -1
        score += penalty
        score = max(0, score)

        visionOSCatchStreak = 0
        
        visionOSRemainingHearts -= 1
        if visionOSRemainingHearts <= 0 {
            visionOSRemainingHearts = 0
            if gameActive {
                self.endGameReason = .heartsDepleted
                endGame(isVisionOSGame: true)
            }
        }
    }
    
    /// Starts the timer responsible for spawning distractions in visionOS mode.
    /// These distractions are non-interactive visual elements.
    private func startVisionOSDistractions() {
        guard isVisionOSMode else { return }
        visionOSDistractionTimer?.invalidate()

        let spawnInterval: TimeInterval = 2.0
        visionOSDistractionTimer = Timer.scheduledTimer(withTimeInterval: spawnInterval, repeats: true) { [weak self] _ in
            guard let self = self, self.gameActive else {
                self?.visionOSDistractionTimer?.invalidate()
                return
            }
            if Double.random(in: 0...1) < 0.4 {
                self.trySpawnVisionOSDistraction()
            }
        }
    }

    /// Attempts to spawn a new distraction in visionOS mode.
    /// Ensures distractions don't overlap with the main circle, existing holograms, or paths between them.
    /// Distractions have a limited lifespan and are removed automatically.
    /// Requires `viewSize` to be set and non-zero.
    private func trySpawnVisionOSDistraction() {
        guard distractions.count < 2 else { return } // Max 2 visual distractions for visionOS
        guard viewSize != .zero else { return }

        let distractionRadius = visionOSDistractionSize / 2
        var candidatePosition: CGPoint = .zero
        var isSafePlacement = false
        let maxAttempts = 10

        for _ in 0..<maxAttempts {
            let randomX = CGFloat.random(
                in: (visionOSDistractionPadding + distractionRadius)...(viewSize.width - visionOSDistractionPadding - distractionRadius)
            )
            let randomY = CGFloat.random(
                in: (visionOSDistractionPadding + distractionRadius)...(viewSize.height - visionOSDistractionPadding - distractionRadius)
            )
            candidatePosition = CGPoint(x: randomX, y: randomY)

            let distToCircle = candidatePosition.distance(to: visionOSCirclePosition)
            if distToCircle < (100 + distractionRadius + 30) { // Main circle size + distraction + padding
                continue
            }

            var tooCloseToHologram = false
            for holoPos in visionOSHologramPositions {
                let distToHolo = candidatePosition.distance(to: holoPos)
                if distToHolo < (45 + distractionRadius + 20) { // Hologram size + distraction + padding
                    tooCloseToHologram = true
                    break
                }
            }
            if tooCloseToHologram {
                continue
            }
            
            var blocksPath = false
            for holoPos in visionOSHologramPositions {
                // Check if distraction is near the line segment between main circle and hologram
                if isPointNearLineSegment(
                    point: candidatePosition,
                    start: visionOSCirclePosition,
                    end: holoPos,
                    threshold: distractionRadius + 15 // Distraction radius + some buffer
                ) {
                    blocksPath = true
                    break
                }
            }
            if blocksPath {
                continue
            }

            isSafePlacement = true
            break
        }

        if isSafePlacement {
            let notificationContent = self.notificationData.randomElement()!
            let newDistraction = Distraction(
                position: candidatePosition,
                title: notificationContent.title,
                message: AppMessages.randomMessage(for: notificationContent.title),
                appIcon: notificationContent.icon,
                iconColors: notificationContent.colors,
                soundID: notificationContent.sound
            )
            
            withAnimation(.spring()) {
                distractions.append(newDistraction)
            }
            
            let lifespan: TimeInterval = Double.random(in: 4.0...7.0) // Lifespan for visionOS distractions
            DispatchQueue.main.asyncAfter(deadline: .now() + lifespan) { [weak self] in
                guard let self = self else { return }
                // Check if distraction still exists before removing (it might have been cleared by stopGame)
                if let index = self.distractions.firstIndex(where: { $0.id == newDistraction.id }) {
                    // Check if the game is still active and if it's a visionOS game mode
                    // to prevent removing distractions if game ended or mode changed
                    if self.gameActive && self.isVisionOSMode {
                        _ = withAnimation { // Store the result to satisfy the compiler if needed
                            self.distractions.remove(at: index)
                        }
                    }
                }
            }
        }
    }

    /// Helper function to determine if a point is within a certain threshold distance from a line segment.
    /// Used in visionOS mode to prevent distractions from blocking the path between the main circle and holograms.
    /// - Parameters:
    ///   - point: The `CGPoint` to check.
    ///   - start: The starting `CGPoint` of the line segment.
    ///   - end: The ending `CGPoint` of the line segment.
    ///   - threshold: The maximum allowed distance from the line segment.
    /// - Returns: `true` if the point is near the line segment, `false` otherwise.
    private func isPointNearLineSegment(point: CGPoint, start: CGPoint, end: CGPoint, threshold: CGFloat) -> Bool {
        // if the start and end points are the same, just check distance to start
        if start.distance(to: end) < 1.0 { // Use a small epsilon to handle floating point inaccuracies
            return point.distance(to: start) < threshold
        }
        let dx = end.x - start.x
        let dy = end.y - start.y
        // Project point onto the line a_b
        // t is the projection parameter
        let t = ((point.x - start.x) * dx + (point.y - start.y) * dy) / (dx*dx + dy*dy)
        var closestPointOnLine: CGPoint
        if t < 0 {
            closestPointOnLine = start // Closest point is a
        } else if t > 1 {
            closestPointOnLine = end   // Closest point is b
        } else {
            closestPointOnLine = CGPoint(x: start.x + t * dx, y: start.y + t * dy) // Closest point is on the segment
        }
        return point.distance(to: closestPointOnLine) < threshold
    }
    
    /// Handles the event where a user taps on a distraction (iOS-specific).
    /// This action ends the game with the reason `.distractionTap`.
    func handleDistractionTap() {
        guard !isVisionOSMode else { return } // This action is for iOS mode
        guard gameActive else { return }
        
        endGameReason = .distractionTap
        endGame(isVisionOSGame: false)
    }
    
    // MARK: - Computed Properties for Stats
    
    /// The all-time high score achieved by the user across all iOS game sessions.
    /// Fetched from `UserProgress` in SwiftData.
    var allTimeHighScore: Int {
        let progressFetch = FetchDescriptor<UserProgress>()
        return (try? modelContext.fetch(progressFetch).first)?.highScore ?? 0
    }
    
    /// The all-time longest focus streak (in seconds) achieved by the user across all iOS game sessions.
    /// Fetched from `UserProgress` in SwiftData.
    var allTimeLongestStreak: TimeInterval { // This refers to iOS time-based streak
        let progressFetch = FetchDescriptor<UserProgress>()
        return (try? modelContext.fetch(progressFetch).first)?.longestStreak ?? 0
    }

    /// The all-time longest catch streak achieved by the user across all visionOS game sessions.
    /// Fetched from `UserProgress` in SwiftData.
    var allTimeLongestVisionOSStreak: Double {
        let progressFetch = FetchDescriptor<UserProgress>()
        return (try? modelContext.fetch(progressFetch).first)?.longestVisionOSStreak ?? 0.0
    }
    
    /// The total number of game sessions played by the user.
    /// Fetched from `UserProgress` in SwiftData.
    var totalGameSessions: Int {
        let progressFetch = FetchDescriptor<UserProgress>()
        return (try? modelContext.fetch(progressFetch).first)?.totalSessions ?? 0
    }
    
    /// A list of the 10 most recent game sessions.
    /// Fetched from `GameSession` in SwiftData, sorted by date in descending order.
    var recentSessions: [GameSession] {
        var sessionsFetch = FetchDescriptor<GameSession>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        sessionsFetch.fetchLimit = 10
        return (try? modelContext.fetch(sessionsFetch)) ?? []
    }
    
    /// The actual duration the last game session was played.
    /// Calculated from `sessionStartTime` and `sessionEndTime`.
    /// If the game is currently active, it returns the time elapsed since `sessionStartTime`.
    var actualPlayedDuration: TimeInterval {
        guard let endTime = sessionEndTime else {
            return gameActive ? Date().timeIntervalSince(sessionStartTime) : 0
        }
        return endTime.timeIntervalSince(sessionStartTime)
    }

    /// Updates the model context if a new one is provided.
    /// This might be used if the environment's model context changes.
    /// Includes a basic check to see if the context is actually different before updating.
    /// - Parameter newContext: The new `ModelContext` to use.
    func updateModelContext(_ newContext: ModelContext) {
        // A more robust way to compare contexts if needed, but often direct assignment is fine
        // if the context is guaranteed to be the correct one from the environment.
        // For now, this check might be overly complex if ModelContainer setup is consistent.
        if !isEqual(newContext) { // Potentially remove isEqual check if causing issues or not necessary
            self.modelContext = newContext
        }
    }
    
    /// Compares the current model context with another to check for equality.
    /// This comparison is based on the URL of their container's first configuration.
    /// - Note: This comparison might be problematic if URLs are not always set (e.g., for in-memory stores)
    ///   or if configurations differ in other ways.
    /// - Parameter other: The `ModelContext` to compare against.
    /// - Returns: `true` if the contexts are considered equal based on their container configuration URL, `false` otherwise.
    private func isEqual(_ other: ModelContext) -> Bool {
        // Check if both contexts are from the same container.
        // This is a simplified check; more robust comparison might be needed if using multiple containers/configurations.
        guard let thisURL = modelContext.container.configurations.first?.url,
              let otherURL = other.container.configurations.first?.url else {
            // If URLs are nil, they might be in-memory or uninitialized in the same way.
            // This part of comparison might need refinement based on how contexts are managed.
            // For now, if one is nil and the other isn't, consider them different.
            // If both are nil, they *could* be the same in-memory store, but it's not guaranteed.
            return modelContext.container.configurations.first?.url == nil && other.container.configurations.first?.url == nil
        }
        return thisURL == otherURL
    }
}
