//
//  TutorialView.swift
//  DistractionDodge
//
//  Created by Ayush Kumar Singh on 2/11/25.
//
#if os(iOS)
import SwiftUI
import SwiftData

/// A comprehensive tutorial view that guides users through the game mechanics of the iOS version of DistractionDodge.
///
/// `TutorialView` provides a step-by-step interactive learning experience:
/// - It presents a series of `TutorialStep`s, each focusing on a specific game aspect.
/// - Interactive demonstrations allow users to practice core mechanics like eye tracking,
///   responding to distractions, and understanding the scoring system.
/// - Visual feedback, animations, and descriptive text enhance the learning process.
/// - The tutorial covers basic focus, distractions, scoring, multipliers, streak bonuses, and penalties.
/// - Users can navigate between steps using buttons or swipe gestures.
/// - An option to skip the tutorial is provided.
///
/// The view uses `GeometryReader` for adaptive layout and `AttentionViewModel` (though not directly visible in the provided snippet, assumed to be used by `MainCircle` or `NotificationView` if they were fully shown) or similar logic for game element simulations.
///
/// - Note: This view is specific to the iOS platform, due to its reliance on `EyeTrackingView` and
///   platform-specific UI/UX paradigms for the tutorial steps.
struct TutorialView: View {
    /// The SwiftData model context, used for updating `UserProgress` upon tutorial completion.
    @Environment(\.modelContext) private var modelContext
    /// The index of the current step in the `tutorialSteps` array.
    @State private var currentStep = 0
    /// Controls the presentation of the `Home` view after completing or skipping the tutorial.
    @State private var showHomeView = false
    /// The position for demonstration elements like the `MainCircle`. (Currently not directly used in the provided snippet, but often needed for such views).
    @State private var demoPosition: CGPoint = .zero
    /// Simulates the gaze status for eye-tracking demonstrations.
    @State private var demoIsGazing = false
    /// Simulates the game score during scoring demonstrations.
    @State private var demoScore = 0
    /// Simulates the focus streak during streak demonstrations.
    @State private var demoStreak = 0
    /// (Currently unused) Controls visibility of a scoring rule card for base scoring.
    @State private var showScoreCard = false
    /// (Currently unused) Controls visibility of a scoring rule card for multipliers.
    @State private var showMultiplierCard = false
    /// (Currently unused) Controls visibility of a scoring rule card for penalties.
    @State private var showPenaltyCard = false
    /// Controls the visibility of a mock distraction during the distraction demonstration step.
    @State private var showDemoDistraction = false
    /// Simulates the score multiplier during the multiplier demonstration.
    @State private var demoMultiplier = 1
    /// Controls the animation of a "+1" score increment indicator.
    @State private var showScoreIncrementIndicator = false
    /// Controls the animation of a "+5 BONUS" indicator for streak bonuses.
    @State private var showBonusIndicator = false
    /// Controls the animation of a "Focus Lost" or penalty indicator.
    @State private var showPenaltyIndicator = false
    /// Simulates elapsed time for demonstrations like multipliers.
    @State private var elapsedTime: Int = 0
    /// Simulates streak time for streak bonus demonstrations.
    @State private var streakTime: Int = 0
    /// Timer used for penalty demonstration animations. (Currently not directly used in the provided snippet's logic, but declared).
    @State private var penaltyTimer: Timer? = nil
    
    /// Indicates if the demonstration focus ball is currently moving.
    @State private var isMovingBall = false
    /// The direction vector for the demonstration ball's movement.
    @State private var moveDirection = CGPoint(x: 1, y: 1)
    /// Tracks if the user has successfully demonstrated following the ball with their gaze.
    @State private var hasDemonstratedFollowing = false
    /// Controls the visibility of the "Next" button, often shown after a step's interaction is complete.
    @State private var showNextButton = false
    /// The current position of the demonstration `MainCircle`, adaptable by `viewSize`.
    @State private var customPosition: CGPoint = .zero
    /// Scale factor for the "Next" button's pulsing animation.
    @State private var nextButtonScale: CGFloat = 1.0
    /// Flag to prevent rapid navigation actions.
    @State private var isNavigating = false
    /// Tracks the horizontal offset of a drag gesture for swipe navigation.
    @GestureState private var dragOffset: CGFloat = 0
    /// Controls the presentation of an alert to confirm skipping the tutorial.
    @State private var showSkipAlert = false
    /// Counter for how many times the penalty screen has appeared, used to vary `id` for animations.
    @State private var penaltyScreenAppearCount = 0
    /// The size of the view, obtained from `GeometryReader`, used for layout and positioning.
    @State private var viewSize: CGSize = .zero
    
