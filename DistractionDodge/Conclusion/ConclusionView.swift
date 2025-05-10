//
//  ConclusionView.swift
//  DistractionDodge
//
//  Created by Ayush Kumar Singh on 22/01/25.
//

import SwiftUI
import SwiftData
#if canImport(HealthKit) // Ensure HealthKit is only imported if available
import HealthKit
#endif

/// A view that presents the user's performance results and feedback after completing a focus training session.
///
/// ConclusionView provides:
/// - Animated score reveal
/// - Performance statistics display
/// - Contextual tips based on performance
/// - Options to retry or restart training
struct ConclusionView: View {
    // MARK: - Properties
    
    /// View model containing game results and statistics
    @ObservedObject var viewModel: AttentionViewModel
    
    /// Environment dismiss action
    @Environment(\.dismiss) var dismiss
    
    #if canImport(HealthKit)
    /// Environment health store
    @Environment(\.healthStore) private var healthStore
    #endif
    
    /// Tracks completion of introduction for navigation
    @AppStorage("hasCompletedIntroduction") private var hasCompletedIntroduction = false
    
    /// Animated score counter
    @State private var displayedScore = 0
    
    /// Controls navigation back to introduction
    @State private var showHome = false
    
    /// Scale factor for score animation
    @State private var scoreScale: CGFloat = 0.5
    
    /// Controls animation states
    @State private var isAnimating = false
    
    /// Scale factor for button animations
    @State private var buttonScale: CGFloat = 1.0
    
    /// Triggers button animation after score reveal
    @State private var shouldAnimateButton = false
    
    /// Background gradient colors
    private let gradientColors: [Color] = [
        .black.opacity(0.8),
        .purple.opacity(0.25)
    ]
    
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
            default:
                return "Great job completing the session!"
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
    
    private func formatTime(_ seconds: TimeInterval) -> String {
        let totalSeconds = Int(seconds)
        let minutes = totalSeconds / 60
        let secondsValue = totalSeconds % 60
        return String(format: "%02d:%02d", minutes, secondsValue)
    }
    
    // The internal logic determines the correct duration and handles HealthKit availability.
    private func saveMindfulMinutes() {
        #if canImport(HealthKit)
        guard HKHealthStore.isHealthDataAvailable() else {
            print("HealthKit: Data is not available on this device.")
            return
        }
        
        let mindfulType = HKObjectType.categoryType(forIdentifier: .mindfulSession)!
        
        // Explicitly capture viewModel
        healthStore.requestAuthorization(toShare: [mindfulType], read: nil) { [viewModel] (success, error) in
            if !success {
                print("HealthKit: Authorization failed or was denied. Error: \(String(describing: error?.localizedDescription))")
                return
            }
            
            // Use the captured `viewModel` instance
            if self.healthStore.authorizationStatus(for: mindfulType) == .sharingAuthorized {
                let endDate = Date()
                
                let gameSpecificDuration: TimeInterval
                if viewModel.isVisionOSMode {
                    gameSpecificDuration = viewModel.actualPlayedDuration
                } else {
                    gameSpecificDuration = viewModel.totalFocusTime
                }
                
                guard gameSpecificDuration > 0 else {
                    print("HealthKit: Mindful session duration is zero or negative, not saving.")
                    return
                }

                let startDate = endDate.addingTimeInterval(-gameSpecificDuration)
                
                let sample = HKCategorySample(
                    type: mindfulType,
                    value: HKCategoryValue.notApplicable.rawValue, // Standard for mindful sessions
                    start: startDate,
                    end: endDate
                )
                
                self.healthStore.save(sample) { (success, error) in // Use self.healthStore
                    if let error = error {
                        print("HealthKit: Error saving mindful minutes: \(error.localizedDescription)")
                    } else if success {
                        // Access viewModel properties from the captured viewModel
                        let platform = viewModel.isVisionOSMode ? "visionOS" : "iOS"
                        print("HealthKit: Mindful minutes saved successfully for \(gameSpecificDuration) seconds on \(platform).")
                    }
                }
            } else {
                print("HealthKit: Authorization not granted after request attempt.")
            }
        }
        #else
        print("HealthKit: Framework not available on this build target.")
        #endif
    }
    
    var body: some View {
        ZStack {
            #if os(iOS)
            LinearGradient(
                gradient: Gradient(colors: gradientColors),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            DistractionBackground()
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
                            
                            Text("\(displayedScore)")
                                .font(.system(size: 80, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                                .scaleEffect(scoreScale)
                                .animation(.interpolatingSpring(stiffness: 170, damping: 15).delay(0.1), value: scoreScale)
                                .onAppear {
                                    displayedScore = 0
                                    scoreScale = 0.5
                                    isAnimating = false
                                    shouldAnimateButton = false
                                    
                                    withAnimation(.spring(response: 0.6, dampingFraction: 0.7, blendDuration: 0.5)) {
                                        scoreScale = 1.0
                                    }
                                    
                                    let finalScore = self.viewModel.score
                                    
                                    Timer.scheduledTimer(withTimeInterval: 0.016, repeats: true) { timer in
                                        if displayedScore < finalScore {
                                            let increment = max(1, (finalScore - displayedScore) / 20) // Faster for large scores
                                            displayedScore += increment
                                            if displayedScore > finalScore { displayedScore = finalScore }
                                            
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
                                            shouldAnimateButton = true
                                        }
                                    }
                                }
                            
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
                            
                            HStack(spacing: 20) {
                                if viewModel.isVisionOSMode {
                                    StatCard(
                                        title: "Max Streak", 
                                        value: "\(self.viewModel.visionOSCatchStreak)", // Use self.viewModel for clarity
                                        icon: "target"
                                    )
                                    StatCard(
                                        title: "Play Time", 
                                        value: formatTime(self.viewModel.actualPlayedDuration),
                                        icon: "timer"
                                    )
                                } else { 
                                    StatCard(
                                        title: "Session Streak",
                                        value: formatTime(self.viewModel.bestStreak as TimeInterval), // Use self.viewModel
                                        icon: "bolt.fill"
                                    )
                                    StatCard(
                                        title: "Focus Time",
                                        value: formatTime(self.viewModel.totalFocusTime as TimeInterval), // Use self.viewModel
                                        icon: "eye.fill" 
                                    )
                                }
                            }
                            .padding(.bottom, 40)
                            
                            VStack(spacing: 20) {
                                Button {
                                    self.viewModel.startGame(isVisionOSGame: self.viewModel.isVisionOSMode)
                                    dismiss()
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
                                .buttonStyle(.borderedProminent)
                                
                                #endif
                                .scaleEffect(buttonScale)
                                .onChange(of: shouldAnimateButton) { _, newValue in
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
                                    showHome = true
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
                                .buttonStyle(.bordered)
                                #endif
                            }
                        }
                        .padding(self.viewModel.isVisionOSMode ? 40 : 30)
                        .frame(maxWidth: .infinity)
                        
                        Spacer()
                    }
                    .frame(minHeight: geometry.size.height)
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .preferredColorScheme(.dark)
        #if os(iOS)
        .statusBarHidden(true)
        .persistentSystemOverlays(.hidden)
        #endif
        .onAppear {
            // The function itself handles HealthKit availability and platform-specific duration.
            saveMindfulMinutes()
        }
        .fullScreenCover(isPresented: $showHome) {
            Home()
        }
    }
}

