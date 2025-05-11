//
//  visionOSTutorialView.swift
//  DistractionDodge
//
//  Created by Ayush Kumar Singh on 5/5/25.
//
#if os(visionOS)

import SwiftUI
import SwiftData

// Note: TutorialHologram, TutorialSparkEffect, FlyingPoint, FlyingPointsView, VisionOSTutorialStep
// definitions have been moved to their own files in Tutorial/Models/ and Tutorial/Views/.
// HologramView and SparkleExplosionView are used from SharedViews/.

/// The main view for the interactive tutorial on visionOS.
///
/// This view guides the user through various game mechanics, including controlling the circle,
/// catching holograms, understanding distractions, scoring, and the hearts system.
public struct visionOSTutorialView: View {
    /// Environment value to dismiss the current view.
    @Environment(\.dismiss) private var dismiss
    /// The SwiftData model context, used for saving tutorial completion progress.
    @Environment(\.modelContext) private var modelContext

    // MARK: - State Variables for Tutorial Flow
    /// The current step of the tutorial.
    @State private var currentStep: VisionOSTutorialStep = .dragCircle
    /// The main title text displayed for the current tutorial step.
    @State private var currentTitle: String = "Control your Circle"
    /// The subtitle/instructional text displayed for the current tutorial step.
    @State private var currentSubtitle: String = "Drag the circle around with your gaze or finger."

    // MARK: - State Variables for Draggable Circle
    /// The current position of the draggable main circle in the demo area.
    @State private var circlePosition: CGPoint = .zero
    /// A Boolean indicating whether the main circle is currently being dragged by the user.
    @State private var isDraggingCircle: Bool = false
    /// The position of the main circle at the start of a drag gesture.
    @State private var dragStartCirclePosition: CGPoint = .zero
    /// A Boolean indicating if the user has successfully dragged the circle at least once in the `dragCircle` step.
    @State private var hasDraggedOnce: Bool = false

    /// The visual radius of the main draggable circle for tutorial purposes.
    private let mainCircleVisualRadius: CGFloat = 100

    // MARK: - State Variables for Hologram Catching Step
    /// An array of `TutorialHologram` objects currently active in the demo area.
    @State private var activeTutorialHolograms: [TutorialHologram] = []
    /// An array of `TutorialSparkEffect` objects currently active in the demo area.
    @State private var activeSparkEffects: [TutorialSparkEffect] = []
    /// An array of `FlyingPoint` objects (e.g., score indicators) currently active.
    @State private var activeFlyingPoints: [FlyingPoint] = []
    /// Timer for spawning tutorial holograms.
    @State private var hologramSpawnTimer: Timer?
    /// Timer for checking expired tutorial holograms.
    @State private var hologramCheckTimer: Timer?
    /// The number of holograms caught by the user in the `catchHologram` step.
    @State private var hologramsCaughtCount: Int = 0
    /// The target number of holograms the user needs to catch to complete the `catchHologram` step.
    private let hologramsToCatchGoal: Int = 3
    /// The maximum number of tutorial holograms allowed on screen simultaneously.
    private let maxConcurrentTutorialHolograms: Int = 2

    // MARK: - State Variables for UI Control
    /// A Boolean indicating whether to show the alert for skipping the tutorial.
    @State private var showSkipAlert: Bool = false
    /// A Boolean to trigger the "pulsing" animation for the "Next" button when it becomes active.
    @State private var showNextButtonReadyAnimation: Bool = false
    /// The scale factor for the "Next" button's pulsing animation.
    @State private var nextButtonScale: CGFloat = 1.0

    // MARK: - State Variables for Layout and Sizing
    /// The total size of the `visionOSTutorialView`. Obtained via `GeometryReader`.
    @State private var viewSize: CGSize = .zero
    /// The calculated size of the interactive demo area within the tutorial view.
    @State private var demoAreaSize: CGSize = .zero
    
    // MARK: - State Variables for Distraction Learning Step
    /// A sample `Distraction` object used to demonstrate distractions.
    @State private var sampleDistraction: Distraction?
    /// Timer for scheduling the appearance of sample distractions.
    @State private var distractionAppearTimer: Timer?

