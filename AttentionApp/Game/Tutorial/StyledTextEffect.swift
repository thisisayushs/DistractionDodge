//
//  StyledTextEffect.swift
//  AttentionApp
//
//  Created by Ayush Kumar Singh on 11/02/25.
//

import SwiftUI

struct StyledTextEffect: ViewModifier {
    let isShowing: Bool
    let style: TextStyle
    
    enum TextStyle {
        case bonus
        case penalty
    }
    
    func body(content: Content) -> some View {
        content
            .opacity(isShowing ? 1 : 0)
            .scaleEffect(isShowing ? 1 : 0.8)
            .rotationEffect(.degrees(isShowing ? 0 : style == .bonus ? -10 : 10))
            .offset(y: isShowing ? 0 : style == .bonus ? 20 : -20)
            .blur(radius: isShowing ? 0 : 5)
            .animation(
                .spring(response: 0.6, dampingFraction: 0.7)
                .speed(0.8),
                value: isShowing
            )
    }
}
