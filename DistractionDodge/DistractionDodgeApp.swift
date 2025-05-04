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
            container = try ModelContainer(
                for: GameSession.self, UserProgress.self,
                configurations: ModelConfiguration(isStoredInMemoryOnly: false)
            )
            
            // Initialize UserProgress if needed
            let context = container.mainContext
            let progressFetch = try context.fetch(FetchDescriptor<UserProgress>())
            if progressFetch.isEmpty {
                let progress = UserProgress(hasCompletedOnboarding: false)
                context.insert(progress)
                try context.save()
            }
        } catch {
            fatalError("Could not initialize ModelContainer: \(error.localizedDescription)")
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
