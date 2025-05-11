//
//  ConclusionView.swift
//  DistractionDodge
//
//  Created by Ayush Kumar Singh on 1/22/25.
//

import SwiftUI
import SwiftData

/// A view that presents the user's performance results and feedback after completing a focus training session.
///
/// `ConclusionView` is displayed when a game session ends, either by time running out or by the user
/// tapping a distraction. It provides a summary of the user's performance, including their score,
/// key statistics like focus time or catch streaks (depending on the platform), and contextual tips.
/// Users can choose to play another session or navigate back to the home screen.
///
/// ## Key Features
/// - **Animated Score Reveal:** The final score is displayed with a counting animation.
/// - **Performance Statistics:** Shows relevant stats like "Session Streak" & "Focus Time" (iOS) or "Max Streak" & "Play Time" (visionOS).
/// - **Contextual Feedback:** Offers tips based on the user's score and the platform.
/// - **Navigation Options:** Provides "Play Again" and "Go Home" buttons.
/// - **Mindful Minutes Logging:** Automatically attempts to save the session duration as mindful minutes to HealthKit.
/// - **Platform-Adaptive UI:** Adjusts its layout and presented statistics for iOS and visionOS.
///
/// ## Usage
/// This view is typically presented as a full-screen cover when ``AttentionViewModel/gameActive`` becomes `false`.
///
/// ```swift
/// .fullScreenCover(isPresented: $showConclusion) {
///     ConclusionView(viewModel: viewModel, healthKitManager: healthKitManager)
/// }
/// ```
struct ConclusionView: View {
    // MARK: - Properties
    
    /// The view model that holds the state and results of the completed game session.
    @ObservedObject var viewModel: AttentionViewModel
    /// The manager responsible for interacting with HealthKit, used here to save mindful minutes.
    @ObservedObject var healthKitManager: HealthKitManager
    
    /// An environment property used to dismiss the current view (e.g., when "Play Again" is tapped).
    @Environment(\.dismiss) var dismiss
    
    /// An AppStorage property that tracks whether the user has completed the initial app introduction.
    /// This is read but not directly modified in this view.
    @AppStorage("hasCompletedIntroduction") private var hasCompletedIntroduction = false
    
    /// The score value displayed on screen, animated from 0 to the final score.
    @State private var displayedScore = 0
    
    /// Controls the presentation of the ``Home`` view as a full-screen cover.
    @State private var showHome = false
    
    /// The scale factor for the score text, used for animation effects.
    @State private var scoreScale: CGFloat = 0.5
    
    /// A general flag to control animation states, currently used to initialize animations on appear.
    @State private var isAnimating = false
    
    /// The scale factor for the "Play Again" button, used for a repeating animation.
    @State private var buttonScale: CGFloat = 1.0
    
    /// A flag that triggers the animation for the "Play Again" button after the score reveal is complete.
    @State private var shouldAnimateButton = false
    
    /// The colors used for the background `LinearGradient`.
    private let gradientColors: [Color] = [
        .black.opacity(0.8),
        .purple.opacity(0.25)
    ]
    
    /// Provides contextual feedback to the user based on their performance and the platform.
    ///
    /// For visionOS, tips relate to hologram catching. For iOS, tips focus on gaze maintenance and streaks.
    private var focusTips: String {
        if viewModel.isVisionOSMode {
            switch viewModel.endGameReason {
            case .timeUp:
                if viewModel.score < 30 {
                    return "Good effort! Keep practicing to improve your hologram catching speed and accuracy."
                } else if viewModel.score < 70 {
                    return "Nice work! You're getting the hang of dodging distractions and catching holograms."
                } else {
                    return "Fantastic performance! You're a true Distraction Dodger on visionOS!"
                }
            default: // Covers .distractionTapped, .heartsDepleted
                return "Great job completing the session! Try to avoid those distractions or keep your hearts up next time."
            }
        } else {
            if viewModel.score < 20 {
                return "Try to maintain your gaze on the target consistently. Small improvements in focus can lead to better scores."
            } else if viewModel.score < 40 {
                return "Your focus is improving! Try to build longer streaks by staying locked on the target."
            } else {
                return "Excellent focus control! Keep challenging yourself to maintain even longer streaks."
            }
        }
    }
    
