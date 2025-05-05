//
//  ContentView.swift
//  DistractionDodge
//
//  Created by Ayush Kumar Singh on 28/12/24.
//

import SwiftUI
import AVFoundation
import SwiftData

/// The main game view where users practice maintaining focus while avoiding distractions.
///
/// ContentView implements the core game mechanics of the focus training app:
/// - Eye tracking to detect user's gaze on the target
/// - Progressive difficulty with timed distractions
/// - Real-time score tracking and feedback
/// - Pause functionality and game state management
struct ContentView: View {
    // MARK: - Properties
    
    @Environment(\.modelContext) private var modelContext
    @StateObject private var viewModel: AttentionViewModel
    
    /// Controls the game obstructed overlay.
    @State private var gameObstructed = false
    
    /// Controls navigation to conclusion screen
    @State private var showConclusion = false
    
    /// Controls display of pause menu
    @State private var showPauseMenu = false
    
    /// Position of video distraction element
    @State private var videoPosition = CGPoint(x: UIScreen.main.bounds.width * 0.6,
                                              y: UIScreen.main.bounds.height * 0.6)
    
    /// Gradient colors for background effect
    private let gradientColors: [Color] = [
        .black.opacity(0.8),
        .purple.opacity(0.2)
    ]
    
    init(duration: Double = 60) {
        let viewModel = AttentionViewModel(modelContext: ModelContext(try! ModelContainer(for: GameSession.self, UserProgress.self)))
        viewModel.setGameDuration(duration)
        _viewModel = StateObject(wrappedValue: viewModel)
    }
    
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
                    .edgesIgnoringSafeArea(.all)
                    .animation(.easeInOut(duration: 2.0), value: viewModel.backgroundGradient)
                
                EyeTrackingView { isGazing in
                    viewModel.updateGazeStatus(isGazing)
                }
                .edgesIgnoringSafeArea(.all)
                
                VideoDistraction()
                    .position(videoPosition)
                    .opacity(viewModel.gameTime >= (0.6 * viewModel.totalGameDuration) ? 0 : 1)
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
            }
        }
        
        .onAppear {
            // Replace the temporary ModelContext with the actual one from the environment
            viewModel.updateModelContext(modelContext)
            viewModel.startGame()
        }
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
            ConclusionView(viewModel: viewModel)
        }
        .sheet(isPresented: $showPauseMenu) {
            PauseMenuView(viewModel: viewModel)
        }
        
        
    }
        
}

#Preview {
    ContentView()
}
