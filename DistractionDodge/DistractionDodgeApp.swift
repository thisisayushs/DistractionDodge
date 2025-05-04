//
//  DistractionDodgeApp.swift
//  DistractionDodge
//
//  Created by Ayush Kumar Singh on 28/12/24.
//

import SwiftUI
import SwiftData

/// The main entry point for the Attention App.
///
/// This app structure configures the initial UI and app-wide settings:
/// - Sets OnboardingView as the root view
/// - Enables dark appearance for the entire application
/// - Manages the primary window group
@main
struct DistractionDodge: App {
    let container: ModelContainer
    
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
                context.insert(UserProgress())
            }
        } catch {
            fatalError("Could not initialize ModelContainer: \(error.localizedDescription)")
        }
    }
    
    var body: some Scene {
        WindowGroup {
            OnboardingView()
                .preferredColorScheme(.dark)
        }
        .modelContainer(container)
    }
}
