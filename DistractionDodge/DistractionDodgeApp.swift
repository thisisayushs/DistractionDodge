//
//  DistractionDodgeApp.swift
//  DistractionDodge
//
//  Created by Ayush Kumar Singh on 28/12/24.
//

import SwiftUI
import SwiftData
import HealthKit
import HealthKitUI

/// The main entry point for the Attention App.
///
/// This app structure configures the initial UI and app-wide settings:
/// - Sets OnboardingView as the root view
/// - Enables dark appearance for the entire application
/// - Manages the primary window group
@main
struct DistractionDodge: App {
    let container: ModelContainer
    let healthStore = HKHealthStore()
    
    init() {
        do {
            let isPreview = ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
            
            let modelConfiguration = ModelConfiguration(isStoredInMemoryOnly: isPreview)
            
            container = try ModelContainer(
                for: GameSession.self, UserProgress.self,
                configurations: modelConfiguration // Use the determined configuration
            )
            
            // Initialize UserProgress if needed
            // This will apply to the in-memory store for previews or persistent store for normal runs
            let context = container.mainContext
            let progressFetchDescriptor = FetchDescriptor<UserProgress>()
            if (try? context.fetch(progressFetchDescriptor))?.isEmpty ?? true {
                let progress = UserProgress(hasCompletedOnboarding: false, longestVisionOSStreak: 0.0)
                context.insert(progress)
                // For in-memory, changes are typically available immediately after insert.
                if !isPreview {
                    try context.save()
                }
            }
        } catch {
            let previewMessage = ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1" ? " (in Preview)" : ""
            fatalError("Could not initialize ModelContainer\(previewMessage): \(error.localizedDescription). Full Error: \(error)")
        }
    }
    
    var body: some Scene {
        WindowGroup {
            RootView()
                .preferredColorScheme(.dark)
                .environment(\.healthStore, healthStore)
        }
        .modelContainer(container)
    }
}

private struct HealthStoreKey: EnvironmentKey {
    static let defaultValue: HKHealthStore = HKHealthStore()
}

extension EnvironmentValues {
    var healthStore: HKHealthStore {
        get { self[HealthStoreKey.self] }
        set { self[HealthStoreKey.self] = newValue }
    }
}
