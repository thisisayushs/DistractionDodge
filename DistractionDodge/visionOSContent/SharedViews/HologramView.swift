//
//  HologramView.swift
//  DistractionDodge
//
//  Created by Ayush Kumar Singh on 5/5/25.
//
#if os(visionOS)
import SwiftUI

/// A visual representation of a hologram, typically used as a target or collectible in the game.
///
/// This view displays a circular shape with a cyan fill, stroke, and shadow, giving it a glowing, holographic appearance.
/// It includes a scale and opacity transition for animations.
public struct HologramView: View {
    /// Initializes a new `HologramView`.
    public init() {} // Add a public initializer if needed across modules, or keep internal if same module.
    
    /// The body of the `HologramView`.
    public var body: some View {
        Circle()
            .fill(Color.cyan.opacity(0.5))
            .frame(width: 90, height: 90)
            .overlay(
                Circle()
                    .stroke(Color.cyan.opacity(0.8), lineWidth: 2)
                    .blur(radius: 3)
            )
            .shadow(color: .cyan.opacity(0.7), radius: 10, x: 0, y: 0)
            .transition(.scale.combined(with: .opacity))
    }
}
#endif
