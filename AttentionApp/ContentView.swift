//
//  ContentView.swift
//  AttentionApp
//
//  Created by Ayush Kumar Singh on 28/12/24.
//

import SwiftUI

// Update Distraction model to include color information
struct Distraction: Identifiable {
    let id = UUID()
    var position: CGPoint
    var title: String
    var message: String
    var appIcon: String
    var iconColors: [Color]  // Array for gradient colors
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

struct ContentView: View {
    // Add state variables for position and gaze tracking
    @State private var position = CGPoint(x: UIScreen.main.bounds.width / 2,
                                        y: UIScreen.main.bounds.height / 2)
    @State private var timer: Timer? = nil
    @State private var isGazingAtObject = false
    @State private var distractions: [Distraction] = []
    @State private var distractionTimer: Timer? = nil
    
    // Update notification content with app-specific colors
    private let notificationData: [(title: String, message: String, icon: String, colors: [Color])] = [
        ("Messages", "Mom: Are you coming for dinner?", "message.fill",
         [Color(red: 32/255, green: 206/255, blue: 97/255), Color(red: 24/255, green: 190/255, blue: 80/255)]),  // iOS Messages green
        ("Calendar", "Team Meeting in 15 minutes", "calendar",
         [.red, .orange]),
        ("Mail", "Weekly Report Due Today", "envelope.fill",
         [.blue, .cyan]),
        ("Reminders", "Pick up groceries", "list.bullet",
         [.orange, .yellow]),
        ("FaceTime", "Missed call from Dad", "video.fill",
         [Color(red: 32/255, green: 206/255, blue: 97/255), Color(red: 24/255, green: 190/255, blue: 80/255)]),  // iOS FaceTime green
        ("Weather", "Rain expected in your area", "cloud.rain.fill",
         [.blue, .cyan]),
        ("Photos", "New Memory: Last Summer", "photo.fill",
         [.purple, .indigo]),
        ("Clock", "Alarm for 7:00 AM", "alarm.fill",
         [.orange, .red])
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
    
    // Update distraction management function to include colors
    private func startDistractions() {
        distractionTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { _ in
            withAnimation {
                distractions.removeAll()
            }
            
            let screenWidth = UIScreen.main.bounds.width
            let screenHeight = UIScreen.main.bounds.height
            let numberOfDistractions = Int.random(in: 1...2)
            
            withAnimation {
                for _ in 0..<numberOfDistractions {
                    let notificationContent = notificationData.randomElement()!
                    let newDistraction = Distraction(
                        position: CGPoint(
                            x: CGFloat.random(in: 150...(screenWidth-150)),
                            y: CGFloat.random(in: 100...(screenHeight-100))
                        ),
                        title: notificationContent.title,
                        message: notificationContent.message,
                        appIcon: notificationContent.icon,
                        iconColors: notificationContent.colors
                    )
                    distractions.append(newDistraction)
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
