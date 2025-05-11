//
//  TutorialSparkEffect.swift
//  DistractionDodge
//
//  Created by Ayush Kumar Singh on 5/6/25.
//
#if os(visionOS)
import SwiftUI // For CGPoint, UUID

/// Represents a visual spark effect used in the tutorial, typically upon catching a tutorial hologram.
public struct TutorialSparkEffect: Identifiable {
    /// A unique identifier for the tutorial spark effect.
    public let id = UUID()
    /// The position where the tutorial spark effect should be rendered.
    public var position: CGPoint

    /// Initializes a new `TutorialSparkEffect`.
    /// - Parameter position: The position where the effect will occur.
    public init(position: CGPoint) {
        self.position = position
    }
}
#endif
