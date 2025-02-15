//
//  NotificationAnimation.swift
//  AttentionApp
//
//  Created by Ayush Kumar Singh on 15/02/25.
//

import SwiftUI

struct NotificationAnimation: ViewModifier {
    let index: Int
    @State private var shake = false
    
    func body(content: Content) -> some View {
        content
            .offset(y: -20)
            .modifier(ShakeEffect(amount: shake ? 5 : 0, animatableData: shake ? 1 : 0))
            .animation(
                .spring(response: 0.5, dampingFraction: 0.65)
                .delay(Double(index) * 0.15),
                value: index
            )
            .onAppear {
                withAnimation(
                    .easeInOut(duration: 0.5)
                    .repeatCount(3, autoreverses: true)
                ) {
                    shake = true
                }
            }
    }
}
