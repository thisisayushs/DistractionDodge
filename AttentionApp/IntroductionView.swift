//
//  InroductionView.swift
//  AttentionApp
//
//  Created by Ayush Kumar Singh on 21/01/25.
//

import SwiftUI

// Keep NotificationSymbol enum as it's needed for screen 4
enum NotificationType: String, CaseIterable {
    case message = "message.badge.filled.fill"
    case email = "envelope.badge.fill"
    case phone = "phone.badge.fill"
    case social = "bubble.left.and.bubble.right.fill"
    case notification = "bell.badge.fill"
    case browser = "safari.fill"
    case calendar = "calendar.badge.exclamationmark"
}

// Screen model remains the same as original
struct Screen: Identifiable {
    let id = UUID()
    let title: String
    let content: [String]
    let sfSymbol: String
    let emoji: String
    let buttonText: String
}

struct IntroductionView: View {
    // Your existing properties remain the same except symbolScale
    @State private var currentIndex = 0
    @State private var emojiScale: CGFloat = 1
    @State private var emojiRotation: CGFloat = 0
    @State private var bellScale: CGFloat = 1
    @State private var bellRotation: Double = -20
    @State private var symbolScale: CGFloat = 1
    @State private var isNavigating = false
    @State private var distractionOpacity: Double = 0.3
    @State private var isGlowing = false
    @State private var ballPosition = CGPoint(x: 100, y: UIScreen.main.bounds.height / 2)
    @State private var notificationTimer: Timer?
    @State private var notifications: [(type: NotificationType, position: CGPoint, id: UUID)] = []
    @State private var moveDirection = CGPoint(x: 1, y: 1)
    @GestureState private var dragOffset: CGFloat = 0
    @State private var showContentView = false
    @State private var showTutorial = false
    
    // Gradient colors remain the same
    let gradientColors: [(start: Color, end: Color)] = [
        (.black.opacity(0.8), .blue.opacity(0.2)),
        (.black.opacity(0.8), .indigo.opacity(0.2)),
        (.black.opacity(0.8), .purple.opacity(0.2)),
        (.black.opacity(0.8), .cyan.opacity(0.2)),
        (.black.opacity(0.8), .blue.opacity(0.25))
    ]
    
    // Screens array remains exactly as it was in the original
    let screens: [Screen] = [
        Screen(
            title: "Where Did Our Focus Go?",
            content: [
                "In today's fast-paced, screen-filled world, our attention is constantly under attack.",
                "Notifications, social media, and endless multitasking leave us feeling scattered and overwhelmed.",
                "Research shows that fragmented attention isn't just exhausting—it makes it harder to think deeply, stay productive, and feel at peace."
            ],
            sfSymbol: "brain.head.profile.fill",
            emoji: "🧠",
            buttonText: "Tell me more"
        ),
        Screen(
            title: "What Are Distractions Doing to Us?",
            content: [
                "Did you know the average person's focus shifts every 47 seconds while working?",
                "Frequent distractions reduce productivity by up to 40% and increase stress.",
                "Digital distractions train our brains to crave constant stimulation, making it harder to focus on what truly matters."
            ],
            sfSymbol: "clock.badge.exclamationmark.fill",
            emoji: "⏰",
            buttonText: "Is there a solution?"
        ),
        Screen(
            title: "The Good News: You Can Retrain Your Brain",
            content: [
                "Focus isn't fixed—it's a skill you can strengthen with the right tools and practice.",
                "By training your brain to resist distractions, you can rebuild the deep focus needed to thrive in today's world."
            ],
            sfSymbol: "arrow.triangle.2.circlepath.circle.fill",
            emoji: "💪",
            buttonText: "How can I train?"
        ),
        Screen(
            title: "How Distraction Dodge Helps You",
            content: [
                "Distraction Dodge is more than just a game—it's a tool to help you:",
                "Strengthen your focus through fun and engaging challenges.",
                "Learn to ignore digital distractions in a safe, controlled environment."
            ],
            sfSymbol: "target",
            emoji: "🔔",
            buttonText: "I'm ready"
        ),
        Screen(
            title: "Take Control of Your Focus",
            content: [
                "It's time to start your journey toward a clearer, calmer, and more focused mind.",
                "Let's see how well you can dodge distractions and sharpen your attention skills."
            ],
            sfSymbol: "figure.mind.and.body",
            emoji: "🚀",
            buttonText: "Start Training"
        )
    ]
    
