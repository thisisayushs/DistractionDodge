//
//  TutorialView.swift
//  AttentionApp
//

import SwiftUI

struct TutorialStep: Identifiable {
    let id = UUID()
    let title: String
    let description: [String]
    let scoringType: ScoringType
}

enum ScoringType {
    case introduction
    case baseScoring
    case multiplier
    case streakBonus
    case penalty
    case distractions
    case summary
}

// Add this elegant text modifier at the top of the file, after other modifiers
struct ElegantTextEffect: ViewModifier {
    let isShowing: Bool
    let style: TextStyle
    
    enum TextStyle {
        case bonus
        case penalty
    }
    
    func body(content: Content) -> some View {
        content
            .opacity(isShowing ? 1 : 0)
            .scaleEffect(isShowing ? 1 : 0.8)
            .rotationEffect(.degrees(isShowing ? 0 : style == .bonus ? -10 : 10))
            .offset(y: isShowing ? 0 : style == .bonus ? 20 : -20)
            .blur(radius: isShowing ? 0 : 5)
            .animation(
                .spring(response: 0.6, dampingFraction: 0.7)
                .speed(0.8),
                value: isShowing
            )
    }
}

struct FloatingScoreModifier: ViewModifier {
    let isShowing: Bool
    
    func body(content: Content) -> some View {
        content
            .opacity(isShowing ? 1 : 0)
            .scaleEffect(isShowing ? 1.2 : 0.8)
            .offset(y: isShowing ? -50 : 0)
            .animation(
                .spring(response: 0.6, dampingFraction: 0.7)
                .speed(0.7),
                value: isShowing
            )
    }
}

struct TutorialView: View {
    @State private var currentStep = 0
    @State private var showContentView = false
    @State private var demoPosition = CGPoint(x: UIScreen.main.bounds.width / 2,
                                              y: UIScreen.main.bounds.height * 0.15)
    @State private var demoIsGazing = false
    @State private var demoScore = 0
    @State private var demoStreak = 0
    @State private var showScoreCard = false
    @State private var showMultiplierCard = false
    @State private var showPenaltyCard = false
    @State private var showDemoDistraction = false
    @State private var demoMultiplier = 1
    @State private var showScoreIncrementIndicator = false
    @State private var showBonusIndicator = false
    @State private var showPenaltyIndicator = false
    @State private var elapsedTime: Int = 0
    @State private var streakTime: Int = 0
    @State private var penaltyTimer: Timer? = nil
    
    @State private var isMovingBall = false
    @State private var moveDirection = CGPoint(x: 1, y: 1)
    @State private var hasDemonstratedFollowing = false
    @State private var showNextButton = false
    @State private var customPosition = CGPoint(x: UIScreen.main.bounds.width / 2,
                                              y: UIScreen.main.bounds.height * 0.15)
    @State private var nextButtonScale: CGFloat = 1.0

    @State private var showTutorialGameSummary = false
    @State private var isNavigating = false
    @GestureState private var dragOffset: CGFloat = 0
    @State private var showSkipAlert = false  // Add this line

    let tutorialSteps = [
        TutorialStep(
            title: "Prepare to Train Your Focus",
            description: [
                "Position your device steadily so your face is clearly visible to the camera.",
                "Look at the circle until it starts glowing.",
                "Now follow the moving circle with your eyes.",
                "Great! You've mastered the basics. Tap 'Next' to continue."
            ],
            scoringType: .introduction
        ),
        TutorialStep(
            title: "Stay Focused Despite Distractions",
            description: [
                "Keep your eyes on the moving circle while notifications appear.",
                "Remember: Looking at or tapping notifications ends your training.",
                "The most challenging part will be resisting the urge to tap interesting notifications."
            ],
            scoringType: .distractions
        ),
        TutorialStep(
            title: "Base Scoring",
            description: [
                "Every second of focus counts! Watch your score grow as you maintain your gaze."
            ],
            scoringType: .baseScoring
        ),
        TutorialStep(
            title: "Score Multipliers",
            description: [
                "Keep focusing to increase your multiplier! Every 5 seconds, your points multiply.",
            ],
            scoringType: .multiplier
        ),
        TutorialStep(
            title: "Streak Bonuses",
            description: [
                "Maintain focus for 10 seconds to earn bonus points!",
            ],
            scoringType: .streakBonus
        ),
        TutorialStep(
            title: "Breaking Focus",
            description: [
                "Be careful! Looking away has consequences.",
            ],
            scoringType: .penalty
        )
    ]
    
