//
//  TextAnimator.swift
//  DistractionDodge
//
//  Created by Ayush Kumar Singh on 1/22/25.
//

import SwiftUI
import AVFoundation

/// A view that creates a typewriter-like text animation effect with sound feedback.
///
/// This component animates text by displaying it character by character, creating
/// a typing machine effect. It includes keyboard sound effects and manages the timing
/// of text display through a configurable interval.
struct TextAnimator: View {
    /// The text content to be animated
    let text: String
    /// The sequential position of this animator in a series of animations
    let index: Int
    /// Binding to track which text block should currently be animating
    @Binding var activeIndex: Int
    /// Binding to control whether the animation should stop
    @Binding var shouldStopAnimation: Bool
    /// The text that is currently being displayed during animation
    @State private var displayedText = ""
    /// Timer that controls the typing animation
    @State private var timer: Timer? = nil
    /// Callback executed when the typing animation completes
    var onFinished: () -> Void
    /// The time interval between displaying each character
    private let typingInterval: TimeInterval = 0.05
    /// The delay before playing the typing sound effect
    private let soundDelay: TimeInterval = 0.02
    
    var body: some View {
        HStack {
            Text(displayedText)
                .font(.system(size: 20, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.9))
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
            Spacer()
        }
        .padding(.horizontal)
        .onAppear {
            if index == activeIndex {
                startTyping()
            }
        }
        .onChange(of: activeIndex) { _, newValue in
            if index == newValue {
                startTyping()
            }
        }
        .onChange(of: shouldStopAnimation) { _, shouldStop in
            if shouldStop {
                timer?.invalidate()
                timer = nil
            }
        }
        .onDisappear {
            timer?.invalidate()
            timer = nil
        }
    }
    
    /// Initiates the typing animation sequence
    ///
    /// This method handles the character-by-character display of text,
    /// playing sound effects for each character except punctuation and spaces.
    /// When animation completes, it triggers the onFinished callback.
    private func startTyping() {
        displayedText = ""
        timer?.invalidate()
        
        var charIndex = 0
        timer = Timer.scheduledTimer(withTimeInterval: typingInterval, repeats: true) { timer in
            guard !self.shouldStopAnimation else {
                timer.invalidate()
                return
            }
            
            guard charIndex < self.text.count else {
                timer.invalidate()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self.onFinished()
                }
                return
            }
            
            let textIndex = self.text.index(self.text.startIndex, offsetBy: charIndex)
            let currentChar = String(self.text[textIndex])
            
            displayedText = String(self.text[...textIndex])
            charIndex += 1
            if !["", " ", ".", ",", "!", "?"].contains(currentChar) {
                DispatchQueue.main.asyncAfter(deadline: .now() + self.soundDelay) {
                    AudioServicesPlaySystemSound(1104)
                }
            }
        }
    }
}