    // MARK: - State Variables for Hearts Learning Step
    /// The number of hearts to display during the `learnHearts` step.
    @State private var tutorialHeartsToShow: Int = 3
    /// A sample `TutorialHologram` used to demonstrate heart loss.
    @State private var demoHeartLossHologram: TutorialHologram?
    /// Timer for managing the heart loss demonstration sequence.
    @State private var heartLossDemoTimer: Timer?

    /// A Boolean to control the presentation of the `Home` view after tutorial completion.
    @State private var showHomeView = false

    /// Initializes a new `visionOSTutorialView`.
    public init() {}

    /// The body of the `visionOSTutorialView`.
    public var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                // Skip Button Area
                HStack {
                    Spacer()
                    Button(action: { showSkipAlert = true }) {
                        Text("Skip")
                            .font(.system(size: 17, weight: .medium, design: .rounded))
                            .foregroundColor(.white.opacity(0.7))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                    }
                    .buttonStyle(.plain)
                    .padding([.top, .trailing], 25)
                }
                .frame(height: 50)

                Spacer()

                // Title and Subtitle
                Text(currentTitle)
                    .font(.system(size: 40, weight: .bold, design: .default))
                    .padding(.bottom, 10)
                    .animation(.easeInOut, value: currentTitle)

                Text(currentSubtitle)
                    .font(.system(size: 20, weight: .regular, design: .default))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                    .padding(.bottom, 20)
                    .animation(.easeInOut, value: currentSubtitle)

