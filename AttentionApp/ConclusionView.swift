//
//  ConclusionView.swift
//  AttentionApp
//
//  Created by Ayush Kumar Singh on 22/01/25.
//

import SwiftUI

struct ConclusionView: View {
    @ObservedObject var viewModel: AttentionViewModel
    @Environment(\.dismiss) var dismiss
    @AppStorage("hasCompletedIntroduction") private var hasCompletedIntroduction = false
    @State private var score = 0
    @State private var showRestartIntroduction = false
    @State private var scoreScale: CGFloat = 0.5
    
    // Gradient colors remain the same
    private let gradientColors: [Color] = [.black.opacity(0.8), .blue.opacity(0.25)]
    
    // Updated focus improvement tips based on score
    private var focusTips: String {
        if viewModel.score < 20 {
            return "Tip: Try to maintain your gaze on the target consistently. Small improvements in focus can lead to better scores."
        } else if viewModel.score < 40 {
            return "Tip: Your focus is improving! Try to build longer streaks by staying locked on the target."
        } else {
            return "Excellent focus control! Keep challenging yourself to maintain even longer streaks."
        }
    }
    
    var body: some View {
        ZStack {
            // Background elements remain the same
            LinearGradient(
                gradient: Gradient(colors: gradientColors),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            // Add floating animation background from IntroductionView
            DistractionBackground()
                .blur(radius: 20)
            
            VStack(spacing: 45) {
                // Top section with score
                VStack(spacing: 30) {
                    Text("⭐ Focus Score ⭐")
                        .font(.system(.title2, design: .rounded))
                        .bold()
                        .foregroundColor(.white)
                        .padding(.top, 20)
                    
                    Text("\(score)")
                        .font(.system(size: 80, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .scaleEffect(scoreScale)
                        .onAppear {
                            score = 0 
                            scoreScale = 0.5 
                            
                            // Animate scale with bounce
                            withAnimation(.spring(
                                response: 0.5,
                                dampingFraction: 0.6,
                                blendDuration: 0
                            )) {
                                scoreScale = 1.0 
                            }
                            
                            // Animate score counting up
                            withAnimation(.easeOut(duration: 1.0)) {
                                score = viewModel.score
                            }
                        }
                    
                    Text(focusTips)
                        .font(.system(.body, design: .rounded))
                        .foregroundColor(.white.opacity(0.9))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                        .padding(.vertical, 15)
                        .background(
                            RoundedRectangle(cornerRadius: 15)
                                .fill(Color.white.opacity(0.15))
                        )
                    
                    // Updated to use bestStreak instead of focusStreak
                    HStack(spacing: 20) {
                        StatCard(title: "Total Focus",
                                value: "\(Int(viewModel.totalFocusTime))s",
                                icon: "clock.fill")
                        
                        StatCard(title: "Best Streak",
                                value: "\(Int(viewModel.bestStreak))s",
                                icon: "bolt.fill")
                    }
                }
                
                Spacer()
                
                // Action buttons with consistent app styling
                VStack(spacing: 20) {
                    Button {
                        viewModel.startGame()
                        dismiss()
                    } label: {
                        HStack {
                            Text("Try Again")
                                .font(.system(size: 22, weight: .bold, design: .rounded))
                        }
                        .foregroundColor(.white)
                        .padding(.vertical, 16)
                        .padding(.horizontal, 35)
                        .background(
                            Capsule()
                                .fill(Color.white.opacity(0.2))
                                .overlay(
                                    Capsule()
                                        .stroke(Color.white, lineWidth: 1.5)
                                )
                                .shadow(color: .white.opacity(0.3), radius: 5, x: 0, y: 2)
                        )
                    }
                    
                    Button {
                        hasCompletedIntroduction = false
                        showRestartIntroduction = true
                    } label: {
                        HStack {
                            Text("Start Over")
                                .font(.system(size: 22, weight: .bold, design: .rounded))
                        }
                        .foregroundColor(.white.opacity(0.8))
                        .padding(.vertical, 16)
                        .padding(.horizontal, 35)
                        .background(
                            Capsule()
                                .fill(Color.white.opacity(0.15))
                                .overlay(
                                    Capsule()
                                        .stroke(Color.white.opacity(0.3), lineWidth: 1.5)
                                )
                                .shadow(color: .white.opacity(0.2), radius: 5, x: 0, y: 2)
                        )
                    }
                }
                .padding(.bottom, 40)
            }
            .padding(30)
        }
        .fullScreenCover(isPresented: $showRestartIntroduction) {
            IntroductionView()
        }
    }
}

// Updated stat card to match app design
struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 24, weight: .semibold))
                .foregroundColor(.white)
            
            Text(value)
                .font(.system(.title2, design: .rounded))
                .bold()
                .foregroundColor(.white)
            
            Text(title)
                .font(.system(.subheadline, design: .rounded))
                .foregroundColor(.white.opacity(0.8))
        }
        .frame(width: 150)
        .padding(.vertical, 20)
        .background(
            RoundedRectangle(cornerRadius: 25)
                .fill(Color.white.opacity(0.15))
                .overlay(
                    RoundedRectangle(cornerRadius: 25)
                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.2), radius: 10)
        )
    }
}
