//
//  SparkleExplosionView.swift
//  DistractionDodge
//
//  Created by Ayush Kumar Singh on 5/5/25.
//
#if os(visionOS)
import SwiftUI

/// A view that displays a sparkling explosion effect.
///
/// This effect consists of expanding rings and a central sparkle image.
/// It animates its scale and opacity on appear and calls a completion handler when the animation finishes.
public struct SparkleExplosionView: View {
    /// The current scale of the explosion effect, animated on appear.
    @State private var scale: CGFloat = 0.2
    /// The current opacity of the explosion effect, animated on appear.
    @State private var opacity: Double = 1.0
    /// A closure to be called when the explosion animation completes.
    let onComplete: () -> Void

    /// The total duration of the sparkle explosion animation.
    private let animationDuration: TimeInterval = 0.6

    /// Initializes a new `SparkleExplosionView`.
    /// - Parameter onComplete: A closure that is called after the animation completes, used for cleanup.
    public init(onComplete: @escaping () -> Void) {
        self.onComplete = onComplete
    }

    /// The body of the `SparkleExplosionView`.
    public var body: some View {
        ZStack {
            // Expanding rings
            ForEach(0..<3) { i in
                Circle()
                    .stroke(Color.yellow.opacity(opacity * (1.0 - Double(i) * 0.2)), lineWidth: 2)
                    .scaleEffect(scale * (1.0 + CGFloat(i) * 0.3))
                    .animation(Animation.easeOut(duration: animationDuration).delay(Double(i) * 0.05), value: scale)
                    .animation(Animation.easeOut(duration: animationDuration).delay(Double(i) * 0.05), value: opacity)
            }
            // Central sparkle
            Image(systemName: "sparkle")
                .font(.system(size: 30))
                .foregroundColor(.yellow.opacity(opacity))
                .scaleEffect(scale * 1.5) // Make sparkle a bit bigger
                .animation(Animation.spring(response: animationDuration * 0.5, dampingFraction: 0.5).delay(0.1), value: scale)
                .animation(Animation.easeOut(duration: animationDuration * 0.8), value: opacity)

        }
        .onAppear {
            // Trigger animation
            self.scale = 1.3
            self.opacity = 0.0
            
            // Schedule removal after animation
            DispatchQueue.main.asyncAfter(deadline: .now() + animationDuration + 0.1) { // Add slight buffer
                onComplete()
            }
        }
    }
}
#endif