    /// An array of gradient color pairs for the background of each tutorial step.
    private let gradientColors: [(start: Color, end: Color)] = [
        (.black.opacity(0.8), .indigo.opacity(0.2)),
        (.black.opacity(0.8), .purple.opacity(0.2)),
        (.black.opacity(0.8), .cyan.opacity(0.2)),
        (.black.opacity(0.8), .blue.opacity(0.2)),
        (.black.opacity(0.8), .indigo.opacity(0.2)),
        (.black.opacity(0.8), .purple.opacity(0.2))
    ]
    
    /// An array defining the content and type for each step of the tutorial.
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
            title: "Scoring",
            description: [
                "Every second of focus counts! Watch your score grow as you maintain your gaze."
            ],
            scoringType: .baseScoring
        ),
        TutorialStep(
            title: "Score Multipliers",
            description: [
                "Keep focusing to increase your multiplier! Every 5 seconds, your score multiply.",
            ],
            scoringType: .multiplier
        ),
        TutorialStep(
            title: "Streak Bonus",
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
    
    /// Handles navigation between tutorial steps.
    /// - Parameter forward: If `true`, navigates to the next step; if `false`, to the previous.
    /// Manages `isNavigating` to prevent multiple rapid transitions and resets `showNextButton`.
    private func navigate(forward: Bool) {
        if !isNavigating {
            isNavigating = true
            
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
                #if os(iOS)
                LinearGradient(
                    gradient: Gradient(colors: [
                        gradientColors[currentStep].start,
                        gradientColors[currentStep].end
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                .animation(.easeInOut(duration: 1.0), value: currentStep)
                #endif
                
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
                                #if os(iOS)
                                .background(
                                    Capsule()
                                        .fill(Color.white.opacity(0.15))
                                        .overlay(
                                            Capsule()
                                                .stroke(Color.white.opacity(0.3), lineWidth: 1)
                                        )
                                )
                                #endif
                        }
                        .padding(.top, 50)
                        .padding(.trailing, 20)
                    }
                    Spacer()
                }
                
                VStack(spacing: 0) {
                    
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
                    
                    
                    VStack(spacing: 80) {
                        switch tutorialSteps[currentStep].scoringType {
                        case .introduction:
                            ZStack {
                                
                                EyeTrackingView { isGazing in
                                    if self.demoIsGazing != isGazing {
                                        self.demoIsGazing = isGazing
                                        if isGazing && !isMovingBall && !hasDemonstratedFollowing {
                                            
                                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                                withAnimation {
                                                    isMovingBall = true
                                                    if self.viewSize != .zero {
                                                        self.startBallMovement()
                                                    }
                                                }
                                            }
                                            
                                            
                                            DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
                                                withAnimation(.easeInOut(duration: 0.5)) {
                                                    isMovingBall = false
                                                    
                                                    if self.viewSize != .zero {
                                                        self.customPosition = CGPoint(x: self.viewSize.width / 2,
                                                                                     y: self.viewSize.height * 0.15)
                                                    }
                                                    
                                                    
                                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                                        withAnimation(.easeInOut) {
                                                            hasDemonstratedFollowing = true
                                                            
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
                                    }
                                }
                       
                                VStack(spacing: 60) {
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
                                    
                                    
                                    MainCircle(isGazingAtTarget: demoIsGazing,
                                               position: customPosition)
                                    .padding(.bottom, 100)
                                    
                                    Spacer()
                                }
                                .frame(maxHeight: .infinity, alignment: .top)
                                .padding(.top, 40)
                                
                                
                            }
                            .id("introduction\(currentStep)_\(penaltyScreenAppearCount)")
                            .onAppear {
                                
                                demoIsGazing = false
                                isMovingBall = false
                                hasDemonstratedFollowing = false
                                showNextButton = false
                                nextButtonScale = 1.0
                                if self.viewSize != .zero {
                                    customPosition = CGPoint(x: self.viewSize.width / 2,
                                                             y: self.viewSize.height * 0.15)
                                }
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
                                           position: CGPoint(x: viewSize.width / 2,
                                                             y: viewSize.height * 0.22))
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
                                    
                                    
                                    VStack(alignment: .center) {
                                        Text("Time")
                                            .font(.system(size: 20, weight: .medium, design: .rounded))
                                        Text("\(elapsedTime)s")
                                            .font(.system(size: 36, weight: .bold, design: .rounded))
                                            .foregroundStyle(.white)
                                    }
                                    
                                    
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
                                           position: CGPoint(x: viewSize.width / 2,
                                                             y: viewSize.height * 0.20))
                                .onAppear {
                                    startMultiplierDemo()
                                }
                            }
                            .id("multiplier\(currentStep)")
                            
                        case .streakBonus:
                            VStack(spacing: 40) {
                                HStack(spacing: 30) {
                                    
                                    VStack(alignment: .center) {
                                        Text("Score")
                                            .font(.system(size: 20, weight: .medium, design: .rounded))
                                        Text("\(demoScore)")
                                            .font(.system(size: 36, weight: .bold, design: .rounded))
                                            .foregroundStyle(.white)
                                    }
                                    
                                    
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
                                    Text("+5 BONUS")
                                        .font(.system(size: 32, weight: .heavy, design: .rounded))
                                        .foregroundStyle(
                                            .linearGradient(
                                                colors: [.yellow, .orange],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                        .modifier(StyledTextEffect(isShowing: showBonusIndicator, style: .bonus))
                                }
                                
                                MainCircle(isGazingAtTarget: true,
                                           position: CGPoint(x: viewSize.width / 2,
                                                             y: viewSize.height * 0.20))
                                .scaleEffect(showBonusIndicator ? 1.1 : 1.0)
                                .onAppear {
                                    startStreakBonusDemo()
                                }
                            }
                            .id("streak\(currentStep)")
                            
                            
                        case .penalty:
                            VStack(spacing: 40) {
                                HStack(spacing: 30) {
                                    
                                    VStack(alignment: .center) {
                                        Text("Score")
                                            .font(.system(size: 20, weight: .medium, design: .rounded))
                                        Text("\(demoScore)")
                                            .font(.system(size: 36, weight: .bold))
                                            .foregroundStyle(.white)
                                    }
                                    
                                    
                                    VStack(alignment: .center) {
                                        Text("Penalty")
                                            .font(.system(size: 20, weight: .medium, design: .rounded))
                                        Text("-\(min(demoStreak, 10))")
                                            .font(.system(size: 36, weight: .bold))
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
                                    Text("Focus Lost")
                                        .font(.system(size: 32, weight: .heavy, design: .rounded))
                                        .foregroundColor(.red)
                                        .transition(.scale.combined(with: .opacity))
                                }
                                
                                MainCircle(isGazingAtTarget: !showPenaltyIndicator,
                                           position: CGPoint(x: viewSize.width / 2,
                                                             y: viewSize.height / 5))
                            }
                            .id("penalty\(currentStep)_\(penaltyScreenAppearCount)")
                            .onAppear {
                                penaltyScreenAppearCount += 1
                                showPenaltyIndicator = false
                                demoScore = 30
                                demoStreak = 8
                                startPenaltyDemo()
                            }
                            
                            
                            
                        case .distractions:
                            ZStack {
                                #if os(iOS)
                                EyeTrackingView { isGazing in
                                    self.demoIsGazing = isGazing
                                }
                                #else
                                Color.clear
                                    .frame(width: 0, height: 0)
                                    .onAppear {
                                        if self.currentStep == 1 && !self.demoIsGazing {
                                            print("Simulating gaze ON for visionOS distractions step")
                                            self.demoIsGazing = true
                                        }
                                    }
                                #endif
                                VStack(spacing: 60) {
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
                                    
                                    
                                    MainCircle(isGazingAtTarget: demoIsGazing,
                                               position: customPosition)
                                    .padding(.bottom, 100)
                                    
                                    Spacer()
                                }
                                
                                
                                if showDemoDistraction {
                                    NotificationView(
                                        distraction: Distraction(
                                            position: CGPoint(x: viewSize.width * 0.7,
                                                              y: viewSize.height * 0.4),
                                            title: "Messages",
                                            message: "🎮 Game night tonight?",
                                            appIcon: "message.fill",
                                            iconColors: [.green, .blue],
                                            soundID: 1007
                                        ),
                                        index: 0
                                    )
                                    .allowsHitTesting(false)
                                    .transition(.opacity.combined(with: .scale(scale: 0.9)))
                                }
                            }
                           
                            .onAppear {
                                
                                if !isMovingBall && self.viewSize != .zero {
                                    isMovingBall = true
                                    startBallMovement()
                                }
                                
                                startDistractionDemo()
                            }
                            .id("distractions\(currentStep)")
                            
                            
                        }
                    }
                    .frame(height: geometry.size.height * 0.4)
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))
                    
                    Spacer()
                    
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
                                #if os(iOS)
                                .background(Capsule().fill(Color.white.opacity(0.2)))
                                #endif
                            }
                            .transition(.move(edge: .trailing).combined(with: .opacity))
                            .disabled(isNavigating)
                        }
                        
                        Button(action: {
                            if currentStep < tutorialSteps.count - 1 {
                                navigate(forward: true)
                            } else {
                                if let progress = try? modelContext.fetch(FetchDescriptor<UserProgress>()).first {
                                    withAnimation {
                                        progress.hasCompletedOnboarding = true
                                        try? modelContext.save()
                                        showHomeView = true
                                    }
                                }
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
                            #if os(iOS)
                            .background(Capsule().fill(Color.white.opacity(0.2)))
                            #endif
                            .scaleEffect(showNextButton ? nextButtonScale : 1.0)
                        }
                        .disabled(isNavigating)
                    }
                    .padding(.bottom, 50)
                }
                .padding()
                
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
                
                
                if showSkipAlert {
                    AlertView(
                        title: "Skip Tutorial?",
                        message: "You are about to skip the tutorial. You will be taken directly to the game.",
                        primaryAction: {
                            if let progress = try? modelContext.fetch(FetchDescriptor<UserProgress>()).first {
                                progress.hasCompletedOnboarding = true
                                try? modelContext.save()
                            }
                            showHomeView = true
                        },
                        secondaryAction: {},
                        isPresented: $showSkipAlert
                    )
                }
            }
            .onAppear {
                if viewSize == .zero {
                    viewSize = geometry.size
                    demoPosition = CGPoint(x: viewSize.width / 2, y: viewSize.height * 0.15)
                    customPosition = CGPoint(x: viewSize.width / 2, y: viewSize.height * 0.15)
                }
            }
            .onChange(of: geometry.size) { oldSize, newSize in
                if newSize != .zero {
                    viewSize = newSize
                    demoPosition = CGPoint(x: viewSize.width / 2, y: viewSize.height * 0.15)
                    customPosition = CGPoint(x: viewSize.width / 2, y: viewSize.height * 0.15)
                }
            }
            .animation(.easeInOut, value: showSkipAlert)
        }
        .onChange(of: currentStep) { oldValue, newValue in
            
            resetStateForStep(newValue)
        }
        .preferredColorScheme(.dark)
        .statusBarHidden(true)
        .persistentSystemOverlays(.hidden)
        .fullScreenCover(isPresented: $showHomeView) {
            Home()
        }
        .animation(.spring(response: 0.6, dampingFraction: 0.7), value: currentStep)
    }
    
    private func startBaseScoring() {
        
        demoScore = 0
        showNextButton = false
        nextButtonScale = 1.0
        var hasStartedBounce = false
        
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            guard tutorialSteps[currentStep].scoringType == .baseScoring else {
                timer.invalidate()
                return
            }
            
            withAnimation {
                demoScore += 1
                showScoreIncrementIndicator = true
                
                if demoScore > 10 {
                    demoScore = 0
                }
                
                if demoScore == 0 && !hasStartedBounce {
                    hasStartedBounce = true
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
            
            withAnimation(.easeInOut(duration: 0.5)) {
                elapsedTime += 1
                
                if elapsedTime >= 60 {
                    elapsedTime = 0
                    demoScore = 0
                    demoMultiplier = 1
                }
                
                if elapsedTime % 5 == 0 && demoMultiplier < 3 {
                    demoMultiplier += 1
                    
                    if !hasStartedBounce {
                        hasStartedBounce = true
                        showNextButton = true
                        withAnimation(
                            .easeInOut(duration: 0.5)
                            .repeatForever(autoreverses: true)
                        ) {
                            nextButtonScale = 1.1
                        }
                    }
                }
                
                demoScore += demoMultiplier
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
            
            
            if streakTime >= 60 {
                streakTime = 0
                demoScore = 0
                demoStreak = 0
            }
            
            
            if !hasStartedBounce && streakTime == 0 {
                hasStartedBounce = true
                showNextButton = true
                withAnimation(
                    .easeInOut(duration: 0.5)
                    .repeatForever(autoreverses: true)
                ) {
                    nextButtonScale = 1.1
                }
            }
            
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
        }
    }
    
    private func startPenaltyDemo() {
        demoScore = 30
        demoStreak = 8
        showPenaltyIndicator = false
        showNextButton = false
        nextButtonScale = 1.0
        var cycleCount = 0
        var hasStartedBounce = false
        
        func runPenaltyCycle() {
            withAnimation(.easeInOut(duration: 0.5)) {
                showPenaltyIndicator = true
                demoScore = max(0, demoScore - min(demoStreak, 10))
                
                
                if !hasStartedBounce && cycleCount > 0 {
                    hasStartedBounce = true
                    showNextButton = true
                    withAnimation(
                        .easeInOut(duration: 0.5)
                        .repeatForever(autoreverses: true)
                    ) {
                        nextButtonScale = 1.1
                    }
                }
            }
            
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                cycleCount += 1
                demoScore = 30
                demoStreak = 8
                withAnimation {
                    showPenaltyIndicator = false
                }
                
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    guard tutorialSteps[currentStep].scoringType == .penalty else { return }
                    runPenaltyCycle()
                }
            }
        }
        
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            runPenaltyCycle()
        }
    }
    
    private func startDistractionDemo() {
        var distractionCount = 0
        if !isMovingBall && viewSize != .zero {
            isMovingBall = true
            startBallMovement()
        }
        showDemoDistraction = false

        Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { timer in
            guard currentStep == 1 && isMovingBall else {
                timer.invalidate()
                return
            }

            distractionCount += 1
            if distractionCount >= 3 {
                timer.invalidate()
                showDemoDistraction = false


                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    withAnimation(.easeInOut(duration: 1.0)) {
                        isMovingBall = false
                        if self.viewSize != .zero {
                            customPosition = CGPoint(x: self.viewSize.width / 2,
                                                     y: self.viewSize.height * 0.15)
                        }
                    }


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


            withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                showDemoDistraction = true
            }


            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                withAnimation(.easeOut) {
                    showDemoDistraction = false


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
        guard viewSize != .zero else {
            print("Cannot start ball movement, view size is zero.")
            isMovingBall = false
            return
        }

        let speed: CGFloat = 2.0
        Timer.scheduledTimer(withTimeInterval: 0.016, repeats: true) { timer in
            guard isMovingBall else {
                timer.invalidate()
                return
            }

            let ballSize: CGFloat = 100
            let currentSize = self.viewSize

            var newX = self.customPosition.x + (self.moveDirection.x * speed)
            var newY = self.customPosition.y + (self.moveDirection.y * speed)

            let minYBoundary = currentSize.height * 0.15
            let maxYBoundary = currentSize.height * 0.4

            if newX <= ballSize/2 || newX >= currentSize.width - ballSize/2 {
                self.moveDirection.x *= -1
                newX = self.customPosition.x + (self.moveDirection.x * speed)
            }
            if newY <= minYBoundary || newY >= maxYBoundary {
                self.moveDirection.y *= -1
                newY = self.customPosition.y + (self.moveDirection.y * speed)
            }

            self.customPosition = CGPoint(
                x: max(ballSize/2, min(newX, currentSize.width - ballSize/2)),
                y: max(minYBoundary, min(newY, maxYBoundary))
            )
        }
    }
    
    private func resetStateForStep(_ step: Int) {
        
        showNextButton = false
        nextButtonScale = 1.0
        
        
        showScoreIncrementIndicator = false
        showBonusIndicator = false
        showPenaltyIndicator = false
        showDemoDistraction = false
        
        
        switch tutorialSteps[step].scoringType {
        case .penalty:
            demoScore = 30
            demoStreak = 8
        case .baseScoring:
            demoScore = 0
            demoStreak = 0
        case .multiplier:
            demoScore = 0
            demoStreak = 0
            demoMultiplier = 1
            elapsedTime = 0
        case .streakBonus:
            demoScore = 0
            demoStreak = 0
            streakTime = 0
        default:
            demoScore = 0
            demoStreak = 0
        }
        
        if step == 0 || step == 1 {
            if viewSize != .zero {
                customPosition = CGPoint(x: viewSize.width / 2,
                                         y: viewSize.height * 0.15)
            } else {
                customPosition = .zero
            }
        }
        
        isMovingBall = false
    }
}

#Preview {
    TutorialView()
}
#endif
