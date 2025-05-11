//
//  CollisionEffect.swift
//  DistractionDodge
//
//  Created by Ayush Kumar Singh on 5/5/25.
//
#if os(visionOS)
import SwiftUI // For CGPoint, UUID

/// Represents a visual effect triggered by a collision, typically when a hologram is caught.
///
/// Each effect has a unique identifier and a position where it should be displayed.
public struct CollisionEffect: Identifiable {
    /// A unique identifier for the collision effect.
    public let id = UUID()
    /// The position where the collision effect should be rendered.
    public var position: CGPoint

    /// Initializes a new `CollisionEffect`.
    /// - Parameter position: The position where the effect will occur.
    public init(position: CGPoint) {
        self.position = position
    }
}
#endif
