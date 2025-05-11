//
//  visionOSContentView.swift
//  DistractionDodge
//
//  Created by Ayush Kumar Singh on 5/5/25.
//
#if os(visionOS)
import SwiftUI
import SwiftData
// Note: Hologram, HologramView, CollisionEffect, SparkleExplosionView definitions
// have been moved to their own files in Game/Models/ and SharedViews/

struct visionOSContentView: View {
    // MARK: - Properties
    private let totalGameDuration: Double
    @StateObject private var attentionViewModel: AttentionViewModel
    @ObservedObject var healthKitManager: HealthKitManager

    @State private var circlePosition: CGPoint = .zero
    @State private var isDragging = false
    @State private var dragStartCirclePosition: CGPoint = .zero
    
    let circleDiameter: CGFloat = 200
    var circleRadius: CGFloat { circleDiameter / 2 }
    private let dragSensitivityMultiplier: CGFloat = 1.0

    @State private var activeHolograms: [Hologram] = []
    @State private var viewSize: CGSize = .zero

    @State private var hologramSpawnTimer: Timer?
    
    private let initialHologramLifespan_const: TimeInterval = 6.0
    private let finalHologramLifespan_const: TimeInterval = 2.5
    private let initialMaxHolograms_const: Int = 2
    private let finalMaxHolograms_const: Int = 4
    private let initialSpawnIntervalRange_const: ClosedRange<Double> = 2.5...4.5
    private let finalSpawnIntervalRange_const: ClosedRange<Double> = 1.0...2.5

    let hologramDiameter: CGFloat = 90 
    var hologramRadius_prop: CGFloat { hologramDiameter / 2 }

    @State private var activeCollisionEffects: [CollisionEffect] = []
    @State private var showGameOverView = false
    @State private var showPauseMenu = false
    @State private var showConclusionView = false


    // MARK: - Init
    init(duration: Double = 60.0, modelContext: ModelContext, healthKitManager: HealthKitManager) {
        self.totalGameDuration = duration
        _attentionViewModel = StateObject(wrappedValue: AttentionViewModel(modelContext: modelContext))
        self.healthKitManager = healthKitManager
    }

    // MARK: - Computed Properties for Difficulty
    private var currentHologramLifespan_prop: TimeInterval {
        let progress = max(0, min(1, (attentionViewModel.totalGameDuration - attentionViewModel.gameTime) / attentionViewModel.totalGameDuration))
        return initialHologramLifespan_const - (initialHologramLifespan_const - finalHologramLifespan_const) * progress
    }

    private var currentMaxHolograms_prop: Int {
        let progress = max(0, min(1, (attentionViewModel.totalGameDuration - attentionViewModel.gameTime) / attentionViewModel.totalGameDuration))
        let count = Double(initialMaxHolograms_const) + Double(finalMaxHolograms_const - initialMaxHolograms_const) * progress
        return Int(round(count))
    }
    
    private var currentSpawnInterval_prop: ClosedRange<Double> {
        let progress = max(0, min(1, (attentionViewModel.totalGameDuration - attentionViewModel.gameTime) / attentionViewModel.totalGameDuration))
        let minInterval = initialSpawnIntervalRange_const.lowerBound - (initialSpawnIntervalRange_const.lowerBound - finalSpawnIntervalRange_const.lowerBound) * progress
        let maxInterval = initialSpawnIntervalRange_const.upperBound - (initialSpawnIntervalRange_const.upperBound - finalSpawnIntervalRange_const.upperBound) * progress
        return minInterval...maxInterval
    }

    // MARK: - Helper Functions
    private func formatTime_helper(_ seconds: TimeInterval) -> String {
        let totalSeconds = Int(seconds)
        let minutes = totalSeconds / 60
        let secondsValue = totalSeconds % 60
        return String(format: "%02d:%02d", minutes, secondsValue)
    }
    
