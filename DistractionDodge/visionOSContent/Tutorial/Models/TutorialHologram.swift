//
//  TutorialHologram.swift
//  DistractionDodge
//
//  Created by Ayush Kumar Singh on 5/6/25.
//
#if os(visionOS)
import SwiftUI // For CGPoint, CGFloat, UUID, Date, TimeInterval

/// Represents a hologram object specifically for use in the tutorial.
///
/// Tutorial holograms have a fixed lifespan and diameter.
public struct TutorialHologram: Identifiable, Equatable {
    /// A unique identifier for the tutorial hologram.
    public let id = UUID()
    /// The current position of the tutorial hologram in 2D space.
    public var position: CGPoint
    /// The time at which the tutorial hologram was created.
    public let creationTime = Date()
    /// The fixed lifespan for tutorial holograms in seconds.
    public static let lifespan: TimeInterval = 6.0
    /// The fixed diameter for tutorial holograms.
    public static let diameter: CGFloat = 90
    /// The fixed radius for tutorial holograms.
    public static var radius: CGFloat { diameter / 2 }

    /// Initializes a new `TutorialHologram`.
    /// - Parameter position: The initial position of the tutorial hologram.
    public init(position: CGPoint) {
        self.position = position
    }
}
#endif
