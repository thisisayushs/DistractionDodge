import SwiftUI
import AVFoundation

class AttentionViewModel: ObservableObject {
    @Published var position = CGPoint(x: UIScreen.main.bounds.width / 2,
                                      y: UIScreen.main.bounds.height / 2)
    @Published var isGazingAtObject = false
    @Published var distractions: [Distraction] = []
    @Published var score: Int = 0
    @Published var focusStreak: TimeInterval = 0
    @Published var distractionsIgnored: Int = 0
    @Published var gameTime: TimeInterval = 60
    @Published var gameActive = false
    @Published var backgroundGradient: [Color] = [.black.opacity(0.8), .cyan.opacity(0.2)]
    @Published var endGameReason: EndGameReason = .timeUp
    
    enum EndGameReason {
        case timeUp
        case distractionTap
    }
    
    private var timer: Timer?
    private var distractionTimer: Timer?
    private var focusStreakTimer: Timer?
    private var gameTimer: Timer?
    private var wasActiveBeforeBackground = false
    private var isInBackground = false
    private var lastDistractionsIgnored: Int = 0
    private var moveDirection = CGPoint(x: 1, y: 1)
    private var currentNotificationInterval: TimeInterval = 2.0
    private var distractionProbability: Double = 0.2
    
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
    
    init() {
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
    
    func startGame() {
        gameActive = true
        currentNotificationInterval = 2.0
        distractionProbability = 0.2
        scheduleNextNotification()
        // Reset all game states
        stopGame()
        gameTime = 60
        score = 0
        focusStreak = 0
        distractionsIgnored = 0
        lastDistractionsIgnored = 0
        position = CGPoint(x: UIScreen.main.bounds.width / 2,
                          y: UIScreen.main.bounds.height / 2)
        
        // Start all game components
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
        endGameReason = .timeUp
        gameActive = false
        stopGame()
    }
    
    func calculateStars() -> Int {
        let maxScore = 100 
        let percentage = Double(score) / Double(maxScore)
        
        if percentage >= 0.8 { return 3 }
        if percentage >= 0.5 { return 2 }
        if percentage >= 0.2 { return 1 }
        return 0
    }
    
    private func pauseGame() {
        timer?.invalidate()
        distractionTimer?.invalidate()
        focusStreakTimer?.invalidate()
        gameTimer?.invalidate()
        timer = nil
        distractionTimer = nil
        focusStreakTimer = nil
        gameTimer = nil
    }
    
    private func resumeGame() {
        startGame()
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
        isGazingAtObject = isGazing
        if !isGazing {
            focusStreak = 0
        }
    }
    
    private func startRandomMovement() {
        let speed: CGFloat = 3.0
        timer = Timer.scheduledTimer(withTimeInterval: 0.016, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            
            let screenSize = UIScreen.main.bounds
            let ballSize: CGFloat = 100
            
            var newX = self.position.x + (self.moveDirection.x * speed)
            var newY = self.position.y + (self.moveDirection.y * speed)
            
            if newX <= ballSize/2 || newX >= screenSize.width - ballSize/2 {
                self.moveDirection.x *= -1
                newX = self.position.x + (self.moveDirection.x * speed)
            }
            if newY <= ballSize/2 || newY >= screenSize.height - ballSize/2 {
                self.moveDirection.y *= -1
                newY = self.position.y + (self.moveDirection.y * speed)
            }
            
            self.position = CGPoint(x: newX, y: newY)
        }
    }
    
    private func startDistractions() {
        distractionTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            
            let probability = 0.10 + (60.0 - self.gameTime) * 0.002
            
            if Double.random(in: 0...1) < probability {
                let screenWidth = UIScreen.main.bounds.width
                let screenHeight = UIScreen.main.bounds.height
                
                let notificationContent = self.notificationData.randomElement()!
                let newDistraction = Distraction(
                    position: CGPoint(
                        x: CGFloat.random(in: 150...(screenWidth-150)),
                        y: CGFloat.random(in: 100...(screenHeight-100))
                    ),
                    title: notificationContent.title,
                    message: AppMessages.randomMessage(for: notificationContent.title),
                    appIcon: notificationContent.icon,
                    iconColors: notificationContent.colors,
                    soundID: notificationContent.sound
                )
                
                withAnimation {
                    self.distractions.append(newDistraction)
                    if self.distractions.count > 3 {
                        self.distractions.removeFirst()
                    }
                }
                
                if UIApplication.shared.applicationState == .active {
                    AudioServicesPlaySystemSound(notificationContent.sound)
                }
            }
        }
    }
    
    private func startFocusStreakTimer() {
        focusStreakTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self, self.isGazingAtObject else { return }
            self.focusStreak += 1
            self.updateScore()
        }
    }
    
    private func updateScore() {
        score += 1
        
        let streakBonus = min(Int(focusStreak) / 10, 2)
        score += streakBonus
        
        let newDistractionsIgnored = distractions.count
        if newDistractionsIgnored > lastDistractionsIgnored {
            distractionsIgnored += newDistractionsIgnored - lastDistractionsIgnored
            score += (newDistractionsIgnored - lastDistractionsIgnored) * 3
        }
        lastDistractionsIgnored = newDistractionsIgnored
    }
    
    private func scheduleNextNotification() {
        Timer.scheduledTimer(withTimeInterval: currentNotificationInterval, repeats: false) { [weak self] _ in
            guard let self = self else { return }
            guard self.gameActive else { return }
            
            if Double.random(in: 0...1) < self.distractionProbability {
                let screenWidth = UIScreen.main.bounds.width
                let screenHeight = UIScreen.main.bounds.height
                
                let notificationContent = self.notificationData.randomElement()!
                let newDistraction = Distraction(
                    position: CGPoint(
                        x: CGFloat.random(in: 150...(screenWidth-150)),
                        y: CGFloat.random(in: 100...(screenHeight-100))
                    ),
                    title: notificationContent.title,
                    message: AppMessages.randomMessage(for: notificationContent.title),
                    appIcon: notificationContent.icon,
                    iconColors: notificationContent.colors,
                    soundID: notificationContent.sound
                )
                
                withAnimation {
                    self.distractions.append(newDistraction)
                    if self.distractions.count > 3 {
                        self.distractions.removeFirst()
                    }
                }
                
                if UIApplication.shared.applicationState == .active {
                    AudioServicesPlaySystemSound(notificationContent.sound)
                }
            }
            self.scheduleNextNotification()
        }
    }
    
    func handleDistractionTap() {
        AudioServicesPlaySystemSound(1521) // Error sound
        endGameReason = .distractionTap
        endGame()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
