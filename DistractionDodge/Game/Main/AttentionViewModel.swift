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
    @Published var sessionEndTime: Date? = nil
    
    @Published var gameID: UUID = UUID()

    enum EndGameReason {
        case timeUp
        case distractionTap
        case heartsDepleted
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
    
    private var viewSize: CGSize = .zero
    
    internal var isVisionOSMode: Bool = false
    
    var totalGameDuration: TimeInterval {
        gameDuration
    }
    
    private let baseDistractionProbability = 0.3
    private let baseDistractionInterval: TimeInterval = 2.5
    
    @Published var visionOSCatchStreak: Int = 0
    @Published var visionOSScoreMultiplier: Double = 1.0
    @Published var visionOSRemainingHearts: Int = 3
    
    @Published var visionOSCirclePosition: CGPoint = .zero
    @Published var visionOSHologramPositions: [CGPoint] = []
    
    private var visionOSDistractionTimer: Timer?
    private let visionOSDistractionSize: CGFloat = 160
    private let visionOSDistractionPadding: CGFloat = 20
    
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
        if !gameActive {
            gameTime = duration
        }
    }
    
    func updateViewSize(_ size: CGSize) {
        if size != .zero && self.viewSize != size {
            self.viewSize = size
            if self.position == .zero {
                self.position = CGPoint(x: size.width / 2, y: size.height / 2)
            }
        }
    }
    
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
                focusStreak: TimeInterval(self.visionOSCatchStreak), // Storing visionOS streak (count) as TimeInterval
                bestStreak: 0, // Not directly applicable for visionOS in the same way as iOS
                totalFocusTime: self.actualPlayedDuration,
                distractionResistCount: self.score // This seems to be placeholder, might need adjustment later
            )
        } else {
            session = GameSession(
                score: score,
                focusStreak: focusStreak,
                bestStreak: bestStreak,
                totalFocusTime: totalFocusTime,
                distractionResistCount: distractions.count // This makes more sense for iOS
            )
        }
        modelContext.insert(session)
        
        let progressFetch = FetchDescriptor<UserProgress>()
        if let progress = try? modelContext.fetch(progressFetch).first {
            if score > progress.highScore {
                progress.highScore = score
            }
            if isVisionOSGame {
                let currentVisionOSSessionStreak = Double(self.visionOSCatchStreak)
                if currentVisionOSSessionStreak > progress.longestVisionOSStreak {
                    progress.longestVisionOSStreak = currentVisionOSSessionStreak
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

    private func trySpawnVisionOSDistraction() {
        guard distractions.count < 2 else { return }
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

    // Helper function to check if a point is near a line segment
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
    
    func handleDistractionTap() {
        guard !isVisionOSMode else { return } // This action is for iOS mode
        guard gameActive else { return }
        
        endGameReason = .distractionTap
        endGame(isVisionOSGame: false)
    }
    
    // MARK: - Computed Properties for Stats
    
    var allTimeHighScore: Int {
        let progressFetch = FetchDescriptor<UserProgress>()
        return (try? modelContext.fetch(progressFetch).first)?.highScore ?? 0
    }
    
    var allTimeLongestStreak: TimeInterval { // This refers to iOS time-based streak
        let progressFetch = FetchDescriptor<UserProgress>()
        return (try? modelContext.fetch(progressFetch).first)?.longestStreak ?? 0
    }

    var allTimeLongestVisionOSStreak: Double {
        let progressFetch = FetchDescriptor<UserProgress>()
        return (try? modelContext.fetch(progressFetch).first)?.longestVisionOSStreak ?? 0.0
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
    
    var actualPlayedDuration: TimeInterval {
        guard let endTime = sessionEndTime else {
            return gameActive ? Date().timeIntervalSince(sessionStartTime) : 0
        }
        return endTime.timeIntervalSince(sessionStartTime)
    }

    func updateModelContext(_ newContext: ModelContext) {
        // A more robust way to compare contexts if needed, but often direct assignment is fine
        // if the context is guaranteed to be the correct one from the environment.
        // For now, this check might be overly complex if ModelContainer setup is consistent.
        if !isEqual(newContext) { // Potentially remove isEqual check if causing issues or not necessary
            self.modelContext = newContext
        }
    }
    
    // This comparison might be problematic if the URL isn't always set or if configurations differ.
    // If issues arise, consider simplifying or removing this check.
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
