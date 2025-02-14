//
//  DistractionBackground.swift
//  AttentionApp
//
//  Created by Ayush Kumar Singh on 11/02/25.
//

import SwiftUI

struct DistractionBackground: View {
    @State private var isAnimating = false
    
    var body: some View {
        ZStack {
            ForEach(0..<20) { _ in
                Circle()
                    .fill(Color.white.opacity(0.1))
                    .frame(width: CGFloat.random(in: 10...30))
                    .position(
                        x: CGFloat.random(in: 0...UIScreen.main.bounds.width),
                        y: CGFloat.random(in: 0...UIScreen.main.bounds.height)
                    )
                    .modifier(HoverMotion(isAnimating: isAnimating))
            }
        }
        .onAppear {
            isAnimating = true
        }
    }
}