    // Add navigation function
    private func navigate(forward: Bool) {
        if !isNavigating {
            isNavigating = true
            withAnimation {
                if forward && currentIndex < screens.count - 1 {
                    currentIndex += 1
                } else if !forward && currentIndex > 0 {
                    currentIndex -= 1
                }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isNavigating = false
            }
        }
    }
    
    // Update ball movement function with improved collision detection
    private func moveBallContinuously() {
        Timer.scheduledTimer(withTimeInterval: 0.016, repeats: true) { timer in
            guard self.currentIndex == 3 else {
                timer.invalidate()
                return
            }
            
            let speed: CGFloat = 3.0
            let ballSize: CGFloat = 100
            let screenSize = UIScreen.main.bounds
            
            // Update position
            var newX = self.ballPosition.x + (self.moveDirection.x * speed)
            var newY = self.ballPosition.y + (self.moveDirection.y * speed)
            
            // Bounce off walls
            if newX <= ballSize/2 || newX >= screenSize.width - ballSize/2 {
                self.moveDirection.x *= -1
                newX = self.ballPosition.x + (self.moveDirection.x * speed)
            }
            if newY <= ballSize/2 || newY >= screenSize.height - ballSize/2 {
                self.moveDirection.y *= -1
                newY = self.ballPosition.y + (self.moveDirection.y * speed)
            }
            
            self.ballPosition = CGPoint(x: newX, y: newY)
        }
    }

    
    // Update notification generation function
    private func generateNotifications() {
        Timer.scheduledTimer(withTimeInterval: 1.5, repeats: true) { timer in
            guard self.currentIndex == 3 else {
                timer.invalidate()
                return
            }
            
            // Safe area insets to avoid buttons
            let topSafeArea: CGFloat = 100
            let bottomSafeArea: CGFloat = 120
            let sideSafeArea: CGFloat = 50
            
            let newNotification = (
                type: NotificationType.allCases.randomElement()!,
                position: CGPoint(
                    x: CGFloat.random(in: sideSafeArea...(UIScreen.main.bounds.width - sideSafeArea)),
                    y: CGFloat.random(in: topSafeArea...(UIScreen.main.bounds.height - bottomSafeArea))
                ),
                id: UUID()
            )
            
            withAnimation(.easeInOut(duration: 0.5)) {
                self.notifications.append(newNotification)
                if self.notifications.count > 8 {
                    self.notifications.removeFirst()
                }
            }
            
            // Remove notification after a random duration
            let lifetime = Double.random(in: 3...6)
            DispatchQueue.main.asyncAfter(deadline: .now() + lifetime) {
                withAnimation(.easeOut(duration: 0.5)) {
                    self.notifications.removeAll { $0.id == newNotification.id }
                }
            }
        }
    }
    
    // Add bell animation function
    private func startBellAnimation() {
        withAnimation(
            .easeInOut(duration: 0.5)
            .repeatForever(autoreverses: true)
        ) {
            bellScale = 1.1
        }
        
        withAnimation(
            .easeInOut(duration: 0.5)
            .repeatForever(autoreverses: true)
        ) {
            bellRotation = 20
        }
    }
    
    // Update reset function to include continuous ball movement
    private func resetAndStartAnimations() {
        // Reset and start bell animations
        bellScale = 1
        bellRotation = -20
        startBellAnimation()
        
        // Reset and restart glowing animation
        isGlowing = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(Animation.easeInOut(duration: 2.0).repeatForever()) {
                self.isGlowing = true
            }
        }
        
