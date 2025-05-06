//
//  OnboardingContentView.swift
//  DistractionDodge
//
//  Created by Ayush Kumar Singh on 10/02/25.
//

import SwiftUI

/// A view that presents the content for each onboarding page with animated text and emoji.
///
/// This view manages the presentation of onboarding content including:
/// - An animated emoji header
/// - A title
/// - Sequentially animated text lines
/// - Progress tracking for completed content
struct OnboardingContentView: View {
    /// The page data containing emoji, title, and content to display
    let page: Page
    
    /// The current page index in the onboarding sequence
    let currentIndex: Int
    
    /// The index of the text line currently being animated
    @Binding var activeLineIndex: Int
    
    /// Set of indices for completed text lines
    @Binding var completedLines: Set<Int>
    
    /// Indicates whether all text lines have been displayed
    @Binding var allLinesComplete: Bool
    
    /// The scale factor for the emoji animation
    @Binding var emojiScale: CGFloat
    
    /// The rotation angle for the emoji animation
    @Binding var emojiRotation: CGFloat
    
    /// Indicates whether text animation should stop
    @Binding var shouldStopTextAnimation: Bool
    
    var body: some View {
        VStack(spacing: 30) {
            
            // CHANGE: Wrap emoji in ZStack and add shadow for visionOS
            #if os(visionOS)
            ZStack { // Use ZStack for layering effects
                Text(page.emoji)
                    // CHANGE: Increase font size for visionOS
                    .font(.system(size: 95)) // Increased from 80
                    .shadow(color: .black.opacity(0.2), radius: 5, x: 2, y: 2) // Keep the lighter shadow
                    .scaleEffect(emojiScale)
            }
            .onAppear {
                withAnimation(
                    .spring(response: 0.8, dampingFraction: 0.7)
                    .repeatForever(autoreverses: true)
                ) {
                    emojiScale = 1.1
                }
            }
            .onDisappear {
                withAnimation(.easeInOut) {
                    emojiScale = 1
                    // emojiRotation reset removed as it's not used in visionOS block
                }
            }
            .padding(.bottom, 30)
            #else // Keep original iOS settings
            Text(page.emoji)
                .font(.system(size: 100))
                .scaleEffect(emojiScale)
                .rotationEffect(.degrees(emojiRotation))
                .onAppear {
                    withAnimation(
                        .spring(response: 0.6, dampingFraction: 0.6)
                        .repeatForever(autoreverses: true)
                    ) {
                        emojiScale = 1.2
                    }

                    withAnimation(
                        .easeInOut(duration: 2)
                        .repeatForever(autoreverses: true)
                    ) {
                        emojiRotation = 10
                    }
                }
                .onDisappear {
                    withAnimation(.easeInOut) {
                        emojiScale = 1
                        emojiRotation = 0
                    }
                }
                .padding(.bottom, 30)
            #endif
        }
        
        Text(page.title)
            #if os(visionOS)
            .font(.system(size: 48, weight: .bold, design: .rounded))
            #else
            .font(.system(size: 42, weight: .bold, design: .rounded))
            #endif
            .foregroundColor(.white)
            .multilineTextAlignment(.center)
            .padding(.horizontal)
            .transition(.scale.combined(with: .opacity))
            .id("title\(currentIndex)")
        
        VStack(alignment: .leading, spacing: 25) {
            ForEach(page.content.indices, id: \.self) { index in
                TextAnimator(
                    text: page.content[index],
                    index: index,
                    activeIndex: $activeLineIndex,
                    shouldStopAnimation: $shouldStopTextAnimation
                ) {
                    withAnimation {
                        completedLines.insert(index)
                        if index < page.content.count - 1 {
                            activeLineIndex += 1
                        } else {
                            allLinesComplete = true
                        }
                    }
                }
                .transition(.asymmetric(
                    insertion: .move(edge: .leading).combined(with: .opacity),
                    removal: .move(edge: .trailing).combined(with: .opacity)
                ))
                .id("content\(currentIndex)\(index)")
            }
        }
        .padding(.top, 20)
        .padding(.horizontal)
    }
    
}


/// A view that provides a styled back button for navigation.
///
/// This button includes an icon and text with a custom background,
/// and supports disabled state during navigation.
struct BackButtonView: View {
    /// Indicates if navigation is currently in progress
    let isNavigating: Bool
    
    /// The action to perform when the back button is tapped
    let action: () -> Void
    
    var body: some View {
        HStack {
            Button(action: action) {
                HStack {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 20, weight: .bold))
                    Text("Back")
                        .font(.system(size: 18, weight: .bold))
                }
                .foregroundColor(.white)
                .padding(.vertical, 8)
                .padding(.horizontal, 16)
                .background(
                    Capsule()
                        .fill(Color.white.opacity(0.2))
                        .overlay(Capsule().stroke(Color.white, lineWidth: 1))
                )
            }
            .padding(.leading, 20)
            .disabled(isNavigating)
            Spacer()
        }
        .padding(.top, 20)
    }
}
