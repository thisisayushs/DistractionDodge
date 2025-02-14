//
//  HoveringScoreModifier.swift
//  AttentionApp
//
//  Created by Ayush Kumar Singh on 11/02/25.
//

import SwiftUI

struct FloatingScoreModifier: ViewModifier {
    let isShowing: Bool
    
    func body(content: Content) -> some View {
        content
            .opacity(isShowing ? 1 : 0)
            .scaleEffect(isShowing ? 1.2 : 0.8)
            .offset(y: isShowing ? -50 : 0)
            .animation(
                .spring(response: 0.6, dampingFraction: 0.7)
                .speed(0.7),
                value: isShowing
            )
    }
}