    // MARK: - ViewBuilder Layers (used by GameAreaView)
    @ViewBuilder
    private func buildDraggableCircle(geometry: GeometryProxy) -> some View {
        MainCircle(
            isGazingAtTarget: self.isDragging,
            position: self.circlePosition
        )
        .hoverEffect()
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    guard self.attentionViewModel.gameActive && !self.attentionViewModel.isPaused else { return }
                    if !self.isDragging {
                        self.isDragging = true
                        self.dragStartCirclePosition = self.circlePosition
                    }
                    let newX = self.dragStartCirclePosition.x + (value.translation.width * self.dragSensitivityMultiplier)
                    let newY = self.dragStartCirclePosition.y + (value.translation.height * self.dragSensitivityMultiplier)
                    let clampedX = max(self.circleRadius, min(newX, geometry.size.width - self.circleRadius))
                    let clampedY = max(self.circleRadius, min(newY, geometry.size.height - self.circleRadius))
                    self.circlePosition = CGPoint(x: clampedX, y: clampedY)
                    self.checkCollisions()
                }
                .onEnded { value in
                    guard self.attentionViewModel.gameActive && !self.attentionViewModel.isPaused else { return }
                    self.isDragging = false
                    self.checkCollisions()
                }
        )
    }

    @ViewBuilder
    private var buildHologramLayer: some View {
        ForEach(self.activeHolograms) { hologram in
            HologramView().position(hologram.position)
        }
    }

    @ViewBuilder
    private var buildCollisionEffectsLayer: some View {
        ForEach(self.activeCollisionEffects) { effect in
            SparkleExplosionView(onComplete: { self.removeCollisionEffect(id: effect.id) })
                .position(effect.position)
                .allowsHitTesting(false)
        }
    }

    @ViewBuilder
    private var buildDistractionsLayer: some View {
        ForEach(self.attentionViewModel.distractions) { distraction in
            VisionOSDistractionView(distraction: distraction) 
                .position(distraction.position)
                .allowsHitTesting(false)
        }
    }


    @ViewBuilder
    private var buildGameInfoDisplay: some View {
        VStack {
            HStack {
                HStack(spacing: 10) {
                    FloatingCard(
                        title: "Time",
                        value: formatTime_helper(attentionViewModel.gameTime),
                        glowCondition: attentionViewModel.gameTime < 10 && attentionViewModel.gameTime > 0,
                        glowColor: .red
                    )
                    FloatingCard(
                        title: "Score",
                        value: "\(attentionViewModel.score)",
                        glowCondition: attentionViewModel.score > 0,
                        glowColor: .yellow
                    )
                    FloatingCard(
                        title: "Streak",
                        value: "\(attentionViewModel.visionOSCatchStreak)",
                        glowCondition: attentionViewModel.visionOSCatchStreak >= 5,
                        glowColor: .cyan
                    )
                    FloatingCard(
                        title: "Multiplier",
                        value: String(format: "%.1fx", attentionViewModel.visionOSScoreMultiplier),
                        glowCondition: attentionViewModel.visionOSScoreMultiplier > 1.0,
                        glowColor: .cyan
                    )
                }
                
                Spacer()
                
                HStack(spacing: 15) {
                    HStack(spacing: 6) {
                        ForEach(0..<3) { index in
                            Image(systemName: index < attentionViewModel.visionOSRemainingHearts ? "heart.fill" : "heart")
                                .foregroundColor(index < attentionViewModel.visionOSRemainingHearts ? .pink : .gray.opacity(0.5))
                                .font(.system(size: 26))
                                .animation(.spring(response: 0.3, dampingFraction: 0.5), value: attentionViewModel.visionOSRemainingHearts)
                        }
                    }
                    
                    Button {
                        attentionViewModel.pauseGame()
                        showPauseMenu = true
                    } label: {
                        Image(systemName: "pause.circle.fill")
                            .font(.system(size: 30, weight: .medium))
                            .foregroundColor(.white.opacity(0.85))
                    }
                    .buttonStyle(.plain)
                }
                .padding(.trailing, 5)
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }


    // MARK: - Main Body
    var body: some View {
        GeometryReader { geometry in
            _GameAreaView(
                parent: self,
                geometry: geometry
            )
            .onAppear {
                self.viewSize = geometry.size
                self.attentionViewModel.updateViewSize(geometry.size)
                self.attentionViewModel.setGameDuration(self.totalGameDuration)
                self.startGame()
            }
            .onDisappear {
                self.stopGame()
            }
            .onChange(of: geometry.size) { oldSize, newSize in
                 self.viewSize = newSize
                 self.attentionViewModel.updateViewSize(newSize)
                 if !self.isDragging && self.attentionViewModel.gameActive && self.viewSize != .zero {
                     self.circlePosition = CGPoint(x: self.viewSize.width / 2, y: self.viewSize.height / 2)
                     self.attentionViewModel.visionOSCirclePosition = self.circlePosition
                 }
            }
            .onChange(of: self.circlePosition) { oldValue, newValue in
                self.attentionViewModel.visionOSCirclePosition = newValue
            }
            .onChange(of: self.activeHolograms) { oldValue, newValue in
                self.attentionViewModel.visionOSHologramPositions = newValue.map { $0.position }
            }
            .onChange(of: attentionViewModel.gameID) { _, newGameID in
                guard attentionViewModel.gameActive else { return }

                self.activeHolograms.removeAll()
                self.activeCollisionEffects.removeAll()
                self.showGameOverView = false
                self.showPauseMenu = false

                if self.viewSize != .zero {
                    self.circlePosition = CGPoint(x: self.viewSize.width / 2, y: self.viewSize.height / 2)
                    self.attentionViewModel.visionOSCirclePosition = self.circlePosition
                }
                self.isDragging = false

                if attentionViewModel.isVisionOSMode {
                    self.stopHologramSpawning()
                    self.startHologramSpawning()
                }
            }
            .onChange(of: attentionViewModel.gameActive) { _, isActive in
                if !isActive && !attentionViewModel.isPaused {
                    self.stopHologramSpawning() 

                    if attentionViewModel.endGameReason == .heartsDepleted {
                        self.showGameOverView = true
                    } else if attentionViewModel.endGameReason == .timeUp {
                        self.showConclusionView = true
                    }
                    self.activeHolograms.removeAll()
                    self.activeCollisionEffects.removeAll()
                }
            }
            .sheet(isPresented: $showGameOverView) {
                GameObstructionView(viewModel: attentionViewModel, isPresented: $showGameOverView)
            }
            .sheet(isPresented: $showPauseMenu) {
                PauseMenuView(viewModel: attentionViewModel)
            }
            .sheet(isPresented: $showConclusionView) {
                ConclusionView(viewModel: attentionViewModel, healthKitManager: healthKitManager)
            }
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)) { _ in
                if attentionViewModel.gameActive && !attentionViewModel.isPaused {
                    attentionViewModel.pauseGame()
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
                // ViewModel handles its own resume logic
            }
        }
    }
    
    // MARK: - Private _GameAreaView Struct
    private struct _GameAreaView: View {
        let parent: visionOSContentView
        let geometry: GeometryProxy

        var body: some View {
            ZStack {
                parent.buildDraggableCircle(geometry: geometry)
                parent.buildHologramLayer
                parent.buildCollisionEffectsLayer
                parent.buildDistractionsLayer
                parent.buildGameInfoDisplay
            }
            .overlay {
                if parent.attentionViewModel.isPaused && parent.showPauseMenu {
                    Color.black.opacity(0.4)
                        .ignoresSafeArea()
                        .transition(.opacity)
                }
            }
        }
    }

    // MARK: - Game Lifecycle
    func startGame() {
        isDragging = false
        showGameOverView = false
        showPauseMenu = false
        showConclusionView = false
        attentionViewModel.startGame(isVisionOSGame: true)
    }

    func stopGame() {
        stopHologramSpawning()
        attentionViewModel.stopGame(isVisionOSGame: true)
    }

    // MARK: - Hologram Mechanics
    func startHologramSpawning() {
        guard attentionViewModel.gameActive, !attentionViewModel.isPaused else { return }
        stopHologramSpawning()
        
        let spawnInterval = Double.random(in: currentSpawnInterval_prop)
        hologramSpawnTimer = Timer.scheduledTimer(withTimeInterval: spawnInterval, repeats: false) { _ in
            if self.attentionViewModel.gameActive, !self.attentionViewModel.isPaused,
               self.viewSize != .zero && self.activeHolograms.count < self.currentMaxHolograms_prop {
                self.spawnHologram()
            }
            if self.attentionViewModel.gameActive, !self.attentionViewModel.isPaused {
                self.startHologramSpawning()
            }
        }
    }

    func stopHologramSpawning() {
        hologramSpawnTimer?.invalidate()
        hologramSpawnTimer = nil
    }

    func spawnHologram() {
        guard attentionViewModel.gameActive, !attentionViewModel.isPaused,
              viewSize.width > hologramDiameter && viewSize.height > hologramDiameter else { return }
        var newPosition: CGPoint
        var attempts = 0
        let maxAttempts = 10
        let mainCircleTrueRadius = self.circleRadius
        let hologramTrueRadius = self.hologramRadius_prop
        
        let safeSpawnPadding: CGFloat = 20
        let minX = hologramTrueRadius + safeSpawnPadding
        let maxX = viewSize.width - hologramTrueRadius - safeSpawnPadding
        let minY = hologramTrueRadius + safeSpawnPadding
        let maxY = viewSize.height - hologramTrueRadius - safeSpawnPadding
        
        guard maxX > minX && maxY > minY else {
            return
        }

        find_position_loop: repeat {
            attempts += 1
            if attempts > maxAttempts {
                return
            }
            newPosition = CGPoint(x: CGFloat.random(in: minX...maxX),
                                  y: CGFloat.random(in: minY...maxY))
            
            let distToCircle = newPosition.distance(to: self.circlePosition)
            if distToCircle < (mainCircleTrueRadius + hologramTrueRadius + 50) {
                continue find_position_loop
            }

            for existingHologram in activeHolograms {
                let distance = newPosition.distance(to: existingHologram.position)
                if distance < (hologramDiameter + 20) { 
                    continue find_position_loop
                }
            }
            break
        } while true
        
        let newHologram = Hologram(position: newPosition)
        withAnimation(.spring()) { activeHolograms.append(newHologram) }

        DispatchQueue.main.asyncAfter(deadline: .now() + currentHologramLifespan_prop) {
            if self.attentionViewModel.gameActive, !self.attentionViewModel.isPaused,
               let index = self.activeHolograms.firstIndex(where: { $0.id == newHologram.id }) {
                self.activeHolograms.remove(at: index)
                self.attentionViewModel.handleVisionOSHologramExpired()
            }
        }
    }

    func removeHologram(id: UUID) {
        activeHolograms.removeAll { $0.id == id }
    }

    // MARK: - Collision Effect Mechanics
    func triggerCollisionEffect(at position: CGPoint) {
        let newEffect = CollisionEffect(position: position)
        activeCollisionEffects.append(newEffect)
    }

    func removeCollisionEffect(id: UUID) {
        activeCollisionEffects.removeAll { $0.id == id }
    }

    func checkCollisions() {
        guard attentionViewModel.gameActive, !attentionViewModel.isPaused, !activeHolograms.isEmpty else { return }
        var caughtHologramIDsAndPositions: [(UUID, CGPoint)] = []
        for hologram in activeHolograms {
            let distance = circlePosition.distance(to: hologram.position)
            let catchThreshold = hologramRadius_prop + circleRadius * 0.3 
            if distance < catchThreshold {
                caughtHologramIDsAndPositions.append((hologram.id, hologram.position))
            }
        }
        for (id, position) in caughtHologramIDsAndPositions {
            withAnimation(.easeOut(duration: 0.2)) { removeHologram(id: id) }
            triggerCollisionEffect(at: position)
            attentionViewModel.handleVisionOSCatch()
        }
    }
}
#endif
