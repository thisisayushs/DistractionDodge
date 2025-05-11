//
//  PauseMenuView.swift
//  DistractionDodge
//
//  Created by Ayush Kumar Singh on 1/22/25.
//

import SwiftUI

/// A view that displays the pause menu during gameplay.
///
/// PauseMenuView provides options to:
/// - Resume the current game
/// - Restart the game
/// - Return to introduction
///
/// Usage:
/// ```swift
/// PauseMenuView(viewModel: attentionViewModel)
/// ```
struct PauseMenuView: View {
    // MARK: - Properties
    
    /// View model containing game state and control methods
    @ObservedObject var viewModel: AttentionViewModel
    
    /// Environment dismiss action
    @Environment(\.dismiss) private var dismiss
    
    /// Controls navigation to introduction screen
    @State private var showHome = false
    
    // MARK: - Body
    
    var body: some View {
        ZStack {
            
            #if os(iOS)
            LinearGradient(
                gradient: Gradient(colors: [.black.opacity(0.8), .purple.opacity(0.2)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            #endif
            
            VStack(spacing: 35) {
                Text("Game Paused")
                    .font(.system(.title, design: .rounded))
                    .bold()
                    .foregroundColor(.white)
                
                VStack(spacing: 20) {
                    Button {
                        dismiss()
                        viewModel.resumeGame()
                    } label: {
                        MenuButton(title: "Resume", icon: "play.fill")
                    }
                    
                    Button {
                        dismiss()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            viewModel.startGame(isVisionOSGame: viewModel.isVisionOSMode)
                        }
                    } label: {
                        MenuButton(title: "Restart", icon: "arrow.clockwise")
                    }
                    
                    Button {
                        showHome = true
                    } label: {
                        MenuButton(title: "Go Home", icon: "arrow.left")
                    }
                }
            }
            .padding(40)
            #if os(visionOS)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 35)) // Use corner radius from presentation
            .frame(minWidth: 300, idealWidth: 400, maxWidth: 500) // Adjust width as needed
            #endif
        }
        .presentationBackground(.clear)
        .presentationCornerRadius(35)
        .interactiveDismissDisabled()
        .fullScreenCover(isPresented: $showHome) {
            Home()
        }
    }
}

/// A styled button view used in the pause menu.
///
/// MenuButton provides a consistent style for pause menu options with:
/// - Icon and text combination
/// - Translucent background
/// - Border and shadow effects
struct MenuButton: View {
    // MARK: - Properties
    
    /// Title text for the button
    let title: String
    
    /// SF Symbol name for the button icon
    let icon: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.title2)
            Text(title)
                .font(.system(.title3, design: .rounded))
                .bold()
        }
        .foregroundColor(.white) // This should be fine with .ultraThinMaterial
        .frame(maxWidth: .infinity)
        .padding(.vertical, 15)
        #if os(iOS)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.15))
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.2), radius: 10)
        )
        #endif
    }
}