        // Reset ball position and restart movements
        ballPosition = CGPoint(x: 100, y: UIScreen.main.bounds.height / 2)
        moveDirection = CGPoint(x: 1, y: 1)
        moveBallContinuously()
        generateNotifications()
    }
    
    // Add these properties for animation control
    @State private var activeLineIndex = 0
    @State private var completedLines: Set<Int> = []
    @State private var allLinesComplete = false
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background gradient remains the same
                LinearGradient(
                    gradient: Gradient(colors: [
                        self.gradientColors[self.currentIndex].start,
                        self.gradientColors[self.currentIndex].end
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                .animation(.easeInOut(duration: 1.0), value: self.currentIndex)
                
                // Animated notifications
                if self.currentIndex == 3 {
                    ForEach(self.notifications, id: \.id) { notification in
                        Image(systemName: notification.type.rawValue)
                            .font(.system(size: 30))
                            .foregroundColor(.white.opacity(0.8))
                            .position(notification.position)
                            .transition(
                                .asymmetric(
                                    insertion: .scale(scale: 0.8)
                                        .combined(with: .opacity)
                                        .animation(.spring(response: 0.4, dampingFraction: 0.6)),
                                    removal: .scale(scale: 0.9)
                                        .combined(with: .opacity)
                                        .animation(.easeOut(duration: 0.5))
                                )
                            )
                    }
                }
                
                DistractionBackground()
                    .blur(radius: 20)
                
                // MainCircle integration for screen 4
                if self.currentIndex == 3 {
                    MainCircle(isGazingAtTarget: self.isGlowing, position: self.ballPosition)
                        .onAppear {
                            withAnimation(Animation.easeInOut(duration: 2.0).repeatForever()) {
                                self.isGlowing.toggle()
                            }
                            self.moveBallContinuously()
                            self.generateNotifications()
                        }
                }
                
                // Main content with gesture
                VStack {
                    // Back button remains the same
                    if self.currentIndex > 0 {
                        BackButtonView(isNavigating: self.isNavigating) {
                            self.navigate(forward: false)
                        }
                    }
                    
                    Spacer()
                    
                    // Content section update
                    IntroductionContentView(
                        screen: self.screens[self.currentIndex],
                        activeLineIndex: $activeLineIndex,
                        completedLines: $completedLines,
                        allLinesComplete: $allLinesComplete,
                        bellScale: $bellScale,
                        bellRotation: $bellRotation,
                        emojiScale: $emojiScale,
                        emojiRotation: $emojiRotation,
                        currentIndex: self.currentIndex
                    )
                    
                    Spacer()
                    
                    // Modified button with bounce animation
                    NavigationButtonView(
                        buttonText: self.screens[self.currentIndex].buttonText,
                        allLinesComplete: self.allLinesComplete,
                        isLastScreen: self.currentIndex == self.screens.count - 1
                    ) {
                        if self.currentIndex == self.screens.count - 1 {
                            self.showTutorial = true
                        } else {
                            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                                self.navigate(forward: true)
                                self.activeLineIndex = 0
                                self.completedLines.removeAll()
                                self.allLinesComplete = false
                            }
                        }
                    }
                }
                .padding()
                // Add gesture recognizer
                .gesture(
                    DragGesture()
                        .updating($dragOffset) { value, state, _ in
                            state = value.translation.width
                        }
                        .onEnded { value in
                            let threshold: CGFloat = 50
                            if value.translation.width > threshold && !self.isNavigating {
                                self.navigate(forward: false)
                            } else if value.translation.width < -threshold && !self.isNavigating {
                                self.navigate(forward: true)
                            }
                        }
                )
            }
        }
        .preferredColorScheme(.dark)
        .fullScreenCover(isPresented: $showTutorial) {
            TutorialView()
        }
        .onDisappear {
            // Clean up animations
            self.notifications.removeAll()
        }
        .onChange(of: self.currentIndex) { _, _ in
            // Reset animation state when screen changes
            self.activeLineIndex = 0
            self.completedLines.removeAll()
            self.allLinesComplete = false
        }
    }
}

// Extract the content section into a separate view
struct IntroductionContentView: View {
    // Properties remain the same
    let screen: Screen
    @Binding var activeLineIndex: Int
    @Binding var completedLines: Set<Int>
    @Binding var allLinesComplete: Bool
    @Binding var bellScale: CGFloat
    @Binding var bellRotation: Double
    @Binding var emojiScale: CGFloat
    @Binding var emojiRotation: CGFloat
    let currentIndex: Int
    
