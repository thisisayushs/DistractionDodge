//
//  GameObstructionView.swift
//  DistractionDodge
//
//  Created by Ayush Kumar Singh on 2/15/25.
//

import SwiftUI

/// A view that appears when the player loses focus by interacting with a distraction.
///
/// This view provides feedback about the game ending due to distraction and offers
/// the option to restart the game. It features:
/// - Visual warning with animated icon
/// - Explanation of why the game ended
/// - Option to restart the game
///
/// Usage:
/// ```swift
/// GameObstructionView(
///     viewModel: attentionViewModel,
///     isPresented: $showGameOver
/// )
/// ```
struct GameObstructionView: View {
    @ObservedObject var viewModel: AttentionViewModel
    @Binding var isPresented: Bool
    
    private var titleText: String {
        switch viewModel.endGameReason {
        case .distractionTap:
            return "Attention Lost!"
        case .heartsDepleted:
            return "Out of Hearts!"
        case .timeUp: // Should ideally be handled by ConclusionView, but good to have a fallback
            return "Time's Up!"
        }
    }
    
    private var messageText: String {
        switch viewModel.endGameReason {
        case .distractionTap:
            return "You got distracted and tapped on a distraction object."
        case .heartsDepleted:
            return "You got distracted and missed too many holograms."
        case .timeUp:
            return "The game session has ended as time ran out."
        }
    }
    
    private var iconName: String {
        switch viewModel.endGameReason {
        case .distractionTap:
            return "exclamationmark.triangle.fill"
        case .heartsDepleted:
            return "heart.slash.fill" // More appropriate icon for hearts depleted
        case .timeUp:
            return "timer.square"
        }
    }
    
    private var iconColors: [Color] {
        switch viewModel.endGameReason {
        case .distractionTap:
            return [.yellow, .orange]
        case .heartsDepleted:
            return [.pink, .red] // Colors for hearts depleted
        case .timeUp:
            return [.gray, .blue]
        }
    }
    
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
                    Image(systemName: iconName)
                        .font(.system(size: 60))
                        .foregroundStyle(
                            .linearGradient(
                                colors: iconColors,
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .padding(.bottom)
                    
                    VStack(spacing: 15) {
                        Text(titleText)
                            .font(.system(.title, design: .rounded))
                            .bold()
                            .foregroundColor(.white)
                        
                        Text(messageText)
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
                        // Assuming GameObstructionView is primarily for visionOS game over by hearts or iOS distraction tap.
                        // If it's visionOS:
                        if viewModel.endGameReason == .heartsDepleted || viewModel.endGameReason == .timeUp && viewModel.isVisionOSMode {
                             viewModel.startGame(isVisionOSGame: true)
                        } else { // iOS distraction tap or iOS time up (though time up usually goes to ConclusionView)
                             viewModel.startGame(isVisionOSGame: false)
                        }
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
                #if os(visionOS)
                .buttonStyle(.plain)
                #endif
                .padding(.top, 20)
            }
            .padding(40)
        }
        .presentationBackground(.clear)
        .presentationCornerRadius(35)
        
    }
}
