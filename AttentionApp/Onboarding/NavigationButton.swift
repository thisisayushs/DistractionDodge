//
//  NavigationButton.swift
//  AttentionApp
//
//  Created by Ayush Kumar Singh on 10/02/25.
//

import SwiftUI

struct NavigationButton: View {
    let buttonText: String
    let allLinesComplete: Bool
    let isLastScreen: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Text(buttonText)
                    .font(.system(size: 22, weight: .bold, design: .rounded))
            }
            .foregroundColor(.white)
            .padding(.vertical, 16)
            .padding(.horizontal, 35)
            .background(
                Capsule()
                    .fill(Color.white.opacity(0.2))
                    .overlay(Capsule().stroke(Color.white, lineWidth: 1.5))
                    .shadow(color: .white.opacity(0.3), radius: 5, x: 0, y: 2)
            )
            
            .scaleEffect(allLinesComplete ? 1.1 : 1.0)
            
            .animation(allLinesComplete ?
                .easeInOut(duration: 0.5).repeatForever(autoreverses: true) :
                    .easeInOut(duration: 0.3),
                       value: allLinesComplete
            )
        }
        .opacity(allLinesComplete ? 1 : 0.5)
        .disabled(!allLinesComplete)
        .padding(.bottom, 40)
    }
}