    var body: some View {
        VStack(spacing: 30) {
            // Updated emoji section with fixed bell animation
            if currentIndex == 3 {
                Text(screen.emoji)
                    .font(.system(size: 100))
                    .scaleEffect(bellScale)
                    .rotationEffect(.degrees(bellRotation))
                    .onAppear {
                        // Start bell animations immediately
                        withAnimation(
                            .easeInOut(duration: 0.5)
                            .repeatForever(autoreverses: true)
                        ) {
                            bellScale = 1.1
                        }
                        
                        withAnimation(
                            .easeInOut(duration: 0.5)
                            .repeatForever(autoreverses: true)
                        ) {
                            bellRotation = 20
                        }
                    }
                    .onDisappear {
                        // Reset bell animation when disappearing
                        withAnimation(.easeInOut) {
                            bellScale = 1
                            bellRotation = -20
                        }
                    }
                    .padding(.bottom, 30)
            } else {
                Text(screen.emoji)
                    .font(.system(size: 100))
                    .scaleEffect(emojiScale)
                    .rotationEffect(.degrees(emojiRotation))
                    .onAppear {
                        withAnimation(
                            .spring(response: 0.6, dampingFraction: 0.6)
                            .repeatForever(autoreverses: true)
                        ) {
                            emojiScale = 1.2
                        }
                        
                        withAnimation(
                            .easeInOut(duration: 2)
                            .repeatForever(autoreverses: true)
                        ) {
                            emojiRotation = 10
                        }
                    }
                    .onDisappear {
                        withAnimation(.easeInOut) {
                            emojiScale = 1
                            emojiRotation = 0
                        }
                    }
                    .padding(.bottom, 30)
            }
            
            // Rest of the view remains the same
            Text(screen.title)
                .font(.system(size: 42, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
                .transition(.scale.combined(with: .opacity))
                .id("title\(currentIndex)")
            
            VStack(alignment: .leading, spacing: 25) {
                ForEach(screen.content.indices, id: \.self) { index in
                    TypewriterText(
                        text: screen.content[index],
                        index: index,
                        activeIndex: $activeLineIndex
                    ) {
                        withAnimation {
                            completedLines.insert(index)
                            if index < screen.content.count - 1 {
                                activeLineIndex += 1
                            } else {
                                allLinesComplete = true
                            }
                        }
                    }
                    .transition(.asymmetric(
                        insertion: .move(edge: .leading).combined(with: .opacity),
                        removal: .move(edge: .trailing).combined(with: .opacity)
                    ))
                    .id("content\(currentIndex)\(index)")
                }
            }
            .padding(.top, 20)
            .padding(.horizontal)
        }
        .padding(.horizontal)
    }
}

// Back button view
struct BackButtonView: View {
    let isNavigating: Bool
    let action: () -> Void
    
    var body: some View {
        HStack {
            Button(action: action) {
                HStack {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 20, weight: .bold))
                    Text("Back")
                        .font(.system(size: 18, weight: .bold))
                }
                .foregroundColor(.white)
                .padding(.vertical, 8)
                .padding(.horizontal, 16)
                .background(
                    Capsule()
                        .fill(Color.white.opacity(0.2))
                        .overlay(Capsule().stroke(Color.white, lineWidth: 1))
                )
            }
            .padding(.leading, 20)
            .disabled(isNavigating)
            Spacer()
        }
        .padding(.top, 20)
    }
}

// Navigation button view
struct NavigationButtonView: View {
    let buttonText: String
    let allLinesComplete: Bool
    let isLastScreen: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Text(buttonText)
                    .font(.system(size: 22, weight: .bold, design: .rounded))
            }
            .foregroundColor(.white)
            .padding(.vertical, 16)
            .padding(.horizontal, 35)
            .background(
                Capsule()
                    .fill(Color.white.opacity(0.2))
                    .overlay(Capsule().stroke(Color.white, lineWidth: 1.5))
                    .shadow(color: .white.opacity(0.3), radius: 5, x: 0, y: 2)
            )
            // Only apply bounce animation when button is active
            .scaleEffect(allLinesComplete ? 1.1 : 1.0)
            // Only animate when button is active
            .animation(allLinesComplete ?
                .easeInOut(duration: 0.5).repeatForever(autoreverses: true) :
                .easeInOut(duration: 0.3),
                value: allLinesComplete
            )
        }
        .opacity(allLinesComplete ? 1 : 0.5)
        .disabled(!allLinesComplete)
        .padding(.bottom, 40)
    }
}

// DistractionBackground struct with fix
struct DistractionBackground: View {
    @State private var isAnimating = false
    
    var body: some View {
        ZStack {
            ForEach(0..<20) { _ in
                Circle()
                    .fill(Color.white.opacity(0.1))
                    .frame(width: CGFloat.random(in: 10...30))
                    .position(
                        x: CGFloat.random(in: 0...UIScreen.main.bounds.width),
                        y: CGFloat.random(in: 0...UIScreen.main.bounds.height)
                    )
                    .modifier(FloatingAnimation(isAnimating: isAnimating))
            }
        }
        .onAppear {
            isAnimating = true
        }
    }
}

// FloatingAnimation struct remains the same
struct FloatingAnimation: ViewModifier {
    let isAnimating: Bool
    
    func body(content: Content) -> some View {
        content
            .offset(y: isAnimating ? CGFloat.random(in: -20...20) : 0)
            .animation(
                Animation.easeInOut(duration: Double.random(in: 2...4))
                    .repeatForever(autoreverses: true),
                value: isAnimating
            )
    }
}

// Preview
struct IntroductionView_Previews: PreviewProvider {
    static var previews: some View {
        IntroductionView()
    }
}