    private func navigate(forward: Bool) {
        if !isNavigating {
            isNavigating = true
            
            // Explicitly stop bounce animation before transitioning
            withAnimation(.easeOut) {
                showNextButton = false
                nextButtonScale = 1.0
            }
            
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                if forward && currentStep < tutorialSteps.count - 1 {
                    currentStep += 1
                } else if !forward && currentStep > 0 {
                    currentStep -= 1
                }
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isNavigating = false
            }
        }
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background gradient with animation
                LinearGradient(
                    gradient: Gradient(colors: [.black.opacity(0.8), .blue.opacity(0.2)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                .animation(.easeInOut(duration: 1.0), value: currentStep)
                
                // Add skip button overlay
                VStack {
                    HStack {
                        Spacer()
                        Button(action: {
                            showSkipAlert = true
                        }) {
                            Text("Skip")
                                .font(.system(size: 17, weight: .medium, design: .rounded))
                                .foregroundColor(.white.opacity(0.7))
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(
                                    Capsule()
                                        .fill(Color.white.opacity(0.15))
                                        .overlay(
                                            Capsule()
                                                .stroke(Color.white.opacity(0.3), lineWidth: 1)
                                        )
                                )
                        }
                        .padding(.top, 50)
                        .padding(.trailing, 20)
                    }
                    Spacer()
                }
                
                VStack(spacing: 0) {
                    // Title with transition
                    Text(tutorialSteps[currentStep].title)
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .padding(.top, 60)
                        .padding(.bottom, 10)
                        .padding(.horizontal)
                        .multilineTextAlignment(.center)
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing).combined(with: .opacity),
                            removal: .move(edge: .leading).combined(with: .opacity)
                        ))
                        .id("title\(currentStep)")
                    
                    // Description with transition
                    Text(currentStep == 0 ?
                        tutorialSteps[0].description[isMovingBall ? 2 :
                                                  (hasDemonstratedFollowing ? 3 :
                                                   (demoIsGazing ? 1 : 0))] :
                        tutorialSteps[currentStep].description[0])
                        .font(.system(size: 20, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.9))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 30)
                        .padding(.bottom, 40)
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing).combined(with: .opacity),
                            removal: .move(edge: .leading).combined(with: .opacity)
                        ))
                        .id("description\(currentStep)")
                        .animation(.easeInOut, value: isMovingBall)
                        .animation(.easeInOut, value: hasDemonstratedFollowing)
                        .animation(.easeInOut, value: demoIsGazing)
                    
                    // Main content area with fixed placement
                    VStack(spacing: 80) {
                        switch tutorialSteps[currentStep].scoringType {
                        case .introduction:
                            ZStack {
                                // EyeTrackingView remains the same
                                EyeTrackingView { isGazing in
                                    if self.demoIsGazing != isGazing {
                                        self.demoIsGazing = isGazing
                                        if isGazing && !isMovingBall && !hasDemonstratedFollowing {
                                            // Start ball movement after 2 seconds of successful gazing
                                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                                withAnimation {
                                                    isMovingBall = true
                                                    self.startBallMovement()
                                                }
                                            }
                                            
                                            // Stop movement and reset after 8 seconds
                                            DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
                                                withAnimation(.easeInOut(duration: 0.5)) {
                                                    isMovingBall = false
                                                    hasDemonstratedFollowing = true
                                                    // Reset ball position
                                                    customPosition = CGPoint(x: UIScreen.main.bounds.width / 2,
                                                                            y: UIScreen.main.bounds.height * 0.15)
                                                    // Show next button guidance and start bounce animation
                                                    showNextButton = true
                                                    withAnimation(
                                                        .easeInOut(duration: 0.5)
                                                        .repeatForever(autoreverses: true)
                                                    ) {
                                                        nextButtonScale = 1.1
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                                
                                VStack(spacing: 60) {
                                    // Instruction text at top changes with circle movement
                                    HStack {
                                        Image(systemName: "eye")
                                            .font(.system(size: 24))
                                        Text(isMovingBall ? "Keep following the circle" : "Gaze Detected")
                                            .font(.system(size: 18, weight: .medium, design: .rounded))
                                    }
                                    .foregroundColor(demoIsGazing ? .green : .white.opacity(0.5))
                                    .padding(.vertical, 8)
                                    .padding(.horizontal, 16)
                                    .background(
                                        Capsule()
                                            .fill(Color.white.opacity(0.15))
                                    )
                                    .shadow(color: demoIsGazing ? .green.opacity(0.5) : .clear, radius: 10)
                                    
                                    Spacer()
                                    
                                    // Ball with custom position
                                    MainCircle(isGazingAtTarget: demoIsGazing,
                                              position: customPosition)
                                        .padding(.bottom, 100)
                                    
                                    Spacer()
                                }
                                .frame(maxHeight: .infinity, alignment: .top)
                                .padding(.top, 40)
                                
                                // Bottom instructions
                                
                            }
                            .id("introduction\(currentStep)")
                            .onDisappear {
                                cleanupCurrentDemo()
                            }
                        
                        case .baseScoring:
                            VStack(spacing: 40) {
                                Text("Score: \(demoScore)")
                                    .font(.system(size: 48, weight: .bold, design: .rounded))
                                    .foregroundStyle(
                                        .linearGradient(
                                            colors: [.white, .cyan],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                
                                MainCircle(isGazingAtTarget: true,
                                          position: CGPoint(x: UIScreen.main.bounds.width / 2,
                                                           y: UIScreen.main.bounds.height * 0.22))
                                    .overlay(
                                        Text("+1")
                                            .font(.system(size: 28, weight: .bold, design: .rounded))
                                            .foregroundStyle(
                                                .linearGradient(
                                                    colors: [.yellow, .orange],
                                                    startPoint: .top,
                                                    endPoint: .bottom
                                                )
                                            )
                                            .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
                                            .modifier(FloatingScoreModifier(isShowing: showScoreIncrementIndicator))
                                    )
                                    .onAppear {
                                        startBaseScoring()
                                    }
                            }
                            .id("scoring\(currentStep)")
                            .onDisappear {
                                cleanupCurrentDemo()
                            }
                        
                        case .multiplier:
                            VStack(spacing: 40) {
                                HStack(spacing: 30) {
                                    // Score display
                                    VStack(alignment: .center) {
                                        Text("Score")
                                            .font(.system(size: 20, weight: .medium, design: .rounded))
                                        Text("\(demoScore)")
                                            .font(.system(size: 36, weight: .bold, design: .rounded))
                                            .foregroundStyle(.white)
                                    }
                                    
                                    // Added timer display
                                    VStack(alignment: .center) {
                                        Text("Time")
                                            .font(.system(size: 20, weight: .medium, design: .rounded))
                                        Text("\(elapsedTime)s")
                                            .font(.system(size: 36, weight: .bold, design: .rounded))
                                            .foregroundStyle(.white)
                                    }
                                    
                                    // Multiplier display
                                    VStack(alignment: .center) {
                                        Text("Multiplier")
                                            .font(.system(size: 20, weight: .medium, design: .rounded))
                                        Text("×\(demoMultiplier)")
                                            .font(.system(size: 36, weight: .bold, design: .rounded))
                                            .foregroundStyle(
                                                .linearGradient(
                                                    colors: [.orange, .red],
                                                    startPoint: .leading,
                                                    endPoint: .trailing
                                                )
                                            )
                                    }
                                }
                                .padding(.vertical, 20)
                                .padding(.horizontal, 40)
                                .background(
                                    RoundedRectangle(cornerRadius: 20)
                                        .fill(Color.white.opacity(0.15))
                                )
                                
                                MainCircle(isGazingAtTarget: true,
                                          position: CGPoint(x: UIScreen.main.bounds.width / 2,
                                                           y: UIScreen.main.bounds.height * 0.20))
                                    .onAppear {
                                        startMultiplierDemo()
                                    }
                            }
                            .id("multiplier\(currentStep)")
                            .onDisappear {
                                cleanupCurrentDemo()
                            }
                        
                        case .streakBonus:
                            VStack(spacing: 40) {
                                HStack(spacing: 30) {
                                    // Score display
                                    VStack(alignment: .center) {
                                        Text("Score")
                                            .font(.system(size: 20, weight: .medium, design: .rounded))
                                        Text("\(demoScore)")
                                            .font(.system(size: 36, weight: .bold, design: .rounded))
                                            .foregroundStyle(.white)
                                    }
                                    
                                    // Streak display
                                    VStack(alignment: .center) {
                                        Text("Streak")
                                            .font(.system(size: 20, weight: .medium, design: .rounded))
                                        Text("\(demoStreak)s")
                                            .font(.system(size: 36, weight: .bold, design: .rounded))
                                            .foregroundStyle(
                                                .linearGradient(
                                                    colors: [.yellow, .orange],
                                                    startPoint: .leading,
                                                    endPoint: .trailing
                                                )
                                            )
                                    }
                                }
                                .padding(.vertical, 20)
                                .padding(.horizontal, 40)
                                .background(
                                    RoundedRectangle(cornerRadius: 20)
                                        .fill(Color.white.opacity(0.15))
                                )
                                
                                if showBonusIndicator {
                                    Text("+5 BONUS!")
                                        .font(.system(size: 32, weight: .heavy, design: .rounded))
                                        .foregroundStyle(
                                            .linearGradient(
                                                colors: [.yellow, .orange],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                        .modifier(ElegantTextEffect(isShowing: showBonusIndicator, style: .bonus))
                                }
                                
                                MainCircle(isGazingAtTarget: true,
                                          position: CGPoint(x: UIScreen.main.bounds.width / 2,
                                                           y: UIScreen.main.bounds.height * 0.20))
                                    .scaleEffect(showBonusIndicator ? 1.1 : 1.0)
                                    .onAppear {
                                        startStreakBonusDemo()
                                    }
                            }
                            .id("streak\(currentStep)")
                            .onDisappear {
                                cleanupCurrentDemo()
                            }
                        
                        case .penalty:
                            VStack(spacing: 40) {
                                HStack(spacing: 30) {
                                    // Score display with potentially reset value
                                    VStack(alignment: .center) {
                                        Text("Score")
                                            .font(.system(size: 20, weight: .medium, design: .rounded))
                                        Text("\(demoScore)")
                                            .font(.system(size: 36, weight: .bold, design: .rounded))
                                            .foregroundStyle(.white)
                                    }
                                    
                                    // Penalty display remains the same
                                    VStack(alignment: .center) {
                                        Text("Penalty")
                                            .font(.system(size: 20, weight: .medium, design: .rounded))
                                        Text("-\(min(demoStreak, 10))")
                                            .font(.system(size: 36, weight: .bold, design: .rounded))
                                            .foregroundStyle(
                                                .linearGradient(
                                                    colors: [.red, .purple],
                                                    startPoint: .leading,
                                                    endPoint: .trailing
                                                )
                                            )
                                    }
                                }
                                .padding(.vertical, 20)
                                .padding(.horizontal, 40)
                                .background(
                                    RoundedRectangle(cornerRadius: 20)
                                        .fill(Color.white.opacity(0.15))
                                )
                                
                                if showPenaltyIndicator {
                                    Text("Focus Lost!")
                                        .font(.system(size: 32, weight: .heavy, design: .rounded))
                                        .foregroundColor(.red)
                                        .transition(.scale.combined(with: .opacity))
                                }
                                
                                MainCircle(isGazingAtTarget: !showPenaltyIndicator,
                                          position: CGPoint(x: geometry.size.width / 2,
                                           y: geometry.size.height / 5))
                                    .onAppear {
                                        startPenaltyDemo()
                                    }
                            }
                            .id("penalty\(currentStep)")
                            .onDisappear {
                                cleanupCurrentDemo()
                            }
                        
                        case .summary:
                            ScrollView {
                                // Summary cards remain the same
                            }
                            .id("summary\(currentStep)")
                        
                        case .distractions:
                            ZStack {
                                // EyeTrackingView and VStack remain the same
                                EyeTrackingView { isGazing in
                                    self.demoIsGazing = isGazing
                                }
                                
                                VStack(spacing: 60) {
                                    // Gaze tracking indicator
                                    HStack {
                                        Image(systemName: "eye")
                                            .font(.system(size: 24))
                                        Text("Keep Following")
                                            .font(.system(size: 18, weight: .medium, design: .rounded))
                                    }
                                    .foregroundColor(demoIsGazing ? .green : .white.opacity(0.5))
                                    .padding(.vertical, 8)
                                    .padding(.horizontal, 16)
                                    .background(
                                        Capsule()
                                            .fill(Color.white.opacity(0.15))
                                    )
                                    .shadow(color: demoIsGazing ? .green.opacity(0.5) : .clear, radius: 10)
                                    
                                    Spacer()
                                    
                                    // Moving ball continues from previous screen
                                    MainCircle(isGazingAtTarget: demoIsGazing,
                                              position: customPosition)
                                        .padding(.bottom, 100)
                                    
                                    Spacer()
                                }
                                
                                // Update to use actual NotificationView but non-interactive
                                if showDemoDistraction {
                                    NotificationView(
                                        distraction: Distraction(
                                            position: CGPoint(x: UIScreen.main.bounds.width * 0.7,
                                                            y: UIScreen.main.bounds.height * 0.4),
                                            title: "Messages",
                                            message: "🎮 Game night tonight?",
                                            appIcon: "message.fill",
                                            iconColors: [.green, .blue],
                                            soundID: 1007
                                        ),
                                        index: 0
                                    )
                                    .environmentObject(AttentionViewModel())
                                    .allowsHitTesting(false) // Make entire notification non-interactive
                                    .transition(.opacity.combined(with: .scale(scale: 0.9)))
                                }
                            }
                            .sheet(isPresented: $showTutorialGameSummary) {
                                GameSummaryView(
                                    viewModel: AttentionViewModel(),
                                    isPresented: $showTutorialGameSummary
                                )
                            }
                            .onAppear {
                                // Continue ball movement from previous screen
                                if !isMovingBall {
                                    isMovingBall = true
                                    startBallMovement()
                                }
                                // Start showing distractions
                                startDistractionDemo()
                            }
                            .id("distractions\(currentStep)")
                            .onDisappear {
                                cleanupCurrentDemo()
                            }
                       
                        }
                    }
                    .frame(height: geometry.size.height * 0.4)
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))
                    
                    Spacer()
                    
                    // Navigation buttons with animation
                    HStack(spacing: 20) {
                        if currentStep > 0 {
                            Button(action: { navigate(forward: false) }) {
                                HStack {
                                    Image(systemName: "chevron.left")
                                    Text("Previous")
                                        .font(.system(size: 17, weight: .medium, design: .rounded))
                                }
                                .foregroundColor(.white)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 10)
                                .background(Capsule().fill(Color.white.opacity(0.2)))
                            }
                            .transition(.move(edge: .trailing).combined(with: .opacity))
                            .disabled(isNavigating)
                        }
                        
                        Button(action: {
                            if currentStep < tutorialSteps.count - 1 {
                                navigate(forward: true)
                            } else {
                                showContentView = true
                            }
                        }) {
                            HStack {
                                Text(currentStep == tutorialSteps.count - 1 ? "Start Game" : "Next")
                                    .font(.system(size: 17, weight: .medium, design: .rounded))
                                if currentStep < tutorialSteps.count - 1 {
                                    Image(systemName: "chevron.right")
                                }
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(Capsule().fill(Color.white.opacity(0.2)))
                            .scaleEffect(showNextButton ? nextButtonScale : 1.0)
                        }
                        .disabled(isNavigating)
                    }
                    .padding(.bottom, 50)
                }
                .padding()
                // Gesture recognizer for swipe navigation
                .gesture(
                    DragGesture()
                        .updating($dragOffset) { value, state, _ in
                            state = value.translation.width
                        }
                        .onEnded { value in
                            let threshold: CGFloat = 50
                            if !isNavigating {
                                if value.translation.width > threshold {
                                    navigate(forward: false)
                                } else if value.translation.width < -threshold {
                                    navigate(forward: true)
                                }
                            }
                        }
                )
            }
        }
        .onChange(of: currentStep) { oldValue, newValue in
            cleanupCurrentDemo()
            resetStateForStep(newValue)
        }
        .preferredColorScheme(.dark)
        .fullScreenCover(isPresented: $showContentView) {
            ContentView()
        }
        .animation(.spring(response: 0.6, dampingFraction: 0.7), value: currentStep)
        .alert("Skip Tutorial?", isPresented: $showSkipAlert) {
            Button("Skip", role: .destructive) {
                showContentView = true
            }
            Button("Continue Tutorial", role: .cancel) {}
        } message: {
            Text("You are about to skip the tutorial, You will be taken directly to the game.")
        }
    }
    
    private func startBaseScoring() {
        demoScore = 0
        showNextButton = false
        nextButtonScale = 1.0
        
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            guard tutorialSteps[currentStep].scoringType == .baseScoring else {
                timer.invalidate()
                return
            }
            
            withAnimation {
                demoScore += 1
                showScoreIncrementIndicator = true
                
                if demoScore == 10 {
                    demoScore = 0 // Reset to zero at exactly 100
                    // Start next button bounce animation
                    showNextButton = true
                    withAnimation(
                        .easeInOut(duration: 0.5)
                        .repeatForever(autoreverses: true)
                    ) {
                        nextButtonScale = 1.1
                    }
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    withAnimation {
                        showScoreIncrementIndicator = false
                    }
                }
            }
        }
    }
    
    private func startMultiplierDemo() {
        demoScore = 0
        demoMultiplier = 1
        elapsedTime = 0
        showNextButton = false
        nextButtonScale = 1.0
        var hasStartedBounce = false
        
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            guard tutorialSteps[currentStep].scoringType == .multiplier else {
                timer.invalidate()
                return
            }
            
            withAnimation {
                elapsedTime += 1
                demoScore += demoMultiplier
                
                // Update multiplier every 5 seconds, cap at 3
                if elapsedTime % 5 == 0 && demoMultiplier < 3 {
                    demoMultiplier += 1
                }
                
                // Reset at 60 seconds and start bounce
                if elapsedTime >= 60 && !hasStartedBounce {
                    hasStartedBounce = true
                    demoScore = 0
                    demoMultiplier = 1
                    elapsedTime = 0
                    
                    // Start next button bounce
                    showNextButton = true
                    withAnimation(
                        .easeInOut(duration: 0.5)
                        .repeatForever(autoreverses: true)
                    ) {
                        nextButtonScale = 1.1
                    }
                }
                
                // Reset values at 60 seconds
                if elapsedTime >= 60 {
                    demoScore = 0
                    demoMultiplier = 1
                    elapsedTime = 0
                }
            }
        }
    }
    
    private func startStreakBonusDemo() {
        demoScore = 0
        demoStreak = 0
        streakTime = 0
        showBonusIndicator = false
        showNextButton = false
        nextButtonScale = 1.0
        var hasStartedBounce = false
        
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            guard tutorialSteps[currentStep].scoringType == .streakBonus else {
                timer.invalidate()
                return
            }
            
            streakTime += 1
            demoStreak += 1
            demoScore += 1
            
            if demoStreak % 10 == 0 {
                withAnimation(.spring(duration: 0.5)) {
                    showBonusIndicator = true
                    demoScore += 5
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    withAnimation {
                        showBonusIndicator = false
                    }
                }
            }
            
            // Reset at 60 seconds and start bounce
            if streakTime >= 60 && !hasStartedBounce {
                hasStartedBounce = true
                withAnimation {
                    demoScore = 0
                    demoStreak = 0
                    streakTime = 0
                    
                    // Start next button bounce
                    showNextButton = true
                    withAnimation(
                        .easeInOut(duration: 0.5)
                        .repeatForever(autoreverses: true)
                    ) {
                        nextButtonScale = 1.1
                    }
                }
            }
            
            // Continue resetting values at 60 seconds
            if streakTime >= 60 {
                demoScore = 0
                demoStreak = 0
                streakTime = 0
            }
        }
    }

    private func startPenaltyDemo() {
        demoScore = 30
        demoStreak = 8
        showPenaltyIndicator = false
        showNextButton = false
        nextButtonScale = 1.0
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation(.easeInOut(duration: 0.5)) {
                showPenaltyIndicator = true
                demoScore = max(0, demoScore - min(demoStreak, 10))
                
                // Start button bounce when focus is lost
                showNextButton = true
                withAnimation(
                    .easeInOut(duration: 0.5)
                    .repeatForever(autoreverses: true)
                ) {
                    nextButtonScale = 1.1
                }
            }
            
            // Reset score after 2 seconds (original behavior)
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                demoScore = 30
                demoStreak = 8
                withAnimation {
                    showPenaltyIndicator = false
                }
            }
        }
    }

    private func startDistractionDemo() {
        var distractionCount = 0
        isMovingBall = true
        startBallMovement()
        showDemoDistraction = false  // Ensure it starts hidden
        
        Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { timer in
            guard currentStep == 1 && isMovingBall else {
                timer.invalidate()
                return
            }
            
            distractionCount += 1
            if distractionCount >= 3 {
                timer.invalidate()
                showDemoDistraction = false // Hide notification before ending
                
                // After last distraction, wait 2 seconds then return ball to center
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    withAnimation(.easeInOut(duration: 1.0)) {
                        isMovingBall = false
                        customPosition = CGPoint(x: UIScreen.main.bounds.width / 2,
                                               y: UIScreen.main.bounds.height * 0.15)
                    }
                    
                    // Start button bounce and keep it bouncing
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                        showNextButton = true
                        withAnimation(
                            .easeInOut(duration: 0.5)
                            .repeatForever(autoreverses: true)
                        ) {
                            nextButtonScale = 1.1
                        }
                    }
                }
                return
            }
            
            // Show notification with proper animation
            withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                showDemoDistraction = true
            }
            
            // Auto-dismiss after 2 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                withAnimation(.easeOut) {
                    showDemoDistraction = false
                    
                    // Show again after a brief pause
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                            showDemoDistraction = true
                        }
                    }
                }
            }
        }
    }
    
    private func startBallMovement() {
        let speed: CGFloat = 2.0 // Slower speed for tutorial
        Timer.scheduledTimer(withTimeInterval: 0.016, repeats: true) { timer in
            guard isMovingBall else {
                timer.invalidate()
                return
            }
            
            let ballSize: CGFloat = 100
            let screenSize = UIScreen.main.bounds
            
            var newX = self.customPosition.x + (self.moveDirection.x * speed)
            var newY = self.customPosition.y + (self.moveDirection.y * speed)
            
            if newX <= ballSize/2 || newX >= screenSize.width - ballSize/2 {
                self.moveDirection.x *= -1
                newX = self.customPosition.x + (self.moveDirection.x * speed)
            }
            if newY <= screenSize.height * 0.15 || newY >= screenSize.height * 0.4 {
                self.moveDirection.y *= -1
                newY = self.customPosition.y + (self.moveDirection.y * speed)
            }
            
            self.customPosition = CGPoint(x: newX, y: newY)
        }
    }
    
    private func cleanupCurrentDemo() {
        // Implement cleanup logic here
    }
    
    private func resetStateForStep(_ step: Int) {
        // Implement state reset logic here
    }
}

