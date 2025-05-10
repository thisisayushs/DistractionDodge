//
//  OnboardingView.swift
//  DistractionDodge
//
//  Created by Ayush Kumar Singh on 21/01/25.
//

import SwiftUI
import SwiftData

#if os(visionOS)
struct OnboardingHologram: Identifiable { // Renamed to avoid conflict if Hologram exists elsewhere globally
    let id = UUID()
    var position: CGPoint
}

struct OnboardingHologramView: View { // Renamed for clarity
    var body: some View {
        Circle()
            .fill(Color.cyan.opacity(0.4))
            .frame(width: 70, height: 70) // Slightly smaller for onboarding
            .overlay(
                Circle()
                    .stroke(Color.cyan.opacity(0.7), lineWidth: 1.5)
                    .blur(radius: 2)
            )
            .shadow(color: .cyan.opacity(0.6), radius: 8, x: 0, y: 0)
            .transition(.scale.combined(with: .opacity))
    }
}
#endif


/// A view that provides an interactive introduction.
///
/// The OnboardingView presents a series of educational pages about focus and attention,
/// incorporating interactive elements and animations to demonstrate key concepts.
/// It serves as the entry point for the experience, providing context about focus challenges
/// and introducing the app's training approach.
struct OnboardingView: View {
    // MARK: - Properties
    
    /// Current page index in the onboarding flow
    @State private var currentIndex = 0
    
    /// Scale factor for emoji animations
    @State private var emojiScale: CGFloat = 1
    
    /// Rotation angle for emoji animations
    @State private var emojiRotation: CGFloat = 0
    
    /// Scale factor for SF symbols
    @State private var symbolScale: CGFloat = 1
    
    /// Controls navigation state to prevent rapid transitions
    @State private var isNavigating = false
    
    /// Opacity level for background distractions
    @State private var distractionOpacity: Double = 0.3
    
    /// Controls the glow effect animation
    @State private var isGlowing = false

    /// Position of the interactive ball demonstration
    @State private var ballPosition: CGPoint = .zero

    /// Timer for generating notifications in the demo (iOS)
    @State private var notificationTimer: Timer?
    
    /// Collection of active notification demonstrations (iOS)
    @State private var notifications: [(type: NotificationCategory, position: CGPoint, id: UUID)] = []
    
    #if os(visionOS)
    /// Timer for generating holograms in the demo (visionOS)
    @State private var onboardingHologramTimer: Timer?
    /// Collection of active hologram demonstrations (visionOS)
    @State private var activeOnboardingHolograms: [OnboardingHologram] = [] // USE OnboardingHologram
    #endif
    
    /// Direction vector for ball movement
    @State private var moveDirection = CGPoint(x: 1, y: 1)
    
    /// Controls navigation to main content
    @State private var showContentView = false
    
    /// Controls navigation to tutorial
    @State private var showTutorial = false
    
    /// Tracks drag gesture state
    @GestureState private var dragOffset: CGFloat = 0
    
    let gradientColors: [(start: Color, end: Color)] = [
        (.black.opacity(0.8), .blue.opacity(0.2)),
        (.black.opacity(0.8), .indigo.opacity(0.2)),
        (.black.opacity(0.8), .purple.opacity(0.2)),
        (.black.opacity(0.8), .cyan.opacity(0.2)),
        (.black.opacity(0.8), .blue.opacity(0.25))
    ]
    
