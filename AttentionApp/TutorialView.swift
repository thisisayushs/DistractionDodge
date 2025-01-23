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
    @State private var showDemoDistraction = true
    @State private var demoMultiplier = 1
    @State private var showScoreIncrementIndicator = false
    @State private var showBonusIndicator = false
    @State private var showPenaltyIndicator = false

    @State private var isMovingBall = false
    @State private var moveDirection = CGPoint(x: 1, y: 1)
    @State private var hasDemonstratedFollowing = false
    @State private var showNextButton = false
    @State private var customPosition = CGPoint(x: UIScreen.main.bounds.width / 2,
                                              y: UIScreen.main.bounds.height * 0.15)
    @State private var nextButtonScale: CGFloat = 1.0

    let tutorialSteps = [
        TutorialStep(
            title: "Prepare to Train Your Focus",
            description: [
                // Initial positioning
                "Position your device steadily so your face is clearly visible to the camera.",
                // When stationary
                "Look at the circle until it starts glowing.",
                // When circle starts moving
                "Now follow the moving circle with your eyes.",
                // When circle stops and returns
                "Great! You've mastered the basics. Tap 'Next' to continue."
            ],
            scoringType: .introduction
        ),
        TutorialStep(
            title: "Dodge the Distractions",
            description: [
                "Stay focused! Don't look at or tap any notifications that appear."
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
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background gradient
                LinearGradient(
                    gradient: Gradient(colors: [.black.opacity(0.8), .blue.opacity(0.2)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Title section
                    Text(tutorialSteps[currentStep].title)
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .padding(.top, 60)
                        .padding(.bottom, 10)
                    
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
                                            .font(.system(size: 18, weight: .medium))
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
                                
                                MainCircle(isGazingAtTarget: true, position: CGPoint(x: geometry.size.width / 2,
                                                                                   y: geometry.size.height / 2))
                                    .overlay(
                                        Text("+1")
                                            .font(.system(size: 24, weight: .bold, design: .rounded))
                                            .foregroundColor(.green)
                                            .opacity(showScoreIncrementIndicator ? 1 : 0)
                                            .offset(y: showScoreIncrementIndicator ? -30 : 0)
                                    )
                                    .onAppear {
                                        startBaseScoring()
                                    }
                            }
                        
                        case .multiplier:
                            VStack(spacing: 40) {
                                HStack(spacing: 30) {
                                    // Score display
                                    VStack(alignment: .center) {
                                        Text("Score")
                                            .font(.system(size: 20, weight: .medium))
                                        Text("\(demoScore)")
                                            .font(.system(size: 36, weight: .bold))
                                            .foregroundStyle(.white)
                                    }
                                    
                                    // Multiplier display
                                    VStack(alignment: .center) {
                                        Text("Multiplier")
                                            .font(.system(size: 20, weight: .medium))
                                        Text("×\(demoMultiplier)")
                                            .font(.system(size: 36, weight: .bold))
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
                                
                                MainCircle(isGazingAtTarget: true, position: CGPoint(x: geometry.size.width / 2,
                                                                                   y: geometry.size.height / 2))
                                    .onAppear {
                                        startMultiplierDemo()
                                    }
                            }
                        
                        case .streakBonus:
                            VStack(spacing: 40) {
                                HStack(spacing: 30) {
                                    // Score display
                                    VStack(alignment: .center) {
                                        Text("Score")
                                            .font(.system(size: 20, weight: .medium))
                                        Text("\(demoScore)")
                                            .font(.system(size: 36, weight: .bold))
                                            .foregroundStyle(.white)
                                    }
                                    
                                    // Streak display
                                    VStack(alignment: .center) {
                                        Text("Streak")
                                            .font(.system(size: 20, weight: .medium))
                                        Text("\(demoStreak)s")
                                            .font(.system(size: 36, weight: .bold))
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
                                        .font(.system(size: 32, weight: .heavy))
                                        .foregroundStyle(
                                            .linearGradient(
                                                colors: [.yellow, .orange],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                        .transition(.scale.combined(with: .opacity))
                                }
                                
                                MainCircle(isGazingAtTarget: true, position: CGPoint(x: geometry.size.width / 2,
                                                                                   y: geometry.size.height / 2))
                                    .scaleEffect(showBonusIndicator ? 1.1 : 1.0)
                                    .onAppear {
                                        startStreakBonusDemo()
                                    }
                            }
                        
                        case .penalty:
                            VStack(spacing: 40) {
                                HStack(spacing: 30) {
                                    // Score display
                                    VStack(alignment: .center) {
                                        Text("Score")
                                            .font(.system(size: 20, weight: .medium))
                                        Text("\(demoScore)")
                                            .font(.system(size: 36, weight: .bold))
                                            .foregroundStyle(.white)
                                    }
                                    
                                    // Penalty display
                                    VStack(alignment: .center) {
                                        Text("Penalty")
                                            .font(.system(size: 20, weight: .medium))
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
                                    Text("Focus Lost!")
                                        .font(.system(size: 32, weight: .heavy))
                                        .foregroundColor(.red)
                                        .transition(.scale.combined(with: .opacity))
                                }
                                
                                MainCircle(isGazingAtTarget: !showPenaltyIndicator, position: CGPoint(x: geometry.size.width / 2,
                                                                                                   y: geometry.size.height / 2))
                                    .onAppear {
                                        startPenaltyDemo()
                                    }
                            }
                        
                        case .summary:
                            ScrollView {
                                // Summary cards remain the same
                            }
                        
                        case .distractions:
                            ZStack {
                                MainCircle(isGazingAtTarget: true, position: CGPoint(x: geometry.size.width / 2,
                                                                                   y: geometry.size.height / 2))
                                if showDemoDistraction {
                                    NotificationView(
                                        distraction: Distraction(
                                            position: CGPoint(x: UIScreen.main.bounds.width * 0.7,
                                                            y: UIScreen.main.bounds.height * 0.4),
                                            title: "Messages",
                                            message: "Don't look here!",
                                            appIcon: "message.fill",
                                            iconColors: [.green, .blue],
                                            soundID: 1007
                                        ),
                                        index: 0
                                    )
                                }
                            }
                       
                        }
                    }
                    .frame(height: geometry.size.height * 0.4)
                    
                    Spacer()
                    
                    // Navigation buttons
                    HStack(spacing: 20) {
                        if currentStep > 0 {
                            Button(action: { currentStep -= 1 }) {
                                HStack {
                                    Image(systemName: "chevron.left")
                                    Text("Previous")
                                }
                                .foregroundColor(.white)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 10)
                                .background(Capsule().fill(Color.white.opacity(0.2)))
                            }
                        }
                        
                        Button(action: {
                            if currentStep < tutorialSteps.count - 1 {
                                currentStep += 1
                            } else {
                                showContentView = true
                            }
                        }) {
                            HStack {
                                Text(currentStep == tutorialSteps.count - 1 ? "Start Game" : "Next")
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
                    }
                    .padding(.bottom, 50)
                }
            }
            .onChange(of: currentStep) { oldValue, newValue in
                // Reset all states when navigating away from or back to introduction
                if oldValue == 0 || newValue == 0 {
                    isMovingBall = false
                    hasDemonstratedFollowing = false
                    demoIsGazing = false
                    nextButtonScale = 1.0
                    showNextButton = false
                    customPosition = CGPoint(x: UIScreen.main.bounds.width / 2,
                                           y: UIScreen.main.bounds.height * 0.15)
                    moveDirection = CGPoint(x: 1, y: 1)
                }
            }
        }
        .fullScreenCover(isPresented: $showContentView) {
            ContentView()
        }
        .onAppear {
            // Remove the position setting here as we're using GeometryReader instead
        }
    }
    
    private func startBaseScoring() {
        demoScore = 0
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            guard tutorialSteps[currentStep].scoringType == .baseScoring else {
                timer.invalidate()
                return
            }
            withAnimation {
                demoScore += 1
                showScoreIncrementIndicator = true
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
        demoStreak = 0
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            guard tutorialSteps[currentStep].scoringType == .multiplier else {
                timer.invalidate()
                return
            }
            withAnimation {
                demoStreak += 1
                demoScore += demoMultiplier
                if demoStreak % 5 == 0 {
                    demoMultiplier += 1
                }
            }
        }
    }
    
    private func startStreakBonusDemo() {
        demoScore = 0
        demoStreak = 0
        showBonusIndicator = false
        
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            guard tutorialSteps[currentStep].scoringType == .streakBonus else {
                timer.invalidate()
                return
            }
            
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
        }
    }

    private func startPenaltyDemo() {
        demoScore = 30
        demoStreak = 8
        showPenaltyIndicator = false
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation(.easeInOut(duration: 0.5)) {
                showPenaltyIndicator = true
                demoScore = max(0, demoScore - min(demoStreak, 10))
            }
            
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
        Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { timer in
            guard currentStep == 1 else {
                timer.invalidate()
                return
            }
            withAnimation {
                showDemoDistraction.toggle()
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
