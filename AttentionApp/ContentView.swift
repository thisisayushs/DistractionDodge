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
    @State private var showConclusion = false
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
                if viewModel.endGameReason == .timeUp {
                    showConclusion = true
                } else {
                    showGameSummary = true
                }
            }
        }
        .sheet(isPresented: $showGameSummary) {
            GameSummaryView(viewModel: viewModel, isPresented: $showGameSummary)
        }
        .fullScreenCover(isPresented: $showConclusion) {
            ConclusionView(viewModel: viewModel)
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
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [.red.opacity(0.8), .orange.opacity(0.2)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 35) {
                VStack(spacing: 25) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 60))
                        .foregroundStyle(
                            .linearGradient(
                                colors: [.yellow, .orange],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .padding(.bottom)
                    
                    VStack(spacing: 15) {
                        Text("Attention Lost!")
                            .font(.system(.title, design: .rounded))
                            .bold()
                            .foregroundColor(.white)
                        
                        Text("You got distracted")
                            .font(.system(.body, design: .rounded))
                            .foregroundColor(.white.opacity(0.9))
                            .multilineTextAlignment(.center)
                    }
                    .padding(.vertical, 25)
                    .padding(.horizontal, 30)
                    .background(
                        RoundedRectangle(cornerRadius: 25)
                            .fill(.white.opacity(0.15))
                            .background(
                                RoundedRectangle(cornerRadius: 25)
                                    .stroke(.white.opacity(0.3), lineWidth: 1)
                            )
                            .shadow(color: .black.opacity(0.2), radius: 15)
                    )
                }
                
                Button {
                    isPresented = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        viewModel.startGame()
                    }
                } label: {
                    Text("Try Again")
                        .font(.system(.headline, design: .rounded))
                        .foregroundColor(.white)
                        .padding(.horizontal, 40)
                        .padding(.vertical, 15)
                        .background(
                            Capsule()
                                .fill(
                                    LinearGradient(
                                        colors: [.orange, .red],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                        )
                        .shadow(color: .black.opacity(0.2), radius: 10)
                }
                .padding(.top, 20)
            }
            .padding(40)
        }
        .presentationBackground(.clear)
        .presentationCornerRadius(35)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
