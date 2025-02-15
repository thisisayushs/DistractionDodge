//
//  GlassBackground.swift
//  AttentionApp
//
//  Created by Ayush Kumar Singh on 15/02/25.
//

import SwiftUI

struct GlassBackground: View {
    var body: some View {
        ZStack {
            Color.white.opacity(0.15)
            
            
            Rectangle()
                .fill(Color.white)
                .opacity(0.05)
                .blur(radius: 10)
            
            
            LinearGradient(
                gradient: Gradient(colors: [Color.white.opacity(0.2), Color.white.opacity(0.1)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
}
