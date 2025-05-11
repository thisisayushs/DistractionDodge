//
//  AboutView.swift
//  DistractionDodge
//
//  Created by Ayush Kumar Singh on 5/3/25.
//
import SwiftUI
import SwiftData

/// The root view of the DistractionDodge application.
///
/// `RootView` determines the initial screen presented to the user based on their onboarding status.
/// It queries `UserProgress` from SwiftData:
/// - If `UserProgress` exists and `hasCompletedOnboarding` is `true`, it navigates to `Home`.
/// - Otherwise (no `UserProgress` data or onboarding not completed), it presents `OnboardingView`.
///
/// This view acts as the primary navigator at app launch.
struct RootView: View {
    /// Fetches `UserProgress` data from SwiftData.
    /// This query retrieves all `UserProgress` objects, but typically there should only be one.
    @Query private var userProgress: [UserProgress]
    
    var body: some View {
        // Check if UserProgress data exists
        if let progress = userProgress.first {
            // If onboarding has been completed, show the Home screen
            if progress.hasCompletedOnboarding {
                Home()
            } else {
                // Otherwise, show the OnboardingView
                OnboardingView()
            }
        } else {
            // If no UserProgress data is found (e.g., first launch), show OnboardingView
            OnboardingView()
        }
    }
}
