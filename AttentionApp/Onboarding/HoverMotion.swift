//
//  HoverMotion.swift
//  AttentionApp
//
//  Created by Ayush Kumar Singh on 11/02/25.
//

import SwiftUI

struct HoverMotion: ViewModifier {
    let isAnimating: Bool
    
    func body(content: Content) -> some View {
        content
            .offset(y: isAnimating ? CGFloat.random(in: -20...20) : 0)
            .animation(
                Animation.easeInOut(duration: Double.random(in: 2...4))
                    .repeatForever(autoreverses: true),
                value: isAnimating
            )
    }
}
