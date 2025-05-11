//
//  FlyingPoint.swift
//  DistractionDodge
//
//  Created by Ayush Kumar Singh on 5/6/25.
//
#if os(visionOS)
import SwiftUI // For CGPoint, UUID, Date, TimeInterval

/// Represents a flying text element, typically used to display points earned in the tutorial.
///
/// Flying points animate upwards and fade out over a fixed duration.
public struct FlyingPoint: Identifiable {
    /// A unique identifier for the flying point.
    public let id = UUID()
    /// The text content to display (e.g., "+3").
    public let text: String
    /// The initial position of the flying point.
    public var position: CGPoint
    /// The time at which the flying point was created.
    public let creationTime = Date()
    /// The fixed duration for the flying point's animation.
    public static let animationDuration: TimeInterval = 1.0

    /// Initializes a new `FlyingPoint`.
    /// - Parameters:
    ///   - text: The text to display.
    ///   - position: The starting position for the animation.
    public init(text: String, position: CGPoint) {
        self.text = text
        self.position = position
    }
}
#endif
