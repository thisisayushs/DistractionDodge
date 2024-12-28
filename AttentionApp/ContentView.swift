//
//  ContentView.swift
//  AttentionApp
//
//  Created by Ayush Kumar Singh on 28/12/24.
//

import SwiftUI
import AVFoundation

// Update Distraction model to include color information and sound ID
struct Distraction: Identifiable {
    let id = UUID()
    var position: CGPoint
    var title: String
    var message: String
    var appIcon: String
    var iconColors: [Color]  // Array for gradient colors
    var soundID: SystemSoundID  // Add sound ID
}

// Add simple MainCircle view
struct MainCircle: View {
    let isGazingAtTarget: Bool
    let position: CGPoint
    
    var body: some View {
        Circle()
            .fill(
                LinearGradient(
                    gradient: Gradient(colors: isGazingAtTarget ?
                                     [.green, .mint] : [.blue, .purple]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .frame(width: 200, height: 200)
            .scaleEffect(isGazingAtTarget ? 1.2 : 1.0)
            .shadow(color: isGazingAtTarget ? .green.opacity(0.5) : .blue.opacity(0.5),
                    radius: isGazingAtTarget ? 15 : 10)
            .overlay(
                Circle()
                    .stroke(Color.white.opacity(0.5), lineWidth: 2)
            )
            .position(x: position.x, y: position.y)
            .animation(.easeInOut(duration: 2), value: position)
            .animation(.easeInOut(duration: 0.3), value: isGazingAtTarget)
    }
}

// Add NotificationAnimation view modifier
struct NotificationAnimation: ViewModifier {
    let index: Int
    
    func body(content: Content) -> some View {
        content
            .offset(y: -20)
            .animation(
                .spring(response: 0.5, dampingFraction: 0.65)
                .delay(Double(index) * 0.15),
                value: index
            )
    }
}

// Update NotificationView to use static colors
struct NotificationView: View {
    let distraction: Distraction
    let index: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
                Image(systemName: distraction.appIcon)
                    .font(.title2)
                    .foregroundStyle(
                        LinearGradient(
                            colors: distraction.iconColors,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 30, height: 30)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(distraction.title)
                        .font(.headline)
                        .foregroundColor(.black)
                    Text(distraction.message)
                        .font(.subheadline)
                        .foregroundColor(Color(white: 0.5))
                        .lineLimit(2)
                }
                
                Spacer()
            }
            .padding()
        }
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.white)
                .shadow(color: Color.white.opacity(0.1),
                        radius: 5)
        )
        .frame(width: 300)
        .modifier(NotificationAnimation(index: index))
    }
}

struct AppMessages {
    static let messages = [
        "Messages": [
            "Mom: Are you coming for dinner?",
            "Dad: Just landed at the airport",
            "John: Let's meet for coffee",
            "Sara: Don't forget about tomorrow",
            "Alex: Check out this link"
        ],
        "Calendar": [
            "Team Meeting in 15 minutes",
            "Doctor's Appointment at 2 PM",
            "Project Deadline Tomorrow",
            "Lunch with colleagues",
            "Weekly Review at 4 PM"
        ],
        "Mail": [
            "Weekly Report Due Today",
            "New email from HR Department",
            "Meeting agenda updated",
            "Invoice received",
            "Travel itinerary confirmed"
        ],
        "Reminders": [
            "Pick up groceries",
            "Call the dentist",
            "Pay electricity bill",
            "Submit expense report",
            "Book flight tickets"
        ],
        "FaceTime": [
            "Missed call from Dad",
            "Mom wants to FaceTime",
            "Incoming call from John",
            "Video call request",
            "Group call from Family"
        ],
        "Weather": [
            "Rain expected in your area",
            "Temperature dropping tonight",
            "High winds alert",
            "Clear skies this afternoon",
            "Storm warning for tonight"
        ],
        "Photos": [
            "New Memory: Last Summer",
            "Photos from your trip",
            "Sharing suggestion: Beach Day",
            "New shared album invite",
            "Featured photos selected"
        ],
        "Clock": [
            "Alarm for 7:00 AM",
            "Timer completed",
            "Bedtime in 30 minutes",
            "Wake up alarm set",
            "Timer paused"
        ]
    ]
    
    static func randomMessage(for app: String) -> String {
        return messages[app]?.randomElement() ?? "New Notification"
    }
}

