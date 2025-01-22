//
//  ContentView.swift
//  AttentionApp
//
//  Created by Ayush Kumar Singh on 28/12/24.
//

import SwiftUI
import AVFoundation



struct ContentView: View {
    @StateObject private var viewModel = AttentionViewModel()
    @State private var showGameSummary = false
    @State private var videoPosition = CGPoint(x: UIScreen.main.bounds.width * 0.6,
                                              y: UIScreen.main.bounds.height * 0.6)
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                LinearGradient(gradient: Gradient(colors: viewModel.backgroundGradient),
                               startPoint: .topLeading,
                               endPoint: .bottomTrailing)
                    .edgesIgnoringSafeArea(.all)
                    .animation(.easeInOut(duration: 2.0), value: viewModel.backgroundGradient)
                
                EyeTrackingView { isGazing in
                    viewModel.updateGazeStatus(isGazing)
                }
                .edgesIgnoringSafeArea(.all)
                
                VideoDistraction()
                    .position(videoPosition)
                    .opacity(viewModel.gameTime >= 45 ? 0 : 1) 
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
                        FloatingCard(title: "Time", value: "\(Int(viewModel.gameTime))s")
                            .opacity(viewModel.gameTime <= 10 ? 0.8 + 0.2 * sin(Double.pi * 2 * Double(viewModel.gameTime)) : 1.0)
                        
                        FloatingCard(title: "Score", value: "\(viewModel.score)")
                        
                        FloatingCard(title: "Streak", value: "\(Int(viewModel.focusStreak))s")
                    }
                    .padding(.top, 40)
                    
                    Spacer()
                }
            }
        }
        .onAppear {
            viewModel.startGame()
        }
        .onDisappear {
            viewModel.stopGame()
        }
        .onChange(of: viewModel.gameActive) { wasActive, isActive in
            if !isActive && wasActive {
                showGameSummary = true
            }
        }
        .sheet(isPresented: $showGameSummary) {
            GameSummaryView(viewModel: viewModel, isPresented: $showGameSummary)
        }
    }
}

struct FloatingCard: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack(spacing: 10) {
            Text(title)
                .font(.system(.headline, design: .rounded))
            Text(value)
                .font(.system(.title3, design: .rounded))
                .bold()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.15))
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
        )
    }
}

struct GameSummaryView: View {
    @ObservedObject var viewModel: AttentionViewModel
    @Binding var isPresented: Bool
    
    var body: some View {
        VStack(spacing: 30) {
            Text(viewModel.endGameReason == .timeUp ? "Time's Up!" : "Game Over!")
                .font(.system(.title, design: .rounded))
                .bold()
                .foregroundColor(viewModel.endGameReason == .timeUp ? .blue : .red)
            
            if viewModel.endGameReason == .distractionTap {
                Text("You got distracted!")
                    .font(.system(.headline, design: .rounded))
                    .foregroundColor(.red)
                    .padding(.bottom)
            }
            
            HStack {
                ForEach(0..<3) { index in
                    Image(systemName: "star.fill")
                        .font(.system(size: 40))
                        .foregroundColor(index < viewModel.calculateStars() ? .yellow : .gray)
                        .shadow(color: .black.opacity(0.2), radius: 5)
                        .scaleEffect(index < viewModel.calculateStars() ? 1.2 : 1.0)
                        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: viewModel.calculateStars())
                }
            }
            .padding(.vertical)
            
            VStack(spacing: 15) {
                Text("Final Score: \(viewModel.score)")
                    .font(.title2)
                Text("Longest Focus Streak: \(Int(viewModel.focusStreak))s")
                Text("Distractions Ignored: \(viewModel.distractionsIgnored)")
            }
            .font(.system(.body, design: .rounded))
            
            Button("Try Again") {
                isPresented = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    viewModel.startGame()
                }
            }
            .font(.headline)
            .foregroundColor(.white)
            .padding(.horizontal, 40)
            .padding(.vertical, 15)
            .background(viewModel.endGameReason == .timeUp ? Color.blue : Color.red)
            .cornerRadius(25)
            .shadow(radius: 5)
        }
        .padding(40)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
