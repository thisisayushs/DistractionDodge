//
//  VisionOSTutorialStep.swift
//  DistractionDodge
//
//  Created by Ayush Kumar Singh on 5/5/25.
//
#if os(visionOS)
import Foundation

/// Enumerates the different steps in the visionOS tutorial.
public enum VisionOSTutorialStep {
    /// The step where the user learns to drag the main circle.
    case dragCircle
    /// The step where the user learns to catch holograms.
    case catchHologram
    /// The step where the user learns about distractions.
    case learnDistractions
    /// The step where the user learns about the scoring system.
    case learnScoring
    /// The step where the user learns about the hearts/lives system.
    case learnHearts
}
#endif
