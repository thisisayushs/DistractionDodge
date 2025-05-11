//
//  Hologram.swift
//  DistractionDodge
//
//  Created by Ayush Kumar Singh on 5/5/25.
//
#if os(visionOS)
import SwiftUI // For CGPoint, UUID, Date

/// Represents a hologram object in the game.
///
/// Holograms have a unique identifier, a position on the screen, and a creation timestamp
/// which can be used to manage their lifespan.
public struct Hologram: Identifiable, Equatable {
    /// A unique identifier for the hologram.
    public let id = UUID()
    /// The current position of the hologram in 2D space.
    public var position: CGPoint
    /// The time at which the hologram was created. Used to manage its lifespan.
    public let creationTime = Date()

    /// Initializes a new `Hologram`.
    /// - Parameter position: The initial position of the hologram.
    public init(position: CGPoint) {
        self.position = position
    }
}
#endif