    let pages: [Page] = [
        Page(
            title: "Where Did Our Focus Go?",
            content: [
                "In today's fast-paced, page-filled world, our attention is constantly under attack.",
                "Notifications, social media, and endless multitasking leave us feeling scattered and overwhelmed.",
                "Research shows that fragmented attention isn't just exhausting, it makes it harder to think deeply, stay productive, and feel at peace."
            ],
            sfSymbol: "brain.head.profile.fill",
            emoji: "🧠",
            buttonText: "Tell me more"
        ),
        Page(
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
        Page(
            title: "The Good News: You Can Retrain Your Brain",
            content: [
                "Focus isn't fixed, it's a skill you can strengthen with the right tools and practice.",
                "By training your brain to resist distractions, you can rebuild the deep focus needed to thrive in today's world."
            ],
            sfSymbol: "arrow.triangle.2.circlepath.circle.fill",
            emoji: "💪",
            buttonText: "How can I train?"
        ),
        Page(
            title: "How Distraction Dodge Helps You",
            content: [
                "Distraction Dodge is more than just a game, it's a tool to help you.",
                "Strengthen your focus through fun and engaging challenges.",
                "Learn to ignore digital distractions in a safe, controlled environment."
            ],
            sfSymbol: "target",
            emoji: "🔔",
            buttonText: "I'm ready"
        ),
        Page(
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
    
    @Query private var userProgress: [UserProgress]
    
    private var hasCompletedIntroduction: Bool {
        userProgress.first?.hasCompletedOnboarding ?? false
    }
    
    private func completeIntroduction() {
        showTutorial = true
    }
    
    private func navigate(forward: Bool) {
        if !isNavigating {
            isNavigating = true
            
            withAnimation {
                if forward && currentIndex < pages.count - 1 {
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
    
    private func moveBallContinuously() {
        guard viewSize != .zero else {
            print("OnboardingView: Cannot move ball, viewSize is zero.")
            return
        }
        Timer.scheduledTimer(withTimeInterval: 0.016, repeats: true) { timer in
            guard self.currentIndex == 3 else {
                timer.invalidate()
                return
            }
            
            guard self.viewSize != .zero else {
                timer.invalidate()
                return
            }

            let speed: CGFloat = 3.0
            let ballSize: CGFloat = 100
            let currentSize = self.viewSize
            
            var newX = self.ballPosition.x + (self.moveDirection.x * speed)
            var newY = self.ballPosition.y + (self.moveDirection.y * speed)
            
            if newX <= ballSize/2 || newX >= currentSize.width - ballSize/2 {
                self.moveDirection.x *= -1
                newX = self.ballPosition.x + (self.moveDirection.x * speed)
            }
            if newY <= ballSize/2 || newY >= currentSize.height - ballSize/2 {
                self.moveDirection.y *= -1
                newY = self.ballPosition.y + (self.moveDirection.y * speed)
            }
            
            self.ballPosition = CGPoint(
                x: max(ballSize/2, min(newX, currentSize.width - ballSize/2)),
                y: max(ballSize/2, min(newY, currentSize.height - ballSize/2))
            )
        }
    }
    
    private func generateNotifications() {
        guard viewSize != .zero else {
            print("OnboardingView: Cannot generate notifications, viewSize is zero.")
            return
        }
        notificationTimer?.invalidate()
        notificationTimer = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: true) { timer in
            guard self.currentIndex == 3 else {
                timer.invalidate()
                self.notificationTimer = nil
                return
            }
            
            guard self.viewSize != .zero else {
                timer.invalidate()
                self.notificationTimer = nil
                return
            }

            let topSafeArea: CGFloat = 100
            let bottomSafeArea: CGFloat = 120
            let sideSafeArea: CGFloat = 50
            
            let currentWidth = self.viewSize.width
            let currentHeight = self.viewSize.height
            
            guard currentWidth > sideSafeArea * 2 && currentHeight > topSafeArea + bottomSafeArea else {
                print("OnboardingView: View size too small for notification placement.")
                return
            }

            let minX = sideSafeArea
            let maxX = currentWidth - sideSafeArea
            let minY = topSafeArea
            let maxY = currentHeight - bottomSafeArea
            
            guard maxX > minX, maxY > minY else {
                print("OnboardingView: Calculated spawn range invalid for notifications.")
                return
            }

            let newNotification = (
                type: NotificationCategory.allCases.randomElement()!,
                position: CGPoint(
                    x: CGFloat.random(in: minX...maxX),
                    y: CGFloat.random(in: minY...maxY)
                ),
                id: UUID()
            )

            withAnimation(.easeInOut(duration: 0.5)) {
                self.notifications.append(newNotification)
                if self.notifications.count > 8 {
                    self.notifications.removeFirst()
                }
            }
            
            let lifetime = Double.random(in: 3...6)
            DispatchQueue.main.asyncAfter(deadline: .now() + lifetime) {
                withAnimation(.easeOut(duration: 0.5)) {
                    self.notifications.removeAll { $0.id == newNotification.id }
                }
            }
        }
    }
    
    private func generateOnboardingHolograms() { // visionOS specific
        #if os(visionOS) // Ensure this function's body is only for visionOS
        guard viewSize != .zero else {
            print("OnboardingView: Cannot generate holograms, viewSize is zero.")
            return
        }
        onboardingHologramTimer?.invalidate()
        onboardingHologramTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { timer in
            guard self.currentIndex == 3 else {
                timer.invalidate()
                self.onboardingHologramTimer = nil
                return
            }

            guard self.viewSize != .zero else {
                timer.invalidate()
                self.onboardingHologramTimer = nil
                return
            }
            
            let hologramDiameter: CGFloat = 70 // Using OnboardingHologramView's size
            let safePadding: CGFloat = 50

            let currentWidth = self.viewSize.width
            let currentHeight = self.viewSize.height

            guard currentWidth > hologramDiameter + safePadding * 2 && currentHeight > hologramDiameter + safePadding * 2 else {
                 print("OnboardingView: View size too small for hologram placement.")
                 return
            }

            let minX = hologramDiameter / 2 + safePadding
            let maxX = currentWidth - hologramDiameter / 2 - safePadding
            let minY = hologramDiameter / 2 + safePadding
            let maxY = currentHeight - hologramDiameter / 2 - safePadding

            guard maxX > minX, maxY > minY else {
                print("OnboardingView: Calculated spawn range invalid for holograms.")
                return
            }
            
            let newHologram = OnboardingHologram( // Use OnboardingHologram
                position: CGPoint(
                    x: CGFloat.random(in: minX...maxX),
                    y: CGFloat.random(in: minY...maxY)
                )
            )

            withAnimation(.spring()) {
                self.activeOnboardingHolograms.append(newHologram)
                if self.activeOnboardingHolograms.count > 5 {
                    self.activeOnboardingHolograms.removeFirst()
                }
            }

            let lifetime = Double.random(in: 4...7)
            DispatchQueue.main.asyncAfter(deadline: .now() + lifetime) {
                withAnimation(.easeOut(duration: 0.5)) {
                    self.activeOnboardingHolograms.removeAll { $0.id == newHologram.id }
                }
            }
        }
        #endif
    }
    
    private func resetAndStartAnimations() {
        guard viewSize != .zero else {
            print("OnboardingView: Cannot reset/start animations, viewSize is zero.")
            return
        }

        notificationTimer?.invalidate()
        notificationTimer = nil
        notifications.removeAll()

        #if os(visionOS)
        onboardingHologramTimer?.invalidate()
        onboardingHologramTimer = nil
        activeOnboardingHolograms.removeAll()
        #endif
        
        isGlowing = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(Animation.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                self.isGlowing = true
            }
        }

        ballPosition = CGPoint(x: viewSize.width / 2, y: viewSize.height / 2)
        moveDirection = CGPoint(x: CGFloat.random(in: -1...1).sign == .minus ? -1 : 1,
                                y: CGFloat.random(in: -1...1).sign == .minus ? -1 : 1)
        moveBallContinuously()

        #if os(iOS)
        generateNotifications()
        #elseif os(visionOS)
        generateOnboardingHolograms()
        #endif
    }
    
    @State private var viewSize: CGSize = .zero
    
    @State private var activeLineIndex = 0
    @State private var completedLines: Set<Int> = []
    @State private var allLinesComplete = false
    
    @State private var showSkipAlert = false
    
    @State private var shouldStopTextAnimation = false
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                #if os(iOS)
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
                #elseif os(visionOS)
                Color.clear.ignoresSafeArea()
                #endif

                if self.currentIndex == 3 {
                    #if os(iOS)
                    ForEach(self.notifications, id: \.id) { notification in
                        Image(systemName: notification.type.rawValue)
                            .font(.system(size: 30))
                            .foregroundColor(.white.opacity(0.8))
                            .position(notification.position)
                            .transition(
                                .asymmetric(
                                    insertion: .scale(scale: 0.8).combined(with: .opacity).animation(.spring(response: 0.4, dampingFraction: 0.6)),
                                    removal: .scale(scale: 0.9).combined(with: .opacity).animation(.easeOut(duration: 0.5))
                                )
                            )
                    }
                    #elseif os(visionOS)
                    ForEach(self.activeOnboardingHolograms) { hologram in // Use activeOnboardingHolograms
                        OnboardingHologramView() // Use OnboardingHologramView
                            .position(hologram.position)
                            .transition(.scale.combined(with: .opacity))
                    }
                    #endif
                }
                
                #if os(iOS)
                DistractionBackground()
                    .blur(radius: 20)
                #endif
                
                if self.currentIndex == 3 {
                    MainCircle(isGazingAtTarget: self.isGlowing, position: self.ballPosition)
                }
                
                VStack {
                    HStack {
                        #if os(iOS)
                        if self.currentIndex > 0 {
                            Button(action: {
                                self.navigate(forward: false)
                            }) {
                                HStack {
                                    Image(systemName: "chevron.left")
                                        .font(.system(size: 20, weight: .bold))
                                    Text("Back")
                                        .font(.system(size: 17, weight: .medium, design: .rounded))
                                }
                                .foregroundColor(.white.opacity(0.7))
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(
                                    Capsule()
                                        .fill(Color.white.opacity(0.15))
                                        .overlay(Capsule().stroke(Color.white.opacity(0.3), lineWidth: 1))
                                )
                            }
                            .disabled(isNavigating)
                        }
                        #endif
                        
                        Spacer()
                        
                        Button(action: {
                            showSkipAlert = true
                        }) {
                            Text("Skip")
                                .font(.system(size: 17, weight: .medium, design: .rounded))
                                .foregroundColor(.white.opacity(0.7))
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                #if os(iOS)
                                .background(
                                    Capsule()
                                        .fill(Color.white.opacity(0.15))
                                        .overlay(Capsule().stroke(Color.white.opacity(0.3), lineWidth: 1))
                                )
                                #endif
                        }
                        #if os(visionOS)
                        .buttonStyle(.plain)
                        .padding([.top, .trailing], 25)
                        #endif
                    }
                    #if os(iOS)
                    .padding(.top, 20)
                    .padding(.horizontal, 20)
                    #elseif os(visionOS)
                    .frame(height: 50)
                    #endif
                    
                    Spacer()
                    
                    OnboardingContentView(
                        page: self.pages[self.currentIndex],
                        currentIndex: self.currentIndex,
                        activeLineIndex: $activeLineIndex,
                        completedLines: $completedLines,
                        allLinesComplete: $allLinesComplete,
                        emojiScale: $emojiScale,
                        emojiRotation: $emojiRotation,
                        shouldStopTextAnimation: $shouldStopTextAnimation
                    )
                    
                    Spacer()
                    
                    NavigationButton(
                        buttonText: self.pages[self.currentIndex].buttonText,
                        allLinesComplete: self.allLinesComplete,
                        isLastScreen: self.currentIndex == self.pages.count - 1
                    ) {
                        if self.currentIndex == self.pages.count - 1 {
                            completeIntroduction()
                        } else {
                            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                                self.navigate(forward: true)
                                self.activeLineIndex = 0
                                self.completedLines.removeAll()
                                self.allLinesComplete = false
                            }
                        }
                    }
                    #if os(visionOS)
                    .padding(.bottom, geometry.safeAreaInsets.bottom > 0 ? geometry.safeAreaInsets.bottom : 30)
                    .padding(.horizontal, 40)
                    #endif
                }
                #if os(visionOS)
                .padding(.bottom, 30)
                #elseif os(iOS)
                .padding(.bottom, 30)
                #endif
                
                .gesture(
                    DragGesture()
                        .updating($dragOffset) { value, state, _ in state = value.translation.width }
                        .onEnded { value in
                            let threshold: CGFloat = 50
                            if value.translation.width > threshold && !self.isNavigating { self.navigate(forward: false) }
                            else if value.translation.width < -threshold && !self.isNavigating { self.navigate(forward: true) }
                        }
                )
                
                #if os(iOS)
                .overlay {
                    if showSkipAlert {
                        AlertView(
                            title: "Skip Introduction?",
                            message: "You are about to skip the introduction. You will be taken to the tutorial.",
                            primaryAction: { showTutorial = true; showSkipAlert = false },
                            secondaryAction: { showSkipAlert = false },
                            isPresented: $showSkipAlert
                        )
                    }
                }
                #elseif os(visionOS)
                .alert("Skip Introduction?", isPresented: $showSkipAlert) {
                    Button("Skip", role: .destructive) { showTutorial = true }
                    Button("Cancel", role: .cancel) {}
                } message: {
                    Text("You are about to skip the introduction. You will be taken to the tutorial.")
                }
                #endif
            }
            .onAppear {
                if self.viewSize == .zero {
                    self.viewSize = geometry.size
                    self.ballPosition = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)
                    if self.currentIndex == 3 {
                        resetAndStartAnimations()
                    }
                }
            }
            .onChange(of: geometry.size) { oldSize, newSize in
                if newSize != .zero && newSize != oldSize {
                    self.viewSize = newSize
                    self.ballPosition.y = newSize.height / 2
                    self.ballPosition.x = newSize.width / 2
                    if self.currentIndex == 3 {
                        resetAndStartAnimations()
                    }
                }
            }
        }
        .onChange(of: currentIndex) { oldValue, newValue in
            self.activeLineIndex = 0
            self.completedLines.removeAll()
            self.allLinesComplete = false
            
            if newValue == 3 {
                if self.viewSize != .zero {
                    resetAndStartAnimations()
                }
            } else {
                notificationTimer?.invalidate()
                notificationTimer = nil
                notifications.removeAll()
                
                #if os(visionOS)
                onboardingHologramTimer?.invalidate()
                onboardingHologramTimer = nil
                activeOnboardingHolograms.removeAll()
                #endif
                
                isGlowing = false
            }
        }
        .onChange(of: allLinesComplete) { _, newAllLinesComplete in }
        .onChange(of: showTutorial) { _, willShow in if willShow { shouldStopTextAnimation = true } }
        .onChange(of: showContentView) { _, willShow in if willShow { shouldStopTextAnimation = true } }
        .fullScreenCover(isPresented: $showContentView) { Home() }
        .fullScreenCover(isPresented: $showTutorial) {
            #if os(iOS)
            TutorialView()
            #elseif os(visionOS)
            visionOSTutorialView()
            #endif
        }
        .preferredColorScheme(.dark)
        #if os(iOS)
        .statusBarHidden(true)
        .persistentSystemOverlays(.hidden)
        #endif
        .onDisappear {
            notificationTimer?.invalidate()
            notificationTimer = nil
            self.notifications.removeAll()

            #if os(visionOS)
            onboardingHologramTimer?.invalidate()
            onboardingHologramTimer = nil
            self.activeOnboardingHolograms.removeAll()
            #endif
            
            isGlowing = false
        }
    }
}