struct ScoringRuleCard: View {
    let title: String
    let description: String
    let icon: String
    let gradient: [Color]
    
    var body: some View {
        HStack(spacing: 20) {
            Image(systemName: icon)
                .font(.system(size: 30))
                .foregroundStyle(
                    .linearGradient(
                        colors: gradient,
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                Text(description)
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.8))
                    .lineSpacing(4)
            }
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 15)
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color.white.opacity(0.15))
                .overlay(
                    RoundedRectangle(cornerRadius: 15)
                        .stroke(
                            LinearGradient(
                                colors: gradient.map { $0.opacity(0.5) },
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
        )
        .padding(.horizontal)
    }
}

struct SummaryCard: View {
    let title: String
    let points: [String]
    let gradient: [Color]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text(title)
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundStyle(
                    .linearGradient(
                        colors: gradient,
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
            
            VStack(alignment: .leading, spacing: 8) {
                ForEach(points, id: \.self) { point in
                    Text(point)
                        .font(.system(size: 18, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.9))
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color.white.opacity(0.15))
                .overlay(
                    RoundedRectangle(cornerRadius: 15)
                        .stroke(
                            LinearGradient(
                                colors: gradient.map { $0.opacity(0.5) },
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
        )
    }
}

#Preview {
    TutorialView()
}
