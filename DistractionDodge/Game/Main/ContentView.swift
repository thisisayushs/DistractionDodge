//
//  ContentView.swift
//  DistractionDodge
//
//  Created by Ayush Kumar Singh on 12/28/24.
//

#if os(iOS)

import SwiftUI
import AVFoundation
import SwiftData

/// The main game view for the iOS version of DistractionDodge.
///
/// `ContentView` is responsible for displaying the core gameplay elements, including:
/// - The eye-tracking overlay (`EyeTrackingView`) to monitor user gaze.
/// - The primary focus target (`MainCircle`).
/// - Dynamic distractions (`NotificationView`, `VideoDistraction`).
/// - Real-time game information display (`FloatingCard` for time, score, streak, multiplier).
/// - A pause button and associated pause menu (`PauseMenuView`).
///
/// It uses `AttentionViewModel` to manage game logic, state, and data.
/// The view's size is determined using `GeometryReader` and passed to the `AttentionViewModel`
/// for correct element positioning and game mechanics.
///
/// Game state changes, such as game over or obstruction, trigger navigation to
/// `ConclusionView` or `GameObstructionView` respectively.
///
/// - Note: This view is specific to iOS due to its reliance on `EyeTrackingView` and ARKit.
///   A separate view handles the visionOS game experience.
struct ContentView: View {
    // MARK: - Properties
    
    /// The SwiftData model context, used by `AttentionViewModel` for data persistence.
    @Environment(\.modelContext) private var modelContext
    /// The main view model managing game state, logic, and data.
    @StateObject private var viewModel: AttentionViewModel
    /// Manages HealthKit interactions, such as saving mindful minutes.
    @ObservedObject var healthKitManager: HealthKitManager
    
    /// Controls the presentation of the `GameObstructionView` when a distraction is tapped.
    @State private var gameObstructed = false
    
    /// Controls the navigation to the `ConclusionView` when the game ends due to time up.
    @State private var showConclusion = false
    
    /// Controls the presentation of the `PauseMenuView`.
    @State private var showPauseMenu = false
    
    /// The current screen position for the `VideoDistraction` element.
    @State private var videoPosition: CGPoint = .zero
    
    /// Gradient colors used for the background of the game view.
    private let gradientColors: [Color] = [
        .black.opacity(0.8),
        .purple.opacity(0.2)
    ]
    
    /// Initializes the `ContentView` with a specified game duration and HealthKit manager.
    /// - Parameters:
    ///   - duration: The total duration for the game session in seconds. Defaults to 60 seconds.
    ///   - healthKitManager: The `HealthKitManager` instance for HealthKit integration.
    init(duration: Double = 60, healthKitManager: HealthKitManager) {
        // Initializes AttentionViewModel internally, ensuring it has a ModelContext.
        // This ModelContext is created here; ideally, it should be passed from a higher level
        // if ContentView is part of a larger SwiftData-managed application structure.
        let viewModel = AttentionViewModel(modelContext: ModelContext(try! ModelContainer(for: GameSession.self, UserProgress.self)))
        viewModel.setGameDuration(duration)
        _viewModel = StateObject(wrappedValue: viewModel)
        self.healthKitManager = healthKitManager
    }
    
    /// Formats a time interval (in seconds) into a "MM:SS" string.
    /// - Parameter seconds: The time interval in seconds.
    /// - Returns: A string representing the formatted time (e.g., "01:30").
    private func formatTime(_ seconds: TimeInterval) -> String {
        let totalSeconds = Int(seconds)
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
               
                LinearGradient(
                    gradient: Gradient(colors: gradientColors),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                    .edgesIgnoringSafeArea(.all) // This modifier is fine on the gradient
                    .animation(.easeInOut(duration: 2.0), value: viewModel.backgroundGradient)
                

                // --- Eye Tracking Handling ---
                
                
                EyeTrackingView { isGazing in
                    viewModel.updateGazeStatus(isGazing)
                }
                
                .edgesIgnoringSafeArea(.all)
               

                // VideoDistraction - placed after geometry is known
                VideoDistraction()
                    .position(videoPosition) // Use the state variable
                     .opacity(viewModel.gameTime < (viewModel.totalGameDuration * 0.6) ? 1 : 0)
                    .animation(.easeInOut(duration: 1.0), value: viewModel.gameTime)
                    .environmentObject(viewModel)

                ForEach(Array(zip(viewModel.distractions.indices, viewModel.distractions)), id: \.1.id) { index, distraction in
                    NotificationView(distraction: distraction, index: index)
                        .position(distraction.position)
                        .environmentObject(viewModel)
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
                
                MainCircle(
                    isGazingAtTarget: viewModel.isGazingAtObject,
                    position: viewModel.position
                )
                
                VStack {
                    HStack(spacing: 20) {
                        FloatingCard(
                            title: "Time",
                            value: formatTime(viewModel.gameTime),
                            glowCondition: viewModel.gameTime <= 10,
                            glowColor: .red
                        )
                        
                        FloatingCard(
                            title: "Score",
                            value: "\(viewModel.score)",
                            glowCondition: viewModel.score >= 100,
                            glowColor: .yellow
                        )
                        
                        FloatingCard(
                            title: "Streak",
                            value: "\(Int(viewModel.focusStreak))s",
                            glowCondition: viewModel.focusStreak >= 10,
                            glowColor: .orange
                        )
                        
                        FloatingCard(
                            title: "Multiplier",
                            value: "\(viewModel.scoreMultiplier)x",
                            glowCondition: viewModel.scoreMultiplier == 3,
                            glowColor: .cyan
                        )
                        
                        Spacer()
                        
                        Button {
                            viewModel.pauseGame()
                            showPauseMenu = true
                        } label: {
                            Image(systemName: "pause.circle.fill")
                                .font(.system(size: 35))
                                .foregroundStyle(
                                    .linearGradient(
                                        colors: [.white, .white.opacity(0.7)],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                                .frame(width: 44, height: 44)
                        }
                        
                        .padding(.trailing, 20)
                    }
                    .padding(.top, 40)
                    .padding(.leading)
                    
                    Spacer()
                }
            } // End ZStack
            .onAppear {
                // Set initial video position using geometry FIRST
                videoPosition = CGPoint(x: geometry.size.width * 0.6,
                                        y: geometry.size.height * 0.6)

                // Pass the view size to the ViewModel
                viewModel.updateViewSize(geometry.size)

                // Start the game logic AFTER size setup and potential gaze simulation
                viewModel.updateModelContext(modelContext)
                viewModel.startGame()
            }
            .onChange(of: geometry.size) { oldSize, newSize in
                 viewModel.updateViewSize(newSize)
                 videoPosition = CGPoint(x: newSize.width * 0.6, y: newSize.height * 0.6)
            }
        } // End GeometryReader
        .onDisappear {
            viewModel.stopGame()
        }
        .onChange(of: viewModel.gameActive) { wasActive, isActive in
            if !isActive && wasActive {
                if viewModel.endGameReason == .timeUp {
                    showConclusion = true
                } else {
                    gameObstructed = true
                }
            }
        }
        .preferredColorScheme(.dark)
        .statusBarHidden(true)
        .persistentSystemOverlays(.hidden)
        .sheet(isPresented: $gameObstructed) {
            GameObstructionView(viewModel: viewModel, isPresented: $gameObstructed)
        }
        .fullScreenCover(isPresented: $showConclusion) {
            ConclusionView(viewModel: viewModel, healthKitManager: healthKitManager)
        }
        .sheet(isPresented: $showPauseMenu) {
            PauseMenuView(viewModel: viewModel)
        }
    }
}

#endif
