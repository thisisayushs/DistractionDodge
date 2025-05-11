//
//  VisionOSGameHostView.swift
//  DistractionDodge
//
//  Created by Ayush Kumar Singh on 5/5/25.
//
#if os(visionOS)
import SwiftUI
import SwiftData
/// A host view for the game content on visionOS.
///
/// This view is responsible for setting up and displaying the main game interface (`visionOSContentView`)
/// for the visionOS platform. It injects necessary dependencies like the `ModelContext` for SwiftData,
/// the game `duration`, and the `HealthKitManager`.
struct VisionOSGameHostView: View {
    /// The SwiftData model context, injected from the environment.
    /// Used for saving game session data.
    @Environment(\.modelContext) private var modelContext
    
    /// The duration for the game session, in seconds.
    let duration: Double
    
    /// An observed object instance of `HealthKitManager`.
    /// Used for saving mindful minutes to HealthKit.
    @ObservedObject var healthKitManager: HealthKitManager

    /// Initializes a new `VisionOSGameHostView`.
    /// - Parameters:
    ///   - duration: The duration for the game session in seconds.
    ///   - healthKitManager: The `HealthKitManager` instance for HealthKit interactions.
    init(duration: Double, healthKitManager: HealthKitManager) {
        self.duration = duration
        self.healthKitManager = healthKitManager
    }

    /// The body of the `VisionOSGameHostView`.
    var body: some View {
        visionOSContentView(duration: duration, modelContext: modelContext, healthKitManager: healthKitManager)
    }
}
#endif