    /// Formats a `TimeInterval` (in seconds) into a "MM:SS" string.
    /// - Parameter seconds: The time interval to format.
    /// - Returns: A string representation of the time in minutes and seconds.
    private func formatTime(_ seconds: TimeInterval) -> String {
        let totalSeconds = Int(seconds)
        let minutes = totalSeconds / 60
        let secondsValue = totalSeconds % 60
        return String(format: "%02d:%02d", minutes, secondsValue)
    }
    
    /// Saves the duration of the completed game session as mindful minutes to HealthKit.
    ///
    /// The duration logged depends on the game mode:
    /// - For visionOS, it uses ``AttentionViewModel/actualPlayedDuration``.
    /// - For iOS, it uses ``AttentionViewModel/totalFocusTime``.
    ///
    /// If the determined duration is zero or less, no attempt is made to save.
    private func saveMindfulMinutes() {
        let gameSpecificDuration: TimeInterval
        if viewModel.isVisionOSMode {
            gameSpecificDuration = viewModel.actualPlayedDuration
        } else {
            gameSpecificDuration = viewModel.totalFocusTime
        }
        
        guard gameSpecificDuration > 0 else {
            print("ConclusionView: Mindful session duration is zero or negative, not attempting to save via HealthKitManager.")
            return
        }

        healthKitManager.saveMindfulMinutes(
            duration: gameSpecificDuration,
            endDate: Date(), // Assumes the session just ended.
            isVisionOSMode: viewModel.isVisionOSMode
        )
    }
    
