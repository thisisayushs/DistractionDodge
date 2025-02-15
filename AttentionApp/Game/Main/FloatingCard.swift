//
//  FloatingCard.swift
//  AttentionApp
//
//  Created by Ayush Kumar Singh on 15/02/25.
//

import SwiftUI

struct FloatingCard: View {
    let title: String
    let value: String
    let glowCondition: Bool
    let glowColor: Color
    @State private var isGlowing = false
    
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
                        .stroke(glowCondition ? glowColor : Color.white.opacity(0.3), lineWidth: 1)
                )
                .shadow(color: glowCondition ? glowColor.opacity(isGlowing ? 0.6 : 0.0) : .black.opacity(0.2),
                        radius: glowCondition ? 8 : 10,
                        x: 0,
                        y: 5)
        )
        .onChange(of: glowCondition) { _, newValue in
            if newValue {
                withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                    isGlowing = true
                }
            } else {
                withAnimation(.easeInOut(duration: 0.3)) {
                    isGlowing = false
                }
            }
        }
    }
}
