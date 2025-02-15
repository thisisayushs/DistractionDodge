//
//  Content.swift
//  AttentionApp
//
//  Created by Ayush Kumar Singh on 10/02/25.
//

import SwiftUI

struct OnboardingContentView: View {
    
    let page: Page
    
    @Binding var activeLineIndex: Int
    @Binding var completedLines: Set<Int>
    @Binding var allLinesComplete: Bool
    @Binding var emojiScale: CGFloat
    @Binding var emojiRotation: CGFloat
    
    let currentIndex: Int
    
    var body: some View {
        VStack(spacing: 30) {
            
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
        }
        
        
        Text(page.title)
            .font(.system(size: 42, weight: .bold, design: .rounded))
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
                    activeIndex: $activeLineIndex
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


struct BackButtonView: View {
    let isNavigating: Bool
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