                // Interactive Demo Area
                ZStack {
                    switch currentStep {
                    case .dragCircle:
                        MainCircle(
                            isGazingAtTarget: isDraggingCircle,
                            position: circlePosition
                        )
                    case .catchHologram:
                        ForEach(activeTutorialHolograms) { hologram in
                             HologramView()
                                .position(hologram.position)
                                .transition(.asymmetric(insertion: .scale.animation(.spring()), removal: .opacity.animation(.easeInOut)))
                        }
                        MainCircle(
                            isGazingAtTarget: isDraggingCircle,
                            position: circlePosition
                        )
                        ForEach(activeSparkEffects) { effect in
                            SparkleExplosionView(onComplete: { removeSparkEffect(id: effect.id) })
                                .position(effect.position)
                                .allowsHitTesting(false)
                        }
                        ForEach(activeFlyingPoints) { point in
                            FlyingPointsView(point: point)
                                .id(point.id)
                                .allowsHitTesting(false)
                                .onAppear {
                                    DispatchQueue.main.asyncAfter(deadline: .now() + FlyingPoint.animationDuration) {
                                        removeFlyingPoint(id: point.id)
                                    }
                                }
                        }
                    case .learnDistractions:
                        MainCircle(
                            isGazingAtTarget: isDraggingCircle,
                            position: circlePosition
                        )
                        .opacity(0.5)
                        if let distraction = sampleDistraction {
                            VisionOSDistractionView(distraction: distraction)
                                .position(distraction.position)
                                .transition(.asymmetric(insertion: .move(edge: .top).combined(with: .opacity), removal: .opacity))
                        }
                    case .learnScoring:
                        ScrollView {
                            VStack(alignment: .leading, spacing: 20) {
                                HStack(spacing: 10) {
                                    Image(systemName: "scope").font(.title2).foregroundColor(.cyan)
                                    VStack(alignment: .leading) {
                                        Text("Catch Hologram").font(.headline)
                                        Text("Base: **+3 points**").font(.subheadline).foregroundColor(.secondary)
                                    }
                                }
                                .padding(.vertical, 5)
                                Divider()
                                HStack(spacing: 10) {
                                    Image(systemName: "flame.fill").font(.title2).foregroundColor(.orange)
                                    VStack(alignment: .leading) {
                                        Text("Streak Bonus").font(.headline)
                                        Text("Every **5** consecutive catches: **+5 bonus points**").font(.subheadline).foregroundColor(.secondary)
                                    }
                                }
                                .padding(.vertical, 5)
                                Divider()
                                HStack(spacing: 10) {
                                    Image(systemName: "arrow.up.right.circle.fill").font(.title2).foregroundColor(.yellow)
                                    VStack(alignment: .leading) {
                                        Text("Score Multiplier").font(.headline)
                                        Text("Increases as game time progresses:").font(.subheadline).foregroundColor(.secondary)
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text("• Start: **1.0x**")
                                            Text("• Mid-game: **1.5x**")
                                            Text("• Late-game: **2.0x**")
                                        }.font(.caption).foregroundColor(.gray).padding(.leading, 15)
                                    }
                                }
                                .padding(.vertical, 5)
                            }
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .frame(width: demoAreaSize.width * 0.9, height: demoAreaSize.height)
                        .background(Material.regularMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 25))
                        .shadow(radius: 5)
                    case .learnHearts:
                        VStack(spacing: 25) {
                            HStack(spacing: 10) {
                                ForEach(0..<3) { index in
                                    Image(systemName: index < tutorialHeartsToShow ? "heart.fill" : "heart")
                                        .font(.system(size: 40))
                                        .foregroundColor(index < tutorialHeartsToShow ? .pink : .gray.opacity(0.6))
                                        .scaleEffect(index < tutorialHeartsToShow ? 1.1 : 1.0)
                                        .animation(.spring(response: 0.4, dampingFraction: 0.5).delay(Double(index) * 0.1), value: tutorialHeartsToShow)
                                }
                            }
                            .padding(.bottom, 10)
                            VStack(alignment: .leading, spacing: 15) {
                                Text("You start with **3 hearts**.").font(.title3.weight(.medium))
                                HStack(alignment: .top) {
                                    Image(systemName: "exclamationmark.shield.fill").foregroundColor(.yellow).font(.title2)
                                    Text("Letting a hologram expire (like the one above!) makes you **lose 1 heart**.")
                                }
                                HStack(alignment: .top) {
                                     Image(systemName: "gamecontroller.fill").foregroundColor(.red).font(.title2)
                                    Text("If you lose all 3 hearts, the **game ends!**")
                                }
                            }
                            .font(.headline)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)
                        }
                        .padding(30)
                        .frame(width: demoAreaSize.width * 0.85, height: demoAreaSize.height * 0.8)
                        .background(Material.regularMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 25))
                        .shadow(radius: 5)
                        if let hologram = demoHeartLossHologram {
                            HologramView()
                                .position(hologram.position)
                                .transition(.asymmetric(insertion: .scale.animation(.spring()), removal: .opacity.animation(.easeInOut(duration: 0.3))))
                        }
                    }
                }
                .frame(width: demoAreaSize.width, height: demoAreaSize.height)
                .background(currentStep == .learnScoring || currentStep == .learnHearts ? Color.clear : Color.gray.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0, coordinateSpace: .local)
                        .onChanged { value in
                            guard currentStep != .learnDistractions && currentStep != .learnScoring && currentStep != .learnHearts else { return }
                            
                            if !isDraggingCircle {
                                isDraggingCircle = true
                                dragStartCirclePosition = circlePosition
                            }
                            
                            let newX = dragStartCirclePosition.x + value.translation.width
                            let newY = dragStartCirclePosition.y + value.translation.height

                            let clampedX = max(mainCircleVisualRadius, min(newX, demoAreaSize.width - mainCircleVisualRadius))
                            let clampedY = max(mainCircleVisualRadius, min(newY, demoAreaSize.height - mainCircleVisualRadius))
                            
                            self.circlePosition = CGPoint(x: clampedX, y: clampedY)

                            switch currentStep {
                            case .dragCircle:
                                if !hasDraggedOnce {
                                    hasDraggedOnce = true
                                    currentSubtitle = "Great job! This is your tool. Get comfortable, then tap Next."
                                    showNextButtonReadyAnimation = true
                                    startNextButtonAnimation()
                                }
                            case .catchHologram:
                                checkHologramCollisions()
                            default:
                                break
                            }
                        }
                        .onEnded { _ in
                            isDraggingCircle = false
                        }
                )
                
                Spacer()

                HStack {
                    Spacer()
                    Button(action: { handleNextAction() }) {
                        Text(currentStep == .learnHearts ? "Start Game!" : "Next")
                            .font(.system(size: 17, weight: .medium, design: .rounded))
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                    }
                    .buttonStyle(.bordered)
                    .disabled(nextButtonDisabled())
                    .scaleEffect(showNextButtonReadyAnimation ? nextButtonScale : 1.0)
                }
                .frame(height: 70)
                .padding(.bottom, geometry.safeAreaInsets.bottom > 0 ? geometry.safeAreaInsets.bottom : 30)
                .padding(.horizontal, 40)
            }
            .onAppear {
                self.viewSize = geometry.size
                setupDemoArea(with: geometry.size)
                setupStep(currentStep)
            }
            .onDisappear {
                stopHologramTimers()
                stopDistractionTimer()
                stopHeartLossDemoTimer()
            }
            .onChange(of: geometry.size) { oldSize, newSize in
                self.viewSize = newSize
                setupDemoArea(with: newSize)
                if !isDraggingCircle && self.demoAreaSize != .zero {
                    self.circlePosition = CGPoint(x: self.demoAreaSize.width / 2, y: self.demoAreaSize.height / 2)
                    self.dragStartCirclePosition = self.circlePosition
                }
            }
            .alert("Skip Tutorial", isPresented: $showSkipAlert) {
                Button("Skip", role: .destructive) { completeTutorial() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("You are about to skip the tutorial. Are you sure?")
            }
            .fullScreenCover(isPresented: $showHomeView) {
                Home()
            }
        }
        .preferredColorScheme(.dark)
        .glassBackgroundEffect()
    }

    private func setupDemoArea(with size: CGSize) {
        self.demoAreaSize = CGSize(width: max(400, size.width * 0.7), height: max(350, size.height * 0.5))
    }
    
    private func setupStep(_ step: VisionOSTutorialStep) {
        currentStep = step
        showNextButtonReadyAnimation = false
        nextButtonScale = 1.0
        
        stopHologramTimers()
        stopDistractionTimer()
        stopHeartLossDemoTimer()

        switch step {
        case .dragCircle:
            currentTitle = "Control your Circle"
            currentSubtitle = "Drag the circle around with your gaze or finger."
            hasDraggedOnce = false
            if self.demoAreaSize != .zero {
                self.circlePosition = CGPoint(x: self.demoAreaSize.width / 2, y: self.demoAreaSize.height / 2)
                self.dragStartCirclePosition = self.circlePosition
            }
        case .catchHologram:
            currentTitle = "Catch the Holograms"
            currentSubtitle = "Catch \(hologramsToCatchGoal) holograms. They will disappear if not caught quickly!"
            hologramsCaughtCount = 0
            activeTutorialHolograms.removeAll()
            activeSparkEffects.removeAll()
            activeFlyingPoints.removeAll()
            if self.demoAreaSize != .zero {
                self.circlePosition = CGPoint(x: self.demoAreaSize.width / 2, y: self.demoAreaSize.height / 2)
                self.dragStartCirclePosition = self.circlePosition
            }
            startHologramSpawningAndExpiration()
        case .learnDistractions:
            currentTitle = "Watch out for Distractions!"
            currentSubtitle = "These distraction will try to break your focus."
            sampleDistraction = nil
            showNextButtonReadyAnimation = true
            startNextButtonAnimation()
            if demoAreaSize != .zero {
                 self.circlePosition = CGPoint(x: self.demoAreaSize.width / 2, y: self.demoAreaSize.height / 2)
                self.dragStartCirclePosition = self.circlePosition
                startDistractionTimer()
            }
        case .learnScoring:
            currentTitle = "Scoring Rules"
            currentSubtitle = "Maximize your score with these tips:"
            showNextButtonReadyAnimation = true
            startNextButtonAnimation()
            activeTutorialHolograms.removeAll(); activeSparkEffects.removeAll(); activeFlyingPoints.removeAll(); sampleDistraction = nil
        case .learnHearts:
            currentTitle = "Stay in the Game!"
            currentSubtitle = "Save your hearts to keep playing:"
            tutorialHeartsToShow = 3
            demoHeartLossHologram = nil
            showNextButtonReadyAnimation = true
            startNextButtonAnimation()
            activeTutorialHolograms.removeAll(); activeSparkEffects.removeAll(); activeFlyingPoints.removeAll(); sampleDistraction = nil
            startHeartLossDemo()
        }
    }

    private func startNextButtonAnimation() {
        withAnimation(Animation.easeInOut(duration: 0.5).repeatForever(autoreverses: true)) {
            nextButtonScale = 1.1
        }
    }

    private func nextButtonDisabled() -> Bool {
        switch currentStep {
        case .dragCircle:
            return !hasDraggedOnce
        case .catchHologram:
            return hologramsCaughtCount < hologramsToCatchGoal
        case .learnDistractions, .learnScoring:
            return false
        case .learnHearts:
            return false
        }
    }

    private func handleNextAction() {
        switch currentStep {
        case .dragCircle:
            setupStep(.catchHologram)
        case .catchHologram:
            setupStep(.learnDistractions)
        case .learnDistractions:
            setupStep(.learnScoring)
        case .learnScoring:
            setupStep(.learnHearts)
        case .learnHearts:
            completeTutorial()
        }
    }
    
    private func completeTutorial() {
        stopHologramTimers()
        stopDistractionTimer()
        stopHeartLossDemoTimer()

        let descriptor = FetchDescriptor<UserProgress>()
        if let progress = try? modelContext.fetch(descriptor).first {
            progress.hasCompletedOnboarding = true
        } else {
            let newProgress = UserProgress(hasCompletedOnboarding: true) 
            modelContext.insert(newProgress)
        }
        
        do {
            try modelContext.save()
        } catch {
        }
        
        showHomeView = true
    }

    private func startHologramSpawningAndExpiration() {
        stopHologramTimers()

        hologramSpawnTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { _ in
            spawnTutorialHologram()
        }
        spawnTutorialHologram()
        if activeTutorialHolograms.count < maxConcurrentTutorialHolograms {
             DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { spawnTutorialHologram() }
        }

        hologramCheckTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
            checkExpiredHolograms()
        }
    }

    private func stopHologramTimers() {
        hologramSpawnTimer?.invalidate()
        hologramSpawnTimer = nil
        hologramCheckTimer?.invalidate()
        hologramCheckTimer = nil
    }

    private func spawnTutorialHologram() {
        guard activeTutorialHolograms.count < maxConcurrentTutorialHolograms, demoAreaSize != .zero else { return }
        
        let padding: CGFloat = TutorialHologram.radius + 10
        let spawnX = CGFloat.random(in: padding...(demoAreaSize.width - padding))
        let spawnY = CGFloat.random(in: padding...(demoAreaSize.height - padding))
        let newPosition = CGPoint(x: spawnX, y: spawnY)

        if newPosition.distance(to: circlePosition) < mainCircleVisualRadius + TutorialHologram.radius + 20 { 
            return 
        }

        let newHologram = TutorialHologram(position: newPosition)
        withAnimation { 
             activeTutorialHolograms.append(newHologram)
        }
    }

    private func checkExpiredHolograms() {
        let now = Date()
        activeTutorialHolograms.removeAll { hologram in
            if now.timeIntervalSince(hologram.creationTime) > TutorialHologram.lifespan {
                return true 
            }
            return false
        }
    }
    
    private func checkHologramCollisions() {
        guard !activeTutorialHolograms.isEmpty, hologramsCaughtCount < hologramsToCatchGoal else { return }

        var caughtIDs: [UUID] = []
        for hologram in activeTutorialHolograms {
            let distance = circlePosition.distance(to: hologram.position)
            let catchThreshold = mainCircleVisualRadius * 0.5 + TutorialHologram.radius * 0.8
            
            if distance < catchThreshold {
                caughtIDs.append(hologram.id)
                hologramsCaughtCount += 1
                triggerSparkEffect(at: hologram.position)
                triggerFlyingPoint(text: "+3", at: hologram.position) 
                
                if hologramsCaughtCount >= hologramsToCatchGoal {
                    currentSubtitle = "Great! You've caught \(hologramsCaughtCount) holograms. Tap Next to continue."
                    showNextButtonReadyAnimation = true
                    startNextButtonAnimation()
                    stopHologramTimers() 
                    activeTutorialHolograms.removeAll() 
                    break 
                } else {
                    currentSubtitle = "Caught \(hologramsCaughtCount)/\(hologramsToCatchGoal). Keep going!"
                }
            }
        }
        
        if !caughtIDs.isEmpty {
            withAnimation { 
                activeTutorialHolograms.removeAll { caughtIDs.contains($0.id) }
            }
        }
    }

    private func triggerSparkEffect(at position: CGPoint) {
        let newEffect = TutorialSparkEffect(position: position)
        activeSparkEffects.append(newEffect)
    }

    private func removeSparkEffect(id: UUID) {
        activeSparkEffects.removeAll { $0.id == id }
    }
    
    private func triggerFlyingPoint(text: String, at position: CGPoint) {
        let newPoint = FlyingPoint(text: text, position: position)
        activeFlyingPoints.append(newPoint)
    }
    
    private func removeFlyingPoint(id: UUID) {
        activeFlyingPoints.removeAll { $0.id == id }
    }

    private func startDistractionTimer() {
        stopDistractionTimer() 
        distractionAppearTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: false) { _ in
            showSampleDistraction()
        }
    }

    private func stopDistractionTimer() {
        distractionAppearTimer?.invalidate()
        distractionAppearTimer = nil
    }

    private func showSampleDistraction() {
        guard demoAreaSize != .zero else { return } 
        
        let distractionX = demoAreaSize.width * 0.5
        let distractionY = demoAreaSize.height * 0.25 

        sampleDistraction = Distraction(
            position: CGPoint(x: distractionX, y: distractionY),
            title: "Upcoming Event",
            message: "Project Deadline in 1 hour!",
            appIcon: "calendar.badge.exclamationmark",
            iconColors: [.orange, .red],
            soundID: 0 
        )
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) { 
            if currentStep == .learnDistractions { 
                self.sampleDistraction = nil 
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { 
                if currentStep == .learnDistractions {
                    let anotherDistractionX = demoAreaSize.width * 0.5
                    let anotherDistractionY = demoAreaSize.height * 0.35 
                    self.sampleDistraction = Distraction(
                        position: CGPoint(x: anotherDistractionX, y: anotherDistractionY),
                        title: "New Message",
                        message: "Ideas for the weekend?",
                        appIcon: "message.fill",
                        iconColors: [.blue, .purple],
                        soundID: 0
                    )
                }
            }
        }
    }

    private func startHeartLossDemo() {
        stopHeartLossDemoTimer() 
        guard demoAreaSize != .zero else { return }

        let hologramDemoPosition = CGPoint(x: demoAreaSize.width / 2, y: demoAreaSize.height * 0.20) 

        heartLossDemoTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: false) { _ in
            guard self.currentStep == .learnHearts else { self.stopHeartLossDemoTimer(); return } 
            
            withAnimation {
                self.demoHeartLossHologram = TutorialHologram(position: hologramDemoPosition)
            }

            self.heartLossDemoTimer = Timer.scheduledTimer(withTimeInterval: 2.5, repeats: false) { _ in
                guard self.currentStep == .learnHearts else { self.stopHeartLossDemoTimer(); return }
                
                withAnimation {
                    self.demoHeartLossHologram = nil 
                    self.tutorialHeartsToShow = 2   
                }

                self.heartLossDemoTimer = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: false) { _ in
                    guard self.currentStep == .learnHearts else { self.stopHeartLossDemoTimer(); return }
                    
                    withAnimation {
                        self.tutorialHeartsToShow = 3   
                    }
                    self.stopHeartLossDemoTimer() 
                }
            }
        }
    }

    private func stopHeartLossDemoTimer() {
        heartLossDemoTimer?.invalidate()
        heartLossDemoTimer = nil
    }
}

#endif