struct ContentView: View {
    // Add state variables for position and gaze tracking
    @State private var position = CGPoint(x: UIScreen.main.bounds.width / 2,
                                        y: UIScreen.main.bounds.height / 2)
    @State private var timer: Timer? = nil
    @State private var isGazingAtObject = false
    @State private var distractions: [Distraction] = []
    @State private var distractionTimer: Timer? = nil
    
    // Update notification data with correct sound IDs
    private let notificationData: [(title: String, icon: String, colors: [Color], sound: SystemSoundID)] = [
        ("Messages", "message.fill",
         [Color(red: 32/255, green: 206/255, blue: 97/255), Color(red: 24/255, green: 190/255, blue: 80/255)],
         1007),  // note sound
        ("Calendar", "calendar",
         [.red, .orange],
         1005),  // chords sound
        ("Mail", "envelope.fill",
         [.blue, .cyan],
         1000),  // default notification sound
        ("Reminders", "list.bullet",
         [.orange, .yellow],
         1005),  // chords sound
        ("FaceTime", "video.fill",
         [Color(red: 32/255, green: 206/255, blue: 97/255), Color(red: 24/255, green: 190/255, blue: 80/255)],
         1002),  // droplet sound
        ("Weather", "cloud.rain.fill",
         [.blue, .cyan],
         1307),  // default notification sound
        ("Photos", "photo.fill",
         [.purple, .indigo],
         1118),  // Droplet Sound
        ("Clock", "alarm.fill",
         [.orange, .red],
         1005)    // chords sound
    ]
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background remains white
                Color.black.edgesIgnoringSafeArea(.all)
                
                // Update EyeTrackingView to pass distraction frames
                EyeTrackingView(onGazeUpdate: { isGazing in
                    isGazingAtObject = isGazing
                })
                .edgesIgnoringSafeArea(.all)
                
                // Update Distractions view with indexed animations
                ForEach(Array(distractions.enumerated()), id: \.element.id) { index, distraction in
                    NotificationView(distraction: distraction, index: index)
                        .position(
                            x: distraction.position.x,
                            y: distraction.position.y + 20  // Offset to account for animation
                        )
                        .transition(
                            .asymmetric(
                                insertion: .scale(scale: 0.8)
                                    .combined(with: .opacity)
                                    .animation(.spring(response: 0.4, dampingFraction: 0.6)),
                                removal: .scale(scale: 0.9)
                                    .combined(with: .opacity)
                                    .animation(.easeOut(duration: 0.2))
                            )
                        )
                }
                
                // Main circle with simplified properties
                MainCircle(
                    isGazingAtTarget: isGazingAtObject,
                    position: position
                )
            }
        }
        .onAppear {
            // Start timer when view appears
            startRandomMovement()
            startDistractions()
        }
        .onDisappear {
            // Stop timer when view disappears
            timer?.invalidate()
            distractionTimer?.invalidate()
            timer = nil
            distractionTimer = nil
        }
    }
    
    // Add function to start random movement
    private func startRandomMovement() {
        timer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { _ in
            let screenWidth = UIScreen.main.bounds.width
            let screenHeight = UIScreen.main.bounds.height
            
            // Calculate safe areas to keep circle fully visible
            let safeX = (100...Int(screenWidth - 100))
            let safeY = (100...Int(screenHeight - 100))
            
            // Generate random position within safe areas
            withAnimation(.easeInOut(duration: 2)) {
                position = CGPoint(
                    x: CGFloat(safeX.randomElement() ?? Int(screenWidth/2)),
                    y: CGFloat(safeY.randomElement() ?? Int(screenHeight/2))
                )
            }
        }
    }
    
    // Update distraction management function to include colors and sounds
    private func startDistractions() {
        distractionTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { _ in
            withAnimation {
                distractions.removeAll()
            }
            
            let screenWidth = UIScreen.main.bounds.width
            let screenHeight = UIScreen.main.bounds.height
            let numberOfDistractions = Int.random(in: 1...2)
            
            DispatchQueue.main.async {
                withAnimation {
                    for _ in 0..<numberOfDistractions {
                        let notificationContent = notificationData.randomElement()!
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
                        distractions.append(newDistraction)
                        
                        // Play app-specific sound
                        AudioServicesPlaySystemSound(notificationContent.sound)
                    }
                }
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                withAnimation {
                    distractions.removeAll()
                }
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
