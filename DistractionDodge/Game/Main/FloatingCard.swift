//
//  FloatingCard.swift
//  DistractionDodge
//
//  Created by Ayush Kumar Singh on 2/15/25.
//

import SwiftUI

/// A view component that displays game statistics in a stylized, floating card format.
///
/// FloatingCard provides a consistent way to display game metrics with optional
/// glow effects for highlighting significant achievements or states during gameplay.
///
/// Usage:
/// ```swift
/// FloatingCard(
///     title: "Score",
///     value: "100",
///     glowCondition: score >= 100,
///     glowColor: .yellow
/// )
/// ```
struct FloatingCard: View {
    // MARK: - Properties
    
    /// The title text displayed in the card
    let title: String
    
    /// The value text displayed in the card
    let value: String
    
    /// Determines if the card should show a glow effect
    let glowCondition: Bool
    
    /// The color of the glow effect when active
    let glowColor: Color
    
    /// Controls the animation state of the glow effect
    @State private var isGlowing = false
    
    // MARK: - Body
    
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
                        .stroke(glowCondition ? glowColor : Color.white.opacity(0.3), lineWidth: glowCondition ? 2.5 : 1)
                )
                .shadow(color: glowCondition ? glowColor.opacity(isGlowing ? 0.8 : 0.2) : .black.opacity(0.2),
                        radius: glowCondition ? (isGlowing ? 12 : 8) : 10,
                        x: 0,
                        y: 5)
        )
        .scaleEffect(glowCondition && isGlowing ? 1.03 : 1.0)
        .onChange(of: glowCondition) { _, newValue in
            if newValue {
                if !isGlowing {
                    withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                        isGlowing = true
                    }
                } else {
                    isGlowing = true
                }
            } else {
                withAnimation(.easeInOut(duration: 0.3)) {
                    isGlowing = false
                }
            }
        }
        .onAppear {
            if glowCondition {
                if !isGlowing {
                    withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                        isGlowing = true
                    }
                }
            } else {
                isGlowing = false
            }
        }
    }
}
