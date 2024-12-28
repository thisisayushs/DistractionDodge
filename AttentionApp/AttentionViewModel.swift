import SwiftUI
import AVFoundation

class AttentionViewModel: ObservableObject {
    @Published var position = CGPoint(x: UIScreen.main.bounds.width / 2,
                                      y: UIScreen.main.bounds.height / 2)
    @Published var isGazingAtObject = false
    @Published var distractions: [Distraction] = []
    
    private var timer: Timer?
    private var distractionTimer: Timer?
    
    private var wasActiveBeforeBackground = false
    
    private var isInBackground = false
    
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
        startRandomMovement()
        startDistractions()
    }
    
    private func pauseGame() {
        timer?.invalidate()
        distractionTimer?.invalidate()
        timer = nil
        distractionTimer = nil
    }
    
    private func resumeGame() {
        startGame()
    }
    
    func stopGame() {
        wasActiveBeforeBackground = false
        pauseGame()
        distractions.removeAll()
    }
    
    func updateGazeStatus(_ isGazing: Bool) {
        isGazingAtObject = isGazing
    }
    
    private func startRandomMovement() {
        timer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            let screenWidth = UIScreen.main.bounds.width
            let screenHeight = UIScreen.main.bounds.height
            
            let safeX = (100...Int(screenWidth - 100))
            let safeY = (100...Int(screenHeight - 100))
            
            self.position = CGPoint(
                x: CGFloat(safeX.randomElement() ?? Int(screenWidth/2)),
                y: CGFloat(safeY.randomElement() ?? Int(screenHeight/2))
            )
        }
    }
    
    private func startDistractions() {
        distractionTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            
            self.distractions.removeAll()
            
            let screenWidth = UIScreen.main.bounds.width
            let screenHeight = UIScreen.main.bounds.height
            let numberOfDistractions = Int.random(in: 1...2)
            
            for _ in 0..<numberOfDistractions {
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
                self.distractions.append(newDistraction)
                
                if UIApplication.shared.applicationState == .active {
                    AudioServicesPlaySystemSound(notificationContent.sound)
                }
            }
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