    /// The body of the `ConclusionView`, defining its content and layout.
    var body: some View {
        ZStack {
            #if os(iOS)
            LinearGradient(
                gradient: Gradient(colors: gradientColors),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            DistractionBackground() // Decorative animated background elements.
                .blur(radius: 20)
            #endif
            
            GeometryReader { geometry in
                ScrollView {
                    VStack {
                        Spacer()
                        
                        VStack(spacing: 30) {
                            Text("Session Complete!")
                                .font(.system(self.viewModel.isVisionOSMode ? .largeTitle : .title2, design: .rounded))
                                .bold()
                                .foregroundColor(.white)
                                .padding(.top, self.viewModel.isVisionOSMode ? 40 : 20)
                            
                            // Animated score display
                            Text("\(displayedScore)")
                                .font(.system(size: 80, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                                .scaleEffect(scoreScale)
                                .animation(.interpolatingSpring(stiffness: 170, damping: 15).delay(0.1), value: scoreScale)
                                .onAppear {
                                    // Reset animation states
                                    displayedScore = 0
                                    scoreScale = 0.5
                                    isAnimating = false // TODO: Confirm if isAnimating has a distinct role here
                                    shouldAnimateButton = false
                                    
                                    // Initial score scale animation
                                    withAnimation(.spring(response: 0.6, dampingFraction: 0.7, blendDuration: 0.5)) {
                                        scoreScale = 1.0
                                    }
                                    
                                    let finalScore = self.viewModel.score
                                    
                                    // Timer to animate score counting up
                                    Timer.scheduledTimer(withTimeInterval: 0.016, repeats: true) { timer in
                                        if displayedScore < finalScore {
                                            let increment = max(1, (finalScore - displayedScore) / 20) // Faster for large scores
                                            displayedScore += increment
                                            if displayedScore > finalScore { displayedScore = finalScore }
                                            
                                            // Brief scale pulse for every 10 points
                                            if displayedScore % 10 == 0 {
                                                withAnimation(.spring(response: 0.2, dampingFraction: 0.5)) {
                                                    scoreScale = 1.1
                                                }
                                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                                    withAnimation(.spring(response: 0.2, dampingFraction: 0.5)) {
                                                        scoreScale = 1.0
                                                    }
                                                }
                                            }
                                        } else {
                                            timer.invalidate()
                                            shouldAnimateButton = true // Trigger button animation
                                        }
                                    }
                                }
                            
                            // Display contextual focus tips
                            Text(focusTips)
                                .font(.system(.body, design: .rounded))
                                .foregroundColor(.white.opacity(0.9))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                                .padding(.vertical, 15)
                                #if os(iOS)
                                .background(
                                    RoundedRectangle(cornerRadius: 15)
                                        .fill(Color.white.opacity(0.15))
                                )
                                #elseif os(visionOS)
                                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 15))
                                #endif
                            
                            // Display statistics cards
                            HStack(spacing: 20) {
                                if viewModel.isVisionOSMode {
                                    StatCard(
                                        title: "Max Streak",
                                        value: "\(self.viewModel.visionOSCatchStreak)",
                                        icon: "target" // Represents successful hologram catches.
                                    )
                                    StatCard(
                                        title: "Play Time",
                                        value: formatTime(self.viewModel.actualPlayedDuration),
                                        icon: "timer"
                                    )
                                } else {
                                    StatCard(
                                        title: "Session Streak",
                                        value: formatTime(self.viewModel.bestStreak as TimeInterval),
                                        icon: "bolt.fill" // Represents focus streak.
                                    )
                                    StatCard(
                                        title: "Focus Time",
                                        value: formatTime(self.viewModel.totalFocusTime as TimeInterval),
                                        icon: "eye.fill" // Represents time spent gazing at the target.
                                    )
                                }
                            }
                            .padding(.bottom, 40)
                            
                            // Action buttons
                            VStack(spacing: 20) {
                                Button {
                                    self.viewModel.startGame(isVisionOSGame: self.viewModel.isVisionOSMode)
                                    dismiss() // Dismiss ConclusionView to go back to the game.
                                } label: {
                                    HStack {
                                        Text("Play Again")
                                            .font(.system(size: 22, weight: .bold, design: .rounded))
                                    }
                                    .foregroundColor(.white)
                                    .padding(.vertical, 16)
                                    .padding(.horizontal, 35)
                                    #if os(iOS)
                                    .background(
                                        Capsule()
                                            .fill(Color.white.opacity(0.2))
                                            .overlay(
                                                Capsule()
                                                    .stroke(Color.white, lineWidth: 1.5)
                                            )
                                            .shadow(color: .white.opacity(0.3), radius: 5, x: 0, y: 2)
                                    )
                                    #endif
                                }
                                #if os(visionOS)
                                .buttonStyle(.borderedProminent) // Platform-specific button style.
                                #endif
                                .scaleEffect(buttonScale)
                                .onChange(of: shouldAnimateButton) { _, newValue in
                                    // Start repeating scale animation for the button when ready.
                                    if newValue {
                                        withAnimation(
                                            .easeInOut(duration: 0.5)
                                            .repeatForever(autoreverses: true)
                                        ) {
                                            buttonScale = 1.1
                                        }
                                    }
                                }
                                
                                Button {
                                    showHome = true // Trigger presentation of the Home view.
                                } label: {
                                    HStack {
                                        Text("Go Home")
                                            .font(.system(size: 22, weight: .bold, design: .rounded))
                                    }
                                    .foregroundColor(.white.opacity(0.8))
                                    .padding(.vertical, 16)
                                    .padding(.horizontal, 35)
                                    #if os(iOS)
                                    .background(
                                        Capsule()
                                            .fill(Color.white.opacity(0.15))
                                            .overlay(
                                                Capsule()
                                                    .stroke(Color.white.opacity(0.3), lineWidth: 1.5)
                                            )
                                            .shadow(color: .white.opacity(0.2), radius: 5, x: 0, y: 2)
                                    )
                                    #endif
                                }
                                #if os(visionOS)
                                .buttonStyle(.bordered) // Platform-specific button style.
                                #endif
                            }
                        }
                        .padding(self.viewModel.isVisionOSMode ? 40 : 30)
                        .frame(maxWidth: .infinity)
                        
                        Spacer()
                    }
                    .frame(minHeight: geometry.size.height) // Ensure scroll content fills height.
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .preferredColorScheme(.dark)
        #if os(iOS)
        .statusBarHidden(true)
        .persistentSystemOverlays(.hidden) // Hide system bars for immersive experience on iOS.
        #endif
        .onAppear {
            saveMindfulMinutes() // Attempt to save mindful minutes when the view appears.
        }
        .fullScreenCover(isPresented: $showHome) {
            Home() // Present Home view.
        }
    }
}

